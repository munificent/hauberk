import 'package:piecemeal/piecemeal.dart';

import 'hero.dart';
import 'stat.dart';

/// The hero's species.
class Race {
  final String name;

  final String description;

  /// The base number of points a hero of this race will attain by the max
  /// level for each stat.
  final Map<Stat, int> stats;

  Race(this.name, this.description, this.stats);

  /// Determines how the hero's stats should increase at each level based on
  /// this race.
  RaceStats rollStats() {
    // Pick specific values for each stat.
    var rolled = <Stat, int>{};
    for (var stat in stats.keys) {
      var base = stats[stat];
      var value = base;

      // Randomly boost the max some.
      value += rng.range(4);
      while (value < 50 && rng.percent(base ~/ 2 + 30)) value++;
      rolled[stat] = value;
    }

    return RaceStats(this, rolled, rng.range(100000));
  }
}

/// Tracks the stat points gained at each level due to the hero's race.
class RaceStats {
  final Race _race;
  final Map<Stat, int> _max;

  /// The stat gains are distributed somewhat randomly across levels. This seed
  /// ensures we use the same distribution every time for a given hero.
  /// Otherwise, when saving and loading a hero, their stats could change.
  final int seed;

  /// The values of each stat at every level.
  ///
  /// Indexes into the list are offset by one, so list element 0 represents
  /// hero level 1.
  final List<Map<Stat, int>> _stats = [];

  RaceStats(this._race, this._max, this.seed) {
    var min = <Stat, int>{};
    var current = <Stat, int>{};
    var totalMin = 0;
    var totalMax = 0;
    for (var stat in _max.keys) {
      min[stat] = 10 + _max[stat] ~/ 15;
      totalMin += min[stat];
      totalMax += _max[stat];
      current[stat] = 0;
    }

    var random = Rng(seed);

    // Distribute the total points evenly across the levels.
    var previous = 0;
    for (var level = 0; level < Hero.maxLevel; level++) {
      double lerp(int from, int to) {
        var t = level / (Hero.maxLevel - 1);
        return (1.0 - t) * from + t * to;
      }

      // Figure out how many total stat points should have been distributed by
      // this level.
      var points = lerp(totalMin, totalMax).toInt();
      var gained = points - previous;

      // Distribute the points across the stats.
      for (var point = 0; point < gained; point++) {
        // The "error" is how far a stat's current value is from where it
        // should ideally be at this level. The stat with the largest error is
        // the one who gets this point.
        var worstError = -100.0;
        var worstStats = <Stat>[];

        for (var stat in _max.keys) {
          var ideal = lerp(min[stat], _max[stat]);
          var error = ideal - current[stat];

          if (error > worstError) {
            worstStats = [stat];
            worstError = error;
          } else if (error == worstError) {
            worstStats.add(stat);
          }
        }

        // Increment the stat whose value is furthest from the ideal.
        var stat = random.item(worstStats);
        current[stat]++;
      }

      _stats.add(Map<Stat, int>.from(current));
      previous = points;
    }
  }

  String get name => _race.name;

  /// The maximum number of points of [stat] the hero will gain.
  int max(Stat stat) => _max[stat];

  int valueAtLevel(Stat stat, int level) => _stats[level - 1][stat];
}
