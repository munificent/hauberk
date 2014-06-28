library dngn.engine.game;

import 'dart:collection';

import '../util.dart';
import 'action_base.dart';
import 'actor.dart';
import 'area.dart';
import 'breed.dart';
import 'element.dart';
import 'fov.dart';
import 'hero.dart';
import 'item.dart';
import 'log.dart';
import 'option.dart';
import 'skill.dart';
import 'stage.dart';

/// Root class for the game engine. All game state is contained within this.
class Game {
  final Area area;
  final int level;
  final stage = new Stage(80, 40);
  final log = new Log();
  final _actions = new Queue<Action>();
  Hero hero;
  Quest quest;

  Game(this.area, this.level, Content content, HeroSave save) {
    stage.game = this;
    area.buildStage(this, level, save);
    Fov.refresh(stage, hero.pos);
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
          action = result.alternative;
          result = action.perform(_actions, gameResult);
        }

        stage.refreshVisibility(hero);

        gameResult.madeProgress = true;

        if (result.done) {
          _actions.removeFirst();

          if (result.succeeded && action.consumesEnergy) {
            action.actor.finishTurn(action);
            stage.actors.advance();
          }

          // Refresh every time the hero takes a turn.
          if (action.actor == hero) return gameResult;
        }

        if (gameResult.events.length > 0) return gameResult;
      }

      // If we get here, all pending actions are done, so advance to the next
      // tick until an actor moves.
      while (_actions.isEmpty) {
        final actor = stage.actors.current;

        // If we are still waiting for input for the actor, just return (again).
        if (actor.energy.canTakeTurn && actor.needsInput) return gameResult;

        if (actor.energy.gain(actor.speed)) {
          // If the actor can move now, but needs input from the user, just
          // return so we can wait for it.
          if (actor.needsInput) return gameResult;

          _actions.add(actor.getAction());
        } else {
          // This actor doesn't have enough energy yet, so move on to the next.
          stage.actors.advance();
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
class Content {
  final List<Area> areas;
  final Map<String, Breed> breeds;
  final Map<String, ItemType> items;
  final List<Recipe> recipes;
  final List<ItemType> _newHeroItems;
  final Map<String, Skill> skills;

  Content(this.areas, this.breeds, this.items, this.recipes, this.skills,
      this._newHeroItems);

  HeroSave createHero(String name) {
    final hero = new HeroSave(skills, name);
    for (final itemType in _newHeroItems) {
      hero.inventory.tryAdd(new Item(itemType));
    }

    return hero;
  }
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
  final value;

  Event(this.type, this.actor, [this.element = Element.NONE, this.value = 0]);

  Event.bolt(Vec this.value, this.element)
    : type = EventType.BOLT,
      actor = null;

  Event.hit(this.actor, this.value)
    : type = EventType.HIT,
      element = Element.NONE;

  Event.die(this.actor)
    : type = EventType.DIE,
      element = Element.NONE,
      value = 0;

  Event.heal(this.actor, this.value)
    : type = EventType.HEAL,
      element = Element.NONE;
}

/// A kind of [Event] that has occurred.
class EventType {
  /// One step of a bolt.
  static const BOLT = const EventType("bolt");

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

  final String _value;
  const EventType(this._value);
}
