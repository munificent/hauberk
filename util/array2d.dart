library util.array2d;

import 'dart:collection';

import 'rect.dart';
import 'vec.dart';

class Array2D<T> extends IterableBase<T> {
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
}
