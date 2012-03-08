/// Root class for the game engine. All game state is contained within this.
class Game {
  final Level        level;
  final List<Effect> effects;
  final Log          log;
  final Rng          rng;
  Hero hero;

  bool _visibilityDirty = true;

  Game()
  : level = new Level(80, 40),
    effects = <Effect>[],
    log = new Log(),
    rng = new Rng(new Date.now().value)
  {
    hero = new Hero(this, 3, 4);
    level.actors.add(hero);
  }

  GameResult update() {
    /*
    effects.clear();

    if (action != null) {
      action.update();
      return;
    }
    */

    // Before we get into the loop, check to see if we're just sitting waiting
    // for user input.
    if (level.actors.current.energy.canTakeTurn &&
        level.actors.current.needsInput) {
      return GameResult.WAITING;
    }

    while (true) {
      final actor = level.actors.current;

      if (actor.energy.canTakeTurn && actor.needsInput) {
        return GameResult.UPDATED;
      }

      if (actor.energy.gain()) {
        // TODO(bob): Double check here is gross.
        if (actor.needsInput) return GameResult.UPDATED;

        var action = actor.getAction();
        var result = action.perform(this, actor);

        // Cascade through the alternates until we hit bottom out.
        while (result.alternate != null) {
          result = result.alternate.perform(this, actor);
        }

        if (_visibilityDirty) {
          Fov.refresh(level, hero.pos);
          _visibilityDirty = false;
        }

        if (result.succeeded) {
          actor.energy.spend();
          level.actors.advance();
        }
      }
    }
  }

  void dirtyVisibility() {
    _visibilityDirty = true;
  }
}

class GameResult {
  // Did absolutely nothing. No actions were processed since the very next
  // thing we need to do is move the hero.
  static final WAITING = const GameResult(0);

  // Some actions were processed, so we need to render.
  static final UPDATED = const GameResult(1);

  final int _value;

  const GameResult(this._value);
}

class Effect {
  final Vec pos;
}
