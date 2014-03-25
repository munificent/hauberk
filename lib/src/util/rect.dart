library dngn.util.rect;

import 'dart:collection';
import 'dart:math' as math;

import 'vec.dart';

// TODO(bob): Finish porting from C#. Figure out how to handle overloads.
/// A two-dimensional rectangle.
class Rect extends IterableBase<Vec> {
  /// Gets the empty rectangle.
  static const EMPTY = const Rect.posAndSize(Vec.ZERO, Vec.ZERO);

  /// Creates a new rectangle a single row in height, as wide as [size],
  /// with its top left corner at [pos].
  static Rect row(Vec pos, int size) => new Rect(pos.x, pos.y, size, 1);

  /// Creates a new rectangle a single column in width, as tall as [size],
  /// with its top left corner at [pos].
  static Rect column(Vec pos, int size) => new Rect(pos.x, pos.y, 1, size);

  /// Creates a new rectangle that is the intersection of [a] and [b].
  ///
  ///     .----------.
  ///     | a        |
  ///     | .--------+----.
  ///     | | result |  b |
  ///     | |        |    |
  ///     '-+--------'    |
  ///       |             |
  ///       '-------------'
  static Rect intersect(Rect a, Rect b)
  {
    final left = math.max(a.left, b.left);
    final right = math.min(a.right, b.right);
    final top = math.max(a.top, b.top);
    final bottom = math.min(a.bottom, b.bottom);

    final width = math.max(0, right - left);
    final height = math.max(0, bottom - top);

    return new Rect(left, top, width, height);
  }

  static Rect centerIn(Rect toCenter, Rect main)
  {
    final pos = main.pos + ((main.size - toCenter.size) ~/ 2);
    return new Rect.posAndSize(pos, toCenter.size);
  }

  final Vec pos;
  final Vec size;

  int get x => pos.x;
  int get y => pos.y;
  int get width => size.x;
  int get height => size.y;

  int get left => x;
  int get top => y;
  int get right => x + width;
  int get bottom => y + height;

  Vec get topLeft => new Vec(left, top);
  Vec get topRight => new Vec(right, top);
  Vec get bottomLeft => new Vec(left, bottom);
  Vec get bottomRight => new Vec(right, bottom);

  Vec get center => new Vec((left + right) ~/ 2, (top + bottom) ~/ 2);

  int get area => size.area;

  const Rect.posAndSize(this.pos, this.size);

  Rect(int x, int y, int width, int height)
  : pos = new Vec(x, y),
    size = new Vec(width, height);

  String toString() => '($pos)-($size)';

  Rect inflate(int distance) {
    return new Rect(x - distance, y - distance,
      width + (distance * 2), height + (distance * 2));
  }

  bool contains(Vec point) {
    if (point.x < pos.x) return false;
    if (point.x >= pos.x + size.x) return false;
    if (point.y < pos.y) return false;
    if (point.y >= pos.y + size.y) return false;

    return true;
  }

  bool containsRect(Rect rect) {
    if (rect.left < left) return false;
    if (rect.right > right) return false;
    if (rect.top < top) return false;
    if (rect.bottom > bottom) return false;

    return true;
  }

  RectIterator get iterator => new RectIterator(this);

  /// Returns the distance between this Rect and [other]. This is minimum
  /// length that a corridor would have to be to go from one Rect to the other.
  /// If the two Rects are adjacent, returns zero. If they overlap, returns -1.
  int distanceTo(Rect other) {
    var vertical;
    if (top >= other.bottom) {
      vertical = top - other.bottom;
    } else if (bottom <= other.top) {
      vertical = other.top - bottom;
    } else {
      vertical = -1;
    }

    var horizontal;
    if (left >= other.right) {
      horizontal = left - other.right;
    } else if (right <= other.left) {
      horizontal = other.left - right;
    } else {
      horizontal = -1;
    }

    if ((vertical == -1) && (horizontal == -1)) return -1;
    if (vertical == -1) return horizontal;
    if (horizontal == -1) return vertical;
    return horizontal + vertical;
  }

  /// Iterates over the points along the edge of the Rect.
  Iterable<Vec> trace() {
    if ((width > 1) && (height > 1)) {
      // TODO(bob): Implement an iterator class here if building the list is
      // slow.
      // Trace all four sides.
      final result = <Vec>[];

      for (var x = left; x < right; x++) {
        result.add(new Vec(x, top));
        result.add(new Vec(x, bottom - 1));
      }

      for (var y = top + 1; y < bottom - 1; y++) {
        result.add(new Vec(left, y));
        result.add(new Vec(right - 1, y));
      }

      return result;
    } else if ((width > 1) && (height == 1)) {
      // A single row.
      return row(topLeft, width);
    } else if ((height >= 1) && (width == 1)) {
      // A single column, or one unit
      return column(topLeft, height);
    }

    // Otherwise, the rect doesn't have a positive size, so there's nothing to
    // trace.
    return const <Vec>[];
  }
}

class RectIterator implements Iterator<Vec> {
  final Rect _rect;
  int _x;
  int _y;

  RectIterator(this._rect) {
    _x = _rect.x - 1;
    _y = _rect.y;
  }

  Vec get current => new Vec(_x, _y);

  bool moveNext() {
    _x++;
    if (_x >= _rect.right) {
      _x = _rect.x;
      _y++;
    }

   return  _y < _rect.bottom;
  }
}
