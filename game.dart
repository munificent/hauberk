/// Root class for the game engine. All game state is contained within this.
class Game {
  final Level       level;
  final List<Actor> actors;
  Game()
  : level = new Level(50, 20),
    actors = <Actor>[] {
    actors.add(new Hero(3, 4));

    for (int i = 0; i < 30; i++) {
      actors.add(new Beetle(i + 10, 9));
      actors.add(new Beetle(i + 10, 10));
      actors.add(new Beetle(i + 10, 8));
      actors.add(new Beetle(i + 10, 11));
    }
  }

  void update() {
    for (final actor in actors) actor.update();
  }
}