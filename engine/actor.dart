/// An active entity in the game. Includes monsters and the hero.
class Actor implements Noun {
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

  get appearance() {
    assert(false); // Abstract.
  }

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

  String get nounText() {
    assert(false); // Abstract.
  }

  int get person() {
    assert(false); // Abstract.
  }

  Gender get gender() {
    assert(false); // Abstract.
  }
}

class Monster extends Actor {
  final Breed breed;

  Monster(Game game, this.breed, int x, int y) : super(game, x, y);

  get appearance() => breed.appearance;

  String get nounText() => 'the ${breed.name}';
  int get person() => 3;
  Gender get gender() => breed.gender;

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

/// A single kind of [Monster] in the game.
class Breed {
  final Gender gender;
  final String name;

  /// Untyped so the engine isn't coupled to how monsters appear.
  final appearance;

  Breed(this.name, this.gender, this.appearance);
}
