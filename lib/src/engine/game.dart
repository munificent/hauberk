import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import 'action/action.dart';
import 'actor.dart';
import 'element.dart';
import 'hero/hero.dart';
import 'hero/hero_class.dart';
import 'items/item.dart';
import 'items/recipe.dart';
import 'items/shop.dart';
import 'log.dart';
import 'stage.dart';

/// Root class for the game engine. All game state is contained within this.
class Game {
  final int depth;
  Stage get stage => _stage;
  Stage _stage;
  final log = new Log();
  final _actions = new Queue<Action>();
  Hero hero;

  Game(Content content, HeroSave save, this.depth) {
    _buildStage(content, save, depth);
  }

  GameResult update() {
    final gameResult = new GameResult();

    while (true) {
      // Process any ongoing or pending actions.
      while (_actions.isNotEmpty) {
        var action = _actions.first;

        // Cascade through the alternates until we hit bottom out.
        var result = action.perform(_actions, gameResult);

        while (result.alternative != null) {
          _actions.removeFirst();
          action = result.alternative;
          _actions.addFirst(action);

          result = action.perform(_actions, gameResult);
        }

        stage.refreshVisibility(hero);

        gameResult.madeProgress = true;

        if (result.done) {
          _actions.removeFirst();

          if (result.succeeded && action.consumesEnergy) {
            action.actor.finishTurn(action);
            stage.advanceActor();
          }

          // Refresh every time the hero takes a turn.
          if (action.actor == hero) return gameResult;
        }

        if (gameResult.events.length > 0) return gameResult;
      }

      // If we get here, all pending actions are done, so advance to the next
      // tick until an actor moves.
      while (_actions.isEmpty) {
        var actor = stage.currentActor;

        // If we are still waiting for input for the actor, just return (again).
        if (actor.energy.canTakeTurn && actor.needsInput) return gameResult;

        if (actor.energy.canTakeTurn || actor.energy.gain(actor.speed)) {
          // If the actor can move now, but needs input from the user, just
          // return so we can wait for it.
          if (actor.needsInput) return gameResult;

          _actions.add(actor.getAction());
        } else {
          // This actor doesn't have enough energy yet, so move on to the next.
          stage.advanceActor();
        }

        // Each time we wrap around, process "idle" things that are ongoing and
        // speed independent.
        if (actor == hero) {
//          trySpawnMonster();
        }
      }
    }
  }

  // TODO: Decide if we want to keep this. Now that there is hunger forcing the
  // player to explore, it doesn't seem strictly necessary.
  /// Over time, new monsters will appear in unexplored areas of the dungeon.
  /// This is to encourage players to not waste time: the more they linger, the
  /// more dangerous the remaining areas become.
//  void trySpawnMonster() {
//    if (!rng.oneIn(Option.spawnMonsterChance)) return;
//
//    // Try to place a new monster in unexplored areas.
//    Vec pos = rng.vecInRect(stage.bounds);
//
//    final tile = stage[pos];
//    if (tile.visible || tile.isExplored || !tile.isPassable) return;
//    if (stage.actorAt(pos) != null) return;
//
//    stage.spawnMonster(area.pickBreed(level), pos);
//  }

  // TODO: Move to separate class.
  void _buildStage(Content content, HeroSave heroSave, int depth) {
    // TODO: Do something useful with depth.
    // TODO: Vary size?
    _stage = new Stage(121, 81, this);

    content.buildStage(_stage, depth);

    var heroPos = stage.findOpenTile();
    hero = new Hero(this, heroPos, heroSave);
    _stage.addActor(hero);

    // TODO: Temp. Wizard light it.
    /*
    for (var pos in stage.bounds) {
      for (var dir in Direction.all) {
        if (stage.bounds.contains(pos + dir) &&
            stage[pos + dir].isTransparent) {
          stage[pos].visible = true;
          break;
        }
      }
    }
    */

    _stage.finishBuild();
  }
}

/// Defines the actual content for the game: the breeds, items, etc. that
/// define the play experience.
abstract class Content {
  // TODO: Temp. Figure out where dungeon generator lives.
  void buildStage(Stage stage, int depth);

  ItemType findItem(String name);
  List<Recipe> get recipes;
  List<Shop> get shops;

  HeroSave createHero(String name, HeroClass heroClass);
}

/// Each call to [Game.update()] will return a [GameResult] object that tells
/// the UI what happened during that update and what it needs to do.
class GameResult {
  /// The "interesting" events that occurred in this update.
  final List<Event> events;

  /// Whether or not any game state has changed. If this is `false`, then no
  /// game processing has occurred (i.e. the game is stuck waiting for user
  /// input for the [Hero]).
  bool madeProgress = false;

  /// Returns `true` if the game state has progressed to the point that a change
  /// should be shown to the user.
  bool get needsRefresh => madeProgress || events.length > 0;

  GameResult()
  : events = <Event>[];
}

/// Describes a single "interesting" thing that occurred during a call to
/// [Game.update()]. In general, events correspond to things that a UI is likely
/// to want to display visually in some form.
class Event {
  final EventType type;
  final Actor actor;
  final Element element;
  final other;
  final Vec pos;
  final Direction dir;

  Event(this.type, this.actor, this.element, this.pos, this.dir, this.other);
}

/// A kind of [Event] that has occurred.
class EventType {
  /// One step of a bolt.
  static const bolt = const EventType("bolt");

  /// The leading edge of a cone.
  static const cone = const EventType("cone");

  /// A thrown item in flight.
  static const toss = const EventType("toss");

  /// An [Actor] was hit.
  static const hit = const EventType("hit");

  /// An [Actor] died.
  static const die = const EventType("die");

  /// An [Actor] was healed.
  static const heal = const EventType("heal");

  /// An [Actor] was frightened.
  static const fear = const EventType("fear");

  /// An [Actor] regained their courage.
  static const courage = const EventType("courage");

  /// Something in the level was detected.
  static const detect = const EventType("detect");

  /// An [Actor] teleported..
  static const teleport = const EventType("teleport");

  /// A new [Actor] was spawned by another.
  static const spawn = const EventType("spawn");

  /// A tile has been hit by sound.
  static const howl = const EventType("howl");

  /// A warrior's slash attack hits a tile.
  static const slash = const EventType("slash");

  /// A warrior's stab attack hits a tile.
  static const stab = const EventType("stab");

  /// The hero picks up gold worth [other].
  static const gold = const EventType("gold");

  final String _name;

  const EventType(this._name);

  String toString() => _name;
}
