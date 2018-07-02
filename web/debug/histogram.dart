import 'dart:math' as math;

class Histogram<T> {
  final Map<T, int> _counts = {};

  int get max => _counts.values.fold(0, math.max);

  int get total => _counts.values.fold(0, (a, b) => a + b);

  int add(T object) {
    _counts.putIfAbsent(object, () => 0);
    return ++_counts[object];
  }

  int count(T object) {
    if (!_counts.containsKey(object)) return 0;
    return _counts[object];
  }

  List<T> ascending() {
    var objects = _counts.keys.toList();
    objects.sort((a, b) => _counts[a].compareTo(_counts[b]));
    return objects;
  }

  List<T> descending() {
    var objects = _counts.keys.toList();
    objects.sort((a, b) => _counts[b].compareTo(_counts[a]));
    return objects;
  }
}
