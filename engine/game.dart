/// Root class for the game engine. All game state is contained within this.
class Game {
  final List<Breed>    breeds;
  final List<ItemType> itemTypes;
  final Level          level;
  final Log            log;
  final Rng            rng;
  Hero                 hero;

  bool _visibilityDirty = true;

  Game(this.breeds, this.itemTypes)
  : level = new Level(80, 40),
    log = new Log(),
    rng = new Rng(new Date.now().value)
  {
    level.game = this;

    //new FeatureCreep(level, new FeatureCreepOptions()).generate();
    new Dungeon(level).generate();

    final pos = level.findOpenTile();
    hero = new Hero(this, pos.x, pos.y);
    level.actors.add(hero);

    // TODO(bob): Temp for testing.
    for (var i = 0; i < 10; i++) {
      final item = new Item(rng.item(itemTypes), level.findOpenTile());
      level.items.add(item);
    }

    for (int i = 0; i < 30; i++) {
      final pos = level.findOpenTile();
      level.actors.add(rng.item(breeds).spawn(this, pos));
    }
    // End temp.

    Fov.refresh(level, hero.pos);
  }

  GameResult update() {
    final gameResult = new GameResult();

    while (true) {
      final actor = level.actors.current;

      if (actor.energy.canTakeTurn && actor.needsInput) {
        return gameResult;
      }

      if (actor.energy.gain()) {
        if (actor.needsInput) {
          return gameResult;
        }

        var action = actor.getAction();
        var result = action.perform(this, gameResult, actor);

        gameResult.madeProgress = true;

        // Cascade through the alternates until we hit bottom out.
        while (result.alternate != null) {
          result = result.alternate.perform(this, gameResult, actor);
        }

        if (_visibilityDirty) {
          Fov.refresh(level, hero.pos);
          _visibilityDirty = false;
        }

        if (result.succeeded) {
          actor.finishTurn();
          level.actors.advance();

          // TODO(bob): Doing this here is a hack. Scent should spread at a
          // uniform rate independent of the hero's speed.
          if (actor == hero) level.updateScent(hero);
        }
      } else {
        // This actor doesn't have enough energy yet, so move on to the next.
        level.actors.advance();
      }
    }
  }

  void dirtyVisibility() {
    _visibilityDirty = true;
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

  GameResult()
  : events = <Event>[];
}

/// Describes a single "interesting" thing that occurred during a call to
/// [Game.update()]. In general, events correspond to things that a UI is likely
/// to want to display visually in some form.
class Event {
  final EventType type;
  final Actor actor;
  final num value;

  Event(this.type, this.actor, this.value);
  Event.hit(this.actor, this.value)
  : type = EventType.HIT;

  Event.kill(this.actor)
  : type = EventType.KILL,
    value = 0;
}

/// A kind of [Event] that has occurred.
class EventType {
  /// An [Actor] was hit.
  static final HIT = const EventType(0);

  /// An [Actor] was killed.
  static final KILL = const EventType(1);

  final int _value;
  const EventType(this._value);
}
