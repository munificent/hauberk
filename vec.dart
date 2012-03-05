
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

// TODO(bob): Finish porting from C#. Figure out how to handle overloads.
/// A two-dimensional rectangle.
class Rect {
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

  const Rect(this.pos, this.size);

  /*
  const Rect(this.size)
  : pos = Vec.zero;

  const Rect(int x, int y, int width, int height)
  : pos = const Vec(x, y),
    size = const Vec(width, height));

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

  Rect Inflate(int distance)
  {
      return new Rect(mPos.Offset(-distance, -distance), mSize.Offset(distance * 2, distance * 2));
  }

  bool Contains(Vec pos)
  {
      if (pos.x < mPos.x) return false;
      if (pos.x >= mPos.x + mSize.x) return false;
      if (pos.y < mPos.y) return false;
      if (pos.y >= mPos.y + mSize.y) return false;

      return true;
  }

  bool Contains(Rect rect)
  {
      // all sides must be within
      if (rect.left < left) return false;
      if (rect.right > right) return false;
      if (rect.top < top) return false;
      if (rect.bottom > bottom) return false;

      return true;
  }

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

  IEnumerable<Vec> Trace()
  {
      if ((width > 1) && (height > 1))
      {
          // trace all four sides
          foreach (Vec top in Row(TopLeft, width - 1)) yield return top;
          foreach (Vec right in Column(TopRight.OffsetX(-1), height - 1)) yield return right;
          foreach (Vec bottom in Row(width - 1)) yield return BottomRight.Offset(-1, -1) - bottom;
          foreach (Vec left in Column(height - 1)) yield return BottomLeft.OffsetY(-1) - left;
      }
      else if ((width > 1) && (height == 1))
      {
          // a single row
          foreach (Vec pos in Row(TopLeft, width)) yield return pos;
      }
      else if ((height >= 1) && (width == 1))
      {
          // a single column, or one unit
          foreach (Vec pos in Column(TopLeft, height)) yield return pos;
      }

      // otherwise, the rect doesn't have a positive size, so there's nothing to trace
  }
  */
}
