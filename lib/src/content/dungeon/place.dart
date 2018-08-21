import 'package:piecemeal/piecemeal.dart';

import 'dungeon.dart';

abstract class Place {
  final bool hasHero;
  final bool emanates;
  final List<Vec> cells;

  final Set<Place> neighbors = Set();

  double monsterDensity;
  int monsterDepthOffset = 0;
  double itemDensity;
  int itemDepthOffset = 0;

  // TODO: In addition to painting themes on places, also paint level
  // adjustment. So if an out of depth monster is spawned, it increases the
  // level of the place for subsequent floor drops.

  Dungeon _dungeon;

  /// The themes this place contains and the strength of each.
  final Map<String, double> themes = {};

  double totalStrength = 0.0;

  Place(this.cells, this.monsterDensity, this.itemDensity,
      {this.hasHero = false, this.emanates = false});

  void bind(Dungeon dungeon) {
    assert(_dungeon == null, "Can only bind once.");
    _dungeon = dungeon;
  }

  void applyThemes();

  void addTheme(String theme, double strength, {bool spread = true}) {
    themes.putIfAbsent(theme, () => 0.0);
    themes[theme] += strength;
    totalStrength += strength;

    if (spread) _dungeon.spreadTheme(this, theme, strength);
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
