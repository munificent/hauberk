/// Root class for the game engine. All game state is contained within this.
class Game {
  final Level        level;
  final List<Effect> effects;
  final Log          log;
  final Rng          rng;
  Hero hero;

  Game()
  : level = new Level(80, 40),
    effects = <Effect>[],
    log = new Log(),
    rng = new Rng(new Date.now().value)
  {
    log.add('Welcome!');
    hero = new Hero(this, 3, 4);

    level.actors.add(hero);

    for (int i = 0; i < 30; i++) {
      level.actors.add(new Beetle(this, i + 10, 9));
      level.actors.add(new Beetle(this, i + 10, 10));
      level.actors.add(new Beetle(this, i + 10, 8));
      level.actors.add(new Beetle(this, i + 10, 11));
    }
  }

  GameResult update() {
    /*
    effects.clear();

    if (action != null) {
      action.update();
      return;
    }
    */

    while (true) {
      final actor = level.actors.current;

      if (actor.energy.canTakeTurn && actor.needsInput) {
        return const GameResult(needInput: true, needPause: false);
      }

      if (actor.energy.gain()) {
        // TODO(bob): Double check here is gross.
        if (actor.needsInput) {
          return const GameResult(needInput: true, needPause: false);
        }

        var action = actor.getAction();
        var result = action.perform(this, actor);

        // Cascade through the alternates until we hit bottom out.
        while (result.alternate != null) {
          result = result.alternate.perform(this, actor);
        }

        if (result.succeeded) {
          actor.energy.spend();
          level.actors.advance();
        }
      }
    }
  }
}

class GameResult {
  final bool needInput;
  final bool needPause;

  const GameResult([this.needInput, this.needPause]);
}

class Effect {
  final Vec pos;
}
