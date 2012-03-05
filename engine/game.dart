/// Root class for the game engine. All game state is contained within this.
class Game {
  final Level        level;
  final Chain<Actor> actors;
  final List<Effect> effects;
  final Rng          rng;
  Hero hero;

  Game()
  : level = new Level(80, 40),
    actors = new Chain<Actor>(),
    effects = <Effect>[],
    rng = new Rng(new Date.now().value)
  {
    hero = new Hero(this, 3, 4);

    actors.add(hero);

    for (int i = 0; i < 30; i++) {
      actors.add(new Beetle(this, i + 10, 9));
      actors.add(new Beetle(this, i + 10, 10));
      actors.add(new Beetle(this, i + 10, 8));
      actors.add(new Beetle(this, i + 10, 11));
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
      if (actors.current.canTakeTurn && actors.current.needsInput) {
        return const GameResult(needInput: true, needPause: false);
      }

      if (actors.current.gainEnergy()) {
        // TODO(bob): Double check here is gross.
        if (actors.current.needsInput) {
          return const GameResult(needInput: true, needPause: false);
        }

        final action = actors.current.takeTurn();
        action.bindActor(actors.current);
        action.perform(this);
        actors.advance();
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
