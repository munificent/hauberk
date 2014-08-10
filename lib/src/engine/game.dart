library hauberk.engine.game;

import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import 'action/action.dart';
import 'actor.dart';
import 'area.dart';
import 'breed.dart';
import 'element.dart';
import 'fov.dart';
import 'hero/hero.dart';
import 'hero/hero_class.dart';
import 'items/item.dart';
import 'items/recipe.dart';
import 'log.dart';
import 'option.dart';
import 'stage.dart';

/// Root class for the game engine. All game state is contained within this.
class Game {
  final Area area;
  final int level;
  Stage get stage => _stage;
  Stage _stage;
  final log = new Log();
  final _actions = new Queue<Action>();
  Hero hero;
  Quest quest;

  Game(this.area, this.level, Content content, HeroSave save) {
    _stage = area.buildStage(this, level, save);
    _stage.finishBuild();
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
          trySpawnMonster();
        }
      }
    }
  }

  /// Over time, new monsters will appear in unexplored areas of the dungeon.
  /// This is to encourage players to not waste time: the more they linger, the
  /// more dangerous the remaining areas become.
  void trySpawnMonster() {
    if (!rng.oneIn(Option.SPAWN_MONSTER_CHANCE)) return;

    // Try to place a new monster in unexplored areas.
    Vec pos = rng.vecInRect(stage.bounds);

    final tile = stage[pos];
    if (tile.visible || tile.isExplored || !tile.isPassable) return;
    if (stage.actorAt(pos) != null) return;

    stage.spawnMonster(area.pickBreed(level), pos);
  }
}

/// Defines the actual content for the game: the breeds, items, etc. that
/// define the play experience.
abstract class Content {
  List<Area> get areas;
  Map<String, Breed> get breeds;
  Map<String, ItemType> get items;
  List<Recipe> get recipes;

  HeroSave createHero(String name, HeroClass heroClass);

  Map serializeAffix(Affix affix);
  Affix deserializeAffix(Map affix);
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

// TODO: Move to using pos for most events instead of value.
/// Describes a single "interesting" thing that occurred during a call to
/// [Game.update()]. In general, events correspond to things that a UI is likely
/// to want to display visually in some form.
class Event {
  final EventType type;
  final Actor actor;
  final Element element;
  final value;
  final Vec pos;

  Event(this.type, {this.actor, this.element: Element.NONE, this.value: 0,
      this.pos});
}

/// A kind of [Event] that has occurred.
class EventType {
  /// One step of a bolt.
  static const BOLT = const EventType("bolt");

  /// The leading edge of a cone.
  static const CONE = const EventType("cone");

  /// An [Actor] was hit.
  static const HIT = const EventType("hit");

  /// An [Actor] died.
  static const DIE = const EventType("die");

  /// An [Actor] was healed.
  static const HEAL = const EventType("heal");

  /// An [Actor] was frightened.
  static const FEAR = const EventType("fear");

  /// An [Actor] regained their courage.
  static const COURAGE = const EventType("courage");

  /// Something in the level was detected.
  static const DETECT = const EventType("detect");

  /// An [Actor] teleported..
  static const TELEPORT = const EventType("teleport");

  /// A new [Actor] was spawned by another.
  static const SPAWN = const EventType("spawn");

  /// A tile has been hit by sound.
  static const HOWL = const EventType("howl");

  final String _value;
  const EventType(this._value);
}
