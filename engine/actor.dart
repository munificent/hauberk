/// An active entity in the game. Includes monsters and the hero.
class Actor implements Noun {
  final Game game;
  int energy;
  Vec _pos;

  Vec get pos() => _pos;
  void set pos(Vec value) {
    if (value != _pos) {
      _pos = changePosition(value);
    }
  }

  int get x() => pos.x;
  void set x(int value) => pos = new Vec(value, y);

  int get y() => pos.y;
  void set y(int value) => pos = new Vec(x, value);

  Actor(this.game, int x, int y)
  : _pos = new Vec(x, y),
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

  /// Called when the actor's position is about to change to [pos]. Override
  /// to do stuff when the position changes. Returns the new position.
  Vec changePosition(Vec pos) => pos;

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
