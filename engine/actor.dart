/// An active entity in the game. Includes monsters and the hero.
class Actor {
  final Game game;
  Vec pos;
  int energy;

  int get x() => pos.x;
  void set x(int value) => pos = new Vec(value, y);

  int get y() => pos.y;
  void set y(int value) => pos = new Vec(x, value);

  Actor(this.game, int x, int y)
  : pos = new Vec(x, y),
    energy = new Energy(Energy.NORMAL_SPEED);

  bool get needsInput() => false;

  Action getAction() {
    // Do nothing.
  }

  bool canOccupy(Vec pos) {
    if (pos.x < 0) return false;
    if (pos.x >= game.level.width) return false;
    if (pos.y < 0) return false;
    if (pos.y >= game.level.height) return false;

    return game.level[pos].type == TileType.FLOOR;
  }
}

class Beetle extends Actor {
  Beetle(Game game, int x, int y) : super(game, x, y);

  void getAction() {
    switch (rng.next(4)) {
      case 0: return new MoveAction(new Vec(0, -1));
      case 1: return new MoveAction(new Vec(0, 1));
      case 2: return new MoveAction(new Vec(-1, 0));
      case 3: return new MoveAction(new Vec(1, 0));
    }

    return new MoveAction(new Vec(0, 0));
  }
}
