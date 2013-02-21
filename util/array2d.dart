part of util;

class Array2D<T> implements Iterable<T> {
  final int width;
  final int height;
  final List<T> elements;

  Array2D(width_, height_, T generator())
  : width = width_,
    height = height_,
    elements = new List<T>(width_ * height_)
  {
    for (int i = 0; i < width * height; i++) {
      elements[i] = generator();
    }
  }

  T operator[](Vec pos) => elements[pos.y * width + pos.x];

  void operator[]=(Vec pos, T value) {
    elements[pos.y * width + pos.x] = value;
  }

  Rect get bounds => new Rect(0, 0, width, height);
  Vec  get size => new Vec(width, height);

  // TODO(bob): Multi-argument subscript operators would be nice.
  T get(int x, int y) => elements[y * width + x];

  void set(int x, int y, T value) {
    elements[y * width + x] = value;
  }

  void fill(T generator(Vec pos)) {
    for (final pos in bounds) {
      this[pos] = generator(pos);
    }
  }

  Iterator<T> get iterator => elements.iterator;

  // TODO(bob): Use a mixin when available.
  int get length {
    throw new UnimplementedError();
  }
  bool get isEmpty => IterableMixinWorkaround.isEmpty(this);
  T get first => IterableMixinWorkaround.first(this);
  T get last => IterableMixinWorkaround.last(this);
  T get single => IterableMixinWorkaround.single(this);
  Iterable<T> map(f(T element)) => IterableMixinWorkaround.map(this, f);
  // TODO(bob): Remove when removed from Iterable.
  Iterable<T> mappedBy(f(T element)) => IterableMixinWorkaround.map(this, f);
  Iterable<T> where(bool test(T element)) => IterableMixinWorkaround.where(this, test);
  Iterable expand(f(T element)) => IterableMixinWorkaround.expand(this, f);
  bool contains(T element) => IterableMixinWorkaround.contains(this, element);
  void forEach(void f(T o)) => IterableMixinWorkaround.forEach(this, f);
  bool any(bool f(T o)) => IterableMixinWorkaround.any(this, f);
  bool every(bool f(T o)) => IterableMixinWorkaround.every(this, f);
  reduce(seed, f(accumulator, T o)) => IterableMixinWorkaround.reduce(this, seed, f);
  String join([String separator]) => IterableMixinWorkaround.join(this, separator);
  List<T> toList() => new List.from(this);
  Set<T> toSet() => new Set.from(this);
  T min([int compare(T a, T b)]) => IterableMixinWorkaround.min(this, compare);
  T max([int compare(T a, T b)]) => IterableMixinWorkaround.max(this, compare);
  Iterable<T> take(int n) {
    throw new UnimplementedError();
  }
  Iterable<T> takeWhile(bool test(T value)) => IterableMixinWorkaround.takeWhile(this, test);
  Iterable<T> skip(int n) {
    throw new UnimplementedError();
  }
  Iterable<T> skipWhile(bool test(T value)) => IterableMixinWorkaround.skipWhile(this, test);
  T firstMatching(bool test(T value), {T orElse()}) => IterableMixinWorkaround.firstMatching(this, test, orElse);
  T lastMatching(bool test(T value), {T orElse()}) => IterableMixinWorkaround.lastMatching(this, test, orElse);
  T singleMatching(bool test(T value)) => IterableMixinWorkaround.singleMatching(this, test);
  T elementAt(int index) => IterableMixinWorkaround.elementAt(this, index);
}
