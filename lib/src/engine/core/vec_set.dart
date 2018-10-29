import 'dart:collection';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

// TODO: Are there other places we should use this?
/// An optimized set of vectors within a given rectangle.
///
/// It's relatively slow to construct, but can be reused efficiently using
/// [clear].
class VecSet extends IterableBase<Vec> {
  /// The current value at each cell.
  ///
  /// To avoid the expense of clearing every cell when done, we instead use a
  /// sentinel value to indicate which cells are present. To "clear" the array,
  /// we just increment to a new sentinel value.
  final Array2D<int> _values;

  /// The current sentinel value.
  ///
  /// Any cells in [_values] that have this value are in the set.
  int _sentinel = 0;

  /// The bounding box surrounding all set values.
  ///
  /// This lets us efficiently iterate over the present cells without going over
  /// large empty regions.
  int _xMin;
  int _xMax;
  int _yMin;
  int _yMax;

  VecSet(int width, int height)
      : _values = Array2D(width, height, 0),
        _xMin = width,
        _xMax = 0,
        _yMin = height,
        _yMax = 0;

  @override
  Iterator<Vec> get iterator {
    var result = <Vec>[];
    for (var y = _yMin; y <= _yMax; y++) {
      for (var x = _xMin; x <= _xMax; x++) {
        if (_values.get(x, y) == _sentinel) result.add(Vec(x, y));
      }
    }

    return result.iterator;
  }

  void clear() {
    _sentinel++;
    // TODO: Check for overflow?

    _xMin = _values.width;
    _xMax = 0;
    _yMin = _values.height;
    _yMax = 0;
  }

  void add(Vec pos) {
    _values[pos] = _sentinel;
    _xMin = math.min(_xMin, pos.x);
    _xMax = math.max(_xMax, pos.x);
    _yMin = math.min(_yMin, pos.y);
    _yMax = math.max(_yMax, pos.y);
  }

  bool contains(Object pos) => _values[pos as Vec] == _sentinel;
}
