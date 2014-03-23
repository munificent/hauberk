part of engine;

/// Root class for the game engine. All game state is contained within this.
class Game {
  final Area           area;
  final int            level;
  final Stage          stage;
  final Log            log;
  final Queue<Action>  actions;
  Hero hero;
  Quest quest;

  Game(this.area, this.level, Content content, HeroSave save)
    : stage = new Stage(80, 40),
      log = new Log(),
      actions = new Queue<Action>() {
    stage.game = this;

    final heroPos = area.buildStage(this, level);

    hero = new Hero(this, heroPos, save, save.skills);
    stage.actors.add(hero);

    Fov.refresh(stage, hero.pos);
  }

  GameResult update() {
    final gameResult = new GameResult();

    while (true) {
      // Process any ongoing actions.
      while (actions.length > 0) {
        var action = actions.first;

        // Cascade through the alternates until we hit bottom out.
        var result = action.perform(gameResult);
        while (result.alternative != null) {
          action = result.alternative;
          result = action.perform(gameResult);
        }

        stage.refreshVisibility(hero);

        gameResult.madeProgress = true;

        if (result.done) {
          actions.removeFirst();

          if (action.consumesEnergy) {
            makeNoise(action.actor, action.noise);

            action.actor.finishTurn(action);
            stage.actors.advance();

            // TODO(bob): Doing this here is a hack. Scent should spread at a
            // uniform rate independent of the hero's speed.
            if (action.actor == hero) stage.updateScent(hero);
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
        final actor = stage.actors.current;

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

    // TODO(bob): Should reuse code in Area to generate out-of-depth monsters.
    final breed = area.pickBreed(level);
    stage.spawnMonster(breed, pos);
  }

  void makeNoise(Actor actor, int noise) {
    // Monsters mostly ignore sounds from other monsters.
    if (actor is! Hero) noise ~/= 4;

    // TODO: Right now, sound doesn't take into account walls or doors. It
    // should so that the player can be sneaky by keeping doors closed. One
    // solution might be to do LOS between the source and actor and attentuate
    // when it crosses walls or doors.
    for (final monster in stage.actors) {
      if (monster is! Monster) continue;

      var distanceSquared = (monster.pos - actor.pos).lengthSquared;

      // Avoid divide by zero.
      if (distanceSquared == 0) distanceSquared = 1;

      // Would be better to handle sound travelling around corners, but this
      // is a loose approximation of sound being attenuated by obstacles.
      if (monster.canView(actor.pos)) noise *= 10;

      // Inverse-square law for acoustics.
      var volume = 100 * noise / distanceSquared;
      monster.noise += volume;
    }
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

  Event(this.type, this.actor, this.element, this.value);

  Event.bolt(Vec this.value, this.element)
    : type = EventType.BOLT,
      actor = null;

  Event.hit(this.actor, this.value)
    : type = EventType.HIT,
      element = Element.NONE;

  Event.kill(this.actor)
    : type = EventType.KILL,
      element = Element.NONE,
      value = 0;

  Event.heal(this.actor, this.value)
    : type = EventType.HEAL,
      element = Element.NONE;
}

/// A kind of [Event] that has occurred.
class EventType {
  /// One step of a bolt.
  static const BOLT = const EventType(0);

  /// An [Actor] was hit.
  static const HIT = const EventType(1);

  /// An [Actor] was killed.
  static const KILL = const EventType(2);

  /// An [Actor] was healed.
  static const HEAL = const EventType(3);

  final int _value;
  const EventType(this._value);
}
