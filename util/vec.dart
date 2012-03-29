/// A two-dimensional point.
class Vec {
  static final ZERO = const Vec(0, 0);

  final int x;
  final int y;

  const Vec(this.x, this.y);

  int get area() => x * y;

  /// Gets the rook length of the Vec, which is the number of squares a rook on
  /// a chessboard would need to move from (0, 0) to reach the endpoint of the
  /// Vec. Also known as Manhattan or taxicab distance.
  int get rookLength() => x.abs() + y.abs();

  /// Gets the king length of the Vec, which is the number of squares a king on
  /// a chessboard would need to move from (0, 0) to reach the endpoint of the
  /// Vec. Also known as Chebyshev distance.
  int get kingLength() => Math.max(x.abs(), y.abs());

  bool operator ==(Vec other) {
    // TODO(bob): Get rid of this when new equality semantics are implemented.
    if (other === null) return false;
    return x == other.x && y == other.y;
  }

  Vec operator *(int other) => new Vec(x * other, y * other);

  Vec operator ~/(int other) => new Vec(x ~/ other, y ~/ other);

  Vec operator +(other) {
    if (other is Vec) {
      return new Vec(x + other.x, y + other.y);
    } else if (other is int) {
      return new Vec(x + other, y + other);
    } else assert(false);
  }

  Vec operator -(other) {
    if (other is Vec) {
      return new Vec(x - other.x, y - other.y);
    } else if (other is int) {
      return new Vec(x - other, y - other);
    } else assert(false);
  }

  /// Gets whether the given vector is within a rectangle from (0,0) to this
  /// vector (half-inclusive).
  bool contains(Vec pos) {
    if (pos.x < 0) return false;
    if (pos.x >= x) return false;
    if (pos.y < 0) return false;
    if (pos.y >= y) return false;

    return true;
  }

  Vec abs() => new Vec(x.abs(), y.abs());
  
  Vec offsetX(int x) => new Vec(this.x + x, y);
  Vec offsetY(int y) => new Vec(x, this.y + y);

  String toString() => '$x, $y';
}
