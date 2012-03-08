// TODO(bob): Finish porting from C#. Figure out how to handle overloads.
/// A two-dimensional rectangle.
class Rect implements Iterable<Vec> {
  /// Gets the empty rectangle.
  static final EMPTY = const Rect(0, 0, 0, 0);

  /*
  /// Creates a new rectangle a single row in height, as wide as [size].
  static Rect row(int size) => new Rect(0, 0, size, 1);

  /// Creates a new rectangle a single row in height, as wide as the [size],
  /// with its top left corner at [x], [y].
  static Rect row(int x, int y, int size) => new Rect(x, y, size, 1);

  /// Creates a new rectangle a single row in height, as wide as [size],
  /// with its top left corner at [pos].
  static Rect row(Vec pos, int size) => new Rect(pos.x, pos.y, size, 1);

  /// Creates a new rectangle a single column in width, as tall as [size].
  static Rect column(int size) => new Rect(0, 0, 1, size);

  /// Creates a new rectangle a single column in width, as tall as [size],
  /// with its top left corner at [x], [y].
  static Rect column(int x, int y, int size) => new Rect(x, y, 1, size);

  /// Creates a new rectangle a single column in width, as tall as [size],
  /// with its top left corner at [pos].
  static Rect column(Vec pos, int size) => new Rect(pos.x, pos.y, 1, size);
  */

  /// <summary>
  /// Creates a new rectangle that is the intersection of the two given rectangles.
  /// </summary>
  /// <example><code>
  /// .----------.
  /// | a        |
  /// | .--------+----.
  /// | | result |  b |
  /// | |        |    |
  /// '-+--------'    |
  ///   |             |
  ///   '-------------'
  /// </code></example>
  /// <param name="a">The first rectangle.</param>
  /// <param name="b">The rectangle to intersect it with.</param>
  /// <returns></returns>
  static Rect intersect(Rect a, Rect b)
  {
    final left = Math.max(a.left, b.left);
    final right = Math.min(a.right, b.right);
    final top = Math.max(a.top, b.top);
    final bottom = Math.min(a.bottom, b.bottom);

    final width = Math.max(0, right - left);
    final height = Math.max(0, bottom - top);

    return new Rect(left, top, width, height);
  }

  static Rect centerIn(Rect toCenter, Rect main)
  {
    final pos = main.pos + ((main.size - toCenter.size) ~/ 2);
    return new Rect(pos, toCenter.size);
  }

  /*

  static bool operator ==(Rect r1, Rect r2)
  {
      return r1.Equals(r2);
  }

  static Rect operator +(Rect r1, Vec v2)
  {
      return new Rect(r1.pos + v2, r1.size);
  }

  static Rect operator +(Vec v1, Rect r2)
  {
      return new Rect(r2.pos + v1, r2.size);
  }

  static Rect operator -(Rect r1, Vec v2)
  {
      return new Rect(r1.pos - v2, r1.size);
  }

  */

  final Vec pos;
  final Vec size;

  int get x() => pos.x;
  int get y() => pos.y;
  int get width() => size.x;
  int get height() => size.y;

  int get left() => x;
  int get top() => y;
  int get right() => x + width;
  int get bottom() => y + height;

  Vec get topLeft() => new Vec(left, top);
  Vec get topRight() => new Vec(right, top);
  Vec get bottomLeft() => new Vec(left, bottom);
  Vec get bottomRight() => new Vec(right, bottom);

  Vec get center() => new Vec((left + right) / 2, (top + bottom) / 2);

  int get area() => size.area;

  /*
  const Rect(this.pos, this.size);

  const Rect(this.size)
  : pos = Vec.zero;
  */

  Rect(int x, int y, int width, int height)
  : pos = new Vec(x, y),
    size = new Vec(width, height);

  /*
  const Rect(this.pos, int width, int height)
  : size = const Vec(width, height);

  const Rect(int width, int height)
  : pos = Vec.zero,
    size = const Vec(width, height);

  const Rect(int x, int y, this.size)
  : pos = const Vec(x, y);
  */

  String toString() => '($pos)-($size)';

  /*
  override bool Equals(object obj)
  {
      if (obj is Rect) return Equals((Rect)obj);

      return base.Equals(obj);
  }

  Rect Offset(Vec pos, Vec size)
  {
      return new Rect(mPos + pos, mSize + size);
  }

  Rect Offset(int x, int y, int width, int height)
  {
      return Offset(new Vec(x, y), new Vec(width, height));
  }
  */

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

  RectIterator iterator() => new RectIterator(this);

  /*
  bool Overlaps(Rect rect)
  {
      // fail if they do not overlap on any axis
      if (left > rect.right) return false;
      if (right < rect.left) return false;
      if (top > rect.bottom) return false;
      if (bottom < rect.top) return false;

      // then they must overlap
      return true;
  }

  Rect Intersect(Rect rect)
  {
      return Intersect(this, rect);
  }

  Rect CenterIn(Rect rect)
  {
      return CenterIn(this, rect);
  }
  */

  // Iterators over the points along the edge of the Rect.
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

class RectIterator {
  final Rect _rect;
  int _x;
  int _y;

  RectIterator(this._rect) {
    _x = _rect.x;
    _y = _rect.y;
  }

  bool hasNext() => _y < _rect.bottom ;

  Vec next() {
    final result = new Vec(_x, _y);
    _x++;
    if (_x >= _rect.right) {
      _x = _rect.x;
      _y++;
    }

    return result;
  }
}
