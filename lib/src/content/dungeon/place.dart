import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import 'dungeon.dart';

abstract class Place {
  final bool hasHero;
  double monsterDensity;
  double itemDensity;
  final List<Vec> cells;

  final Set<Place> neighbors = new Set();

  // TODO: In addition to painting themes on places, also paint level
  // adjustment. So if an out of depth monster is spawned, it increases the
  // level of the place for subsequent floor drops.

  PlaceGraph _graph;

  /// The themes this place contains and the strength of each.
  final Map<String, double> themes = {};

  double totalStrength = 0.0;

  Place(this.cells, this.monsterDensity, this.itemDensity,
      {this.hasHero = false});

  void bind(PlaceGraph graph) {
    assert(_graph == null, "Can only bind once.");
    _graph = graph;
  }

  void applyThemes();

  void addTheme(String theme, double strength, {spread = true}) {
    themes.putIfAbsent(theme, () => 0.0);
    themes[theme] += strength;
    totalStrength += strength;

    if (spread) _graph.spreadTheme(this, theme, strength);
  }

  /// Randomly chooses one of the place's themes, weighted by their strength.
  String chooseTheme() {
    // TODO: Consider binary search if this is slow.
    var i = rng.float(totalStrength);
    for (var theme in themes.keys) {
      if (i < themes[theme]) return theme;
      i -= themes[theme];
    }

    throw "unreachable";
  }
}

class AquaticPlace extends Place {
  AquaticPlace(List<Vec> cells) : super(cells, 0.07, 0.02);

  void applyThemes() {
    addTheme("aquatic", 2.0 + cells.length / 200.0);
  }
}

/// Calculates and stores the connections between places.
class PlaceGraph {
  Array2D<Place> _cells;

  Place placeAt(Vec pos) {
    if (_cells == null) return null;
    return _cells[pos];
  }

  void findConnections(Dungeon dungeon, List<Place> places) {
    // TODO: Should dungeon directly store the place for each cell instead of
    // calculating it here?
    // Store the place that owns each tile.
    _cells = new Array2D<Place>(dungeon.width, dungeon.height);
    for (var place in places) {
      for (var cell in place.cells) {
        _cells[cell] = place;
      }
    }

    // Find adjacent places.
    for (var pos in dungeon.bounds.inflate(-1)) {
      var from = _cells[pos];
      if (from == null) continue;

      for (var direction in Direction.cardinal) {
        var to = _cells[pos + direction];
        if (to != null && to != from) {
          from.neighbors.add(to);
          to.neighbors.add(from);
        }
      }
    }

    for (var place in places) {
      place.bind(this);
    }
  }

  void spreadTheme(Place start, String theme, double strength) {
    var visited = {start: strength};
    var queue = new Queue<Place>();
    queue.add(start);

    while (queue.isNotEmpty) {
      var here = queue.removeFirst();
      // TODO: Attenuate less based on place size or type? It might be nice if
      // passages didn't attenuate as much as rooms.
      var strength = visited[here] / 2.0;
      if (strength < 0.3) continue;

      for (var neighbor in here.neighbors) {
        if (visited.containsKey(neighbor)) continue;

        neighbor.themes.putIfAbsent(theme, () => 0.0);
        neighbor.themes[theme] += strength;
        neighbor.totalStrength += strength;

        visited[neighbor] = strength;
        queue.add(neighbor);
      }
    }
  }
}
