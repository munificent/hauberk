part of util;

// TODO(bob): Finish porting from C#. Figure out how to handle overloads.
/// A two-dimensional rectangle.
class Rect implements Iterable<Vec> {
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


  // TODO(bob): Use a mixin when available.
  int get length => area;
  bool get isEmpty => IterableMixinWorkaround.isEmpty(this);
  Vec get first => IterableMixinWorkaround.first(this);
  Vec get last => IterableMixinWorkaround.last(this);
  Vec get single => IterableMixinWorkaround.single(this);
  Iterable<Vec> map(f(Vec element)) => IterableMixinWorkaround.map(this, f);
  // TODO(bob): Remove when removed from Iterable.
  Iterable<Vec> mappedBy(f(Vec element)) => IterableMixinWorkaround.map(this, f);
  Iterable<Vec> where(bool test(Vec element)) => IterableMixinWorkaround.where(this, test);
  Iterable expand(f(Vec element)) => IterableMixinWorkaround.expand(this, f);
  void forEach(void f(Vec o)) => IterableMixinWorkaround.forEach(this, f);
  bool any(bool f(Vec o)) => IterableMixinWorkaround.any(this, f);
  bool every(bool f(Vec o)) => IterableMixinWorkaround.every(this, f);
  reduce(seed, f(accumulator, Vec o)) => IterableMixinWorkaround.reduce(this, seed, f);
  String join([String separator]) => IterableMixinWorkaround.join(this, separator);
  List<Vec> toList() => new List.from(this);
  Set<Vec> toSet() => new Set.from(this);
  Vec min([int compare(Vec a, Vec b)]) => IterableMixinWorkaround.min(this, compare);
  Vec max([int compare(Vec a, Vec b)]) => IterableMixinWorkaround.max(this, compare);
  Iterable<Vec> take(int n) {
    throw new UnimplementedError();
  }
  Iterable<Vec> takeWhile(bool test(Vec value)) => IterableMixinWorkaround.takeWhile(this, test);
  Iterable<Vec> skip(int n) {
    throw new UnimplementedError();
  }
  Iterable<Vec> skipWhile(bool test(Vec value)) => IterableMixinWorkaround.skipWhile(this, test);
  Vec firstMatching(bool test(Vec value), {Vec orElse()}) => IterableMixinWorkaround.firstMatching(this, test, orElse);
  Vec lastMatching(bool test(Vec value), {Vec orElse()}) => IterableMixinWorkaround.lastMatching(this, test, orElse);
  Vec singleMatching(bool test(Vec value)) => IterableMixinWorkaround.singleMatching(this, test);
  Vec elementAt(int index) => IterableMixinWorkaround.elementAt(this, index);
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
