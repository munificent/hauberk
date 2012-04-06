/// Root class for the game engine. All game state is contained within this.
class Game {
  final List<Breed>    breeds;
  final List<ItemType> itemTypes;
  final Level          level;
  final Log            log;
  final Rng            rng;
  final Queue<Action>  actions;
  Hero                 hero;

  Game(this.breeds, this.itemTypes)
  : level = new Level(80, 40),
    log = new Log(),
    rng = new Rng(new Date.now().value),
    actions = new Queue<Action>()
  {
    level.game = this;

    //new FeatureCreep(level, new FeatureCreepOptions()).generate();
    new Dungeon(level).generate();

    final pos = level.findOpenTile();
    hero = new Hero(this, pos.x, pos.y);
    level.actors.add(hero);

    // TODO(bob): Temp for testing.
    for (var i = 0; i < 20; i++) {
      final item = new Item(rng.item(itemTypes), level.findOpenTile());
      level.items.add(item);
    }

    for (int i = 0; i < 30; i++) {
      final pos = level.findOpenTile();
      level.actors.add(rng.item(breeds).spawn(this, pos));
    }

    /*
    for (final pos in level.bounds) {
      level[pos]._explored = true;
    }
    */
    // End temp.

    Fov.refresh(level, hero.pos);
  }

  GameResult update() {
    final gameResult = new GameResult();

    while (true) {
      // Process any ongoing actions.
      while (actions.length > 0) {
        var action = actions.first();

        // Cascade through the alternates until we hit bottom out.
        var result = action.perform(gameResult);
        while (result.alternate != null) {
          final alternate = result.alternate;
          action = alternate;
          result = action.perform(gameResult);
        }

        level.refreshVisibility(hero);

        gameResult.madeProgress = true;

        if (result.done) {
          actions.removeFirst();

          if (action.consumesEnergy) {
            makeNoise(action.actor, action.noise);

            action.actor.finishTurn();
            level.actors.advance();

            // TODO(bob): Doing this here is a hack. Scent should spread at a
            // uniform rate independent of the hero's speed.
            if (action.actor == hero) level.updateScent(hero);
          }

          // TODO(bob): Uncomment this to animate the hero while resting or
          // running.
          //if (actor == hero) return gameResult;
        }

        if (gameResult.events.length > 0) return gameResult;
      }

      // If we get here, all pending actions are done, so advance to the next
      // tick until an actor moves.
      while (actions.length == 0) {
        final actor = level.actors.current;

        // If we are still waiting for input for the actor, just return (again).
        if (actor.energy.canTakeTurn && actor.needsInput) return gameResult;

        if (actor.energy.gain()) {
          // If the actor can move now, but needs input from the user, just
          // return so we can wait for it.
          if (actor.needsInput) return gameResult;

          var action = actor.getAction();
          actions.add(action);
        } else {
          // This actor doesn't have enough energy yet, so move on to the next.
          level.actors.advance();
        }
      }
    }
  }

  void makeNoise(Actor actor, int noise) {
    // Monsters ignore sounds from other monsters completely.
    if (actor is! Hero) return;

    // TODO(bob): Right now, sound doesn't take into account walls or doors. It
    // should so that the player can be sneaky by keeping doors closed. One
    // solution might be to do LOS between the source and actor and attentuate
    // when it crosses walls or doors.
    for (final monster in level.actors) {
      if (monster is! Monster) continue;

      var distanceSquared = (monster.pos - actor.pos).lengthSquared;

      // Avoid divide by zero.
      if (distanceSquared == 0) distanceSquared = 1;

      // Inverse-square law for acoustics.
      var volume = 1000 * noise / distanceSquared;
      monster.noise += volume;
    }
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
  bool get needsRefresh() => madeProgress || events.length > 0;

  GameResult()
  : events = <Event>[];
}

/// Describes a single "interesting" thing that occurred during a call to
/// [Game.update()]. In general, events correspond to things that a UI is likely
/// to want to display visually in some form.
class Event {
  final EventType type;
  final Actor actor;
  final value;

  Event(this.type, this.actor, this.value);

  Event.bolt(Vec this.value)
  : type = EventType.BOLT,
    actor = null;

  Event.hit(this.actor, this.value)
  : type = EventType.HIT;

  Event.kill(this.actor)
  : type = EventType.KILL,
    value = 0;
}

/// A kind of [Event] that has occurred.
class EventType {
  /// One step of a bolt.
  static final BOLT = const EventType(0);

  /// An [Actor] was hit.
  static final HIT = const EventType(1);

  /// An [Actor] was killed.
  static final KILL = const EventType(2);

  final int _value;
  const EventType(this._value);
}
