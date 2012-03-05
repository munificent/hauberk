
/// A two-dimensional point.
class Vec {
  final int x;
  final int y;

  const Vec(this.x, this.y);

  Vec operator +(Vec other) => new Vec(x + other.x, y + other.y);
  Vec operator -(Vec other) => new Vec(x - other.x, y - other.y);
}

class Direction {
  static final NONE = const Direction(-1);
  static final N  = const Direction(0);
  static final NE = const Direction(1);
  static final E  = const Direction(2);
  static final SE = const Direction(3);
  static final S  = const Direction(4);
  static final SW = const Direction(5);
  static final W  = const Direction(6);
  static final NW = const Direction(7);

  final int _value;

  const Direction(this._value);
}