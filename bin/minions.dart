import 'dart:math' as math;

import 'package:hauberk/src/content/monster/monsters.dart';

const trials = 1000;

void main() {
  Monsters.initialize();

  for (var breed in Monsters.breeds.all) {
    if (breed.minions == null) continue;

    var histogram = Histogram<String>();
    for (var i = 0; i < trials; i++) {
      // Minions are weaker than the main breed.
      var minionDepth = (breed.depth * 0.9).floor();
      breed.minions.spawnBreed(minionDepth, (minion) {
        histogram.add(minion.name);
      });
    }

    var total = (histogram.total / trials).toStringAsFixed(2);
    print("${breed.name} ($total)");
    for (var minion in histogram.descending()) {
      var count =
          (histogram.count(minion) / trials).toStringAsFixed(2).padLeft(4);
      print("- $count $minion");
    }
  }
}

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
