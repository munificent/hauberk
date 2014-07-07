library hauberk.util.vec;

import 'dart:math' as math;

/// Shared base class of [Vec] and [Direction]. We do this instead of having
/// [Direction] inherit directly from [Vec] so that we can avoid it inheriting
/// an `==` operator, which would prevent it from being used in `switch`
/// statements. Instead, [Direction] uses identity equality.
class VecBase {
  final int x;
  final int y;

  const VecBase(this.x, this.y);

  int get area => x * y;

  /// Gets the rook length of the Vec, which is the number of squares a rook on
  /// a chessboard would need to move from (0, 0) to reach the endpoint of the
  /// Vec. Also known as Manhattan or taxicab distance.
  int get rookLength => x.abs() + y.abs();

  /// Gets the king length of the Vec, which is the number of squares a king on
  /// a chessboard would need to move from (0, 0) to reach the endpoint of the
  /// Vec. Also known as Chebyshev distance.
  int get kingLength => math.max(x.abs(), y.abs());

  int get lengthSquared => x * x + y * y;

  Vec operator *(int other) => new Vec(x * other, y * other);

  Vec operator ~/(int other) => new Vec(x ~/ other, y ~/ other);

  Vec operator +(other) {
    if (other is VecBase) {
      return new Vec(x + other.x, y + other.y);
    } else if (other is int) {
      return new Vec(x + other, y + other);
    }

    throw new ArgumentError("Operand must be an int or VecBase.");
  }

  Vec operator -(other) {
    if (other is VecBase) {
      return new Vec(x - other.x, y - other.y);
    } else if (other is int) {
      return new Vec(x - other, y - other);
    }

    throw new ArgumentError("Operand must be an int or VecBase.");
  }

  /// Returns `true` if the magnitude of this vector is greater than [other].
  bool operator >(other) {
    if (other is VecBase) {
      return lengthSquared > other.lengthSquared;
    } else if (other is int) {
      return lengthSquared > other * other;
    }

    throw new ArgumentError("Operand must be an int or VecBase.");
  }

  /// Returns `true` if the magnitude of this vector is greater than or equal
  /// to [other].
  bool operator >=(other) {
    if (other is VecBase) {
      return lengthSquared >= other.lengthSquared;
    } else if (other is int) {
      return lengthSquared >= other * other;
    }

    throw new ArgumentError("Operand must be an int or VecBase.");
  }

  /// Returns `true` if the magnitude of this vector is less than [other].
  bool operator <(other) {
    if (other is VecBase) {
      return lengthSquared < other.lengthSquared;
    } else if (other is int) {
      return lengthSquared < other * other;
    }

    throw new ArgumentError("Operand must be an int or VecBase.");
  }

  /// Returns `true` if the magnitude of this vector is less than or equal to
  /// [other].
  bool operator <=(other) {
    if (other is VecBase) {
      return lengthSquared <= other.lengthSquared;
    } else if (other is int) {
      return lengthSquared <= other * other;
    }

    throw new ArgumentError("Operand must be an int or VecBase.");
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

/// A two-dimensional point.
class Vec extends VecBase {
  static const ZERO = const Vec(0, 0);

  const Vec(int x, int y) : super(x, y);

  bool operator ==(Vec other) => x == other.x && y == other.y;
}
