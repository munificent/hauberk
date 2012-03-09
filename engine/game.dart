/// Root class for the game engine. All game state is contained within this.
class Game {
  final Level        level;
  List<Effect>       effects;
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

  bool update() {
    var needsRender = effects.length > 0;

    // Note that the effects run in realtime independent of the turn-based
    // energy system. This is good in that it lets the player keep going while
    // effects are playing out. But it also means that gameplay must *not* take
    // effects into account in order to remain completely turn-based.
    effects = effects.filter((effect) {
      return effect.update() &&
             level.bounds.contains(effect.pos) &&
             level[effect.pos].isPassable;
    });

    while (true) {
      final actor = level.actors.current;

      if (actor.energy.canTakeTurn && actor.needsInput) {
        return needsRender;
      }

      if (actor.energy.gain()) {
        if (actor.needsInput) return needsRender;

        var action = actor.getAction();
        var result = action.perform(this, actor);

        needsRender = true;

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


          // TODO(bob): Doing this here is a hack. Scent should spread at a
          // uniform rate independent of the hero's speed.
          if (actor == hero) level.updateScent(hero);
        }
      }
    }
  }

  void dirtyVisibility() {
    _visibilityDirty = true;
  }
}

class Effect {
  Vec get pos() => new Vec(x.toInt(), y.toInt());
  float x;
  float y;
  float h;
  float v;
  int life;

  Effect(this.x, this.y, this.h, this.v, this.life);

  bool update() {
    x += h;
    y += v;
    life--;
    return life >= 0;
  }
}
