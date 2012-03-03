/// Root class for the game engine. All game state is contained within this.
class Game {
  final Level        level;
  final Chain<Actor> actors;
  final List<Effect> effects;

  final Hero hero;

  Game()
  : level = new Level(90, 30),
    actors = new Chain<Actor>(),
    effects = <Effect>[],
    hero = new Hero(3, 4)
  {
    actors.add(hero);

    for (int i = 0; i < 30; i++) {
      actors.add(new Beetle(i + 10, 9));
      actors.add(new Beetle(i + 10, 10));
      actors.add(new Beetle(i + 10, 8));
      actors.add(new Beetle(i + 10, 11));
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
        action.perform(this, actors.current);
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
