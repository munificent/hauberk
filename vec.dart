
/// A two-dimensional point.
class Vec {
  final int x;
  final int y;

  const Vec(this.x, this.y);

  Vec operator +(Vec other) => new Vec(x + other.x, y + other.y);
  Vec operator -(Vec other) => new Vec(x - other.x, y - other.y);
}

class Effect {
  final Vec pos;
}
