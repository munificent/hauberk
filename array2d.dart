class Array2D<T> {
  final int width;
  final int height;
  final List<T> elements;

  Array2D(width_, height_, T generator())
  : width = width_,
    height = height_,
    elements = new List<T>(width_ * height_) {
    for (int i = 0; i < width * height; i++) {
      elements[i] = generator();
    }
  }

  // TODO(bob): Bounds check.
  // TODO(bob): Multi-argument subscript operators would be nice.
  T get(int x, int y) => elements[y * width + x];
  void set(int x, int y, T value) => elements[y * width + x] = value;
}
