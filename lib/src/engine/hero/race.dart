import 'package:piecemeal/piecemeal.dart';

import 'attribute.dart';
import 'hero.dart';

/// The hero's species.
class Race {
  final String name;

  final String description;

  /// The base number of points a hero of this race will attain by the max
  /// level for each attribute.
  final Map<Attribute, int> attributes;

  Race(this.name, this.description, this.attributes);

  /// Determines how the hero's attributes should increase at each level based
  /// on this race.
  RaceAttributes rollAttributes() {
    // Pick specific values for each attribute.
    var rolled = <Attribute, int>{};
    for (var attribute in attributes.keys) {
      var base = attributes[attribute];
      var value = base;

      // Randomly boost the max some.
      value += rng.range(4);
      while (value < 50 && rng.percent(base ~/ 2 + 30)) value++;
      rolled[attribute] = value;
    }

    return new RaceAttributes(this, rolled, rng.range(100000));
  }
}

// TODO: Make the engine actually use these.
/// Tracks the attribute points gained at each level due to the hero's race.
class RaceAttributes {
  final Race _race;
  final Map<Attribute, int> _max;

  /// The attribute gains are distributed somewhat randomly across levels. This
  /// seed ensures we use the same distribute every time for a given hero.
  /// Otherwise, when saving and loading a hero, their stats could change.
  final int seed;

  /// The values of each attribute at every level.
  ///
  /// Indexes into the list are offset by one, so list element 0 represents
  /// hero level 1.
  final List<Map<Attribute, int>> _attributes = [];

  RaceAttributes(this._race, this._max, this.seed) {
    var min = <Attribute, int>{};
    var current = <Attribute, int>{};
    var totalMin = 0;
    var totalMax = 0;
    for (var attribute in _max.keys) {
      min[attribute] = 10 + _max[attribute] ~/ 15;
      totalMin += min[attribute];
      totalMax += _max[attribute];
      current[attribute] = 0;
    }

    var random = new Rng(seed);

    // Distribute the total points evenly across the levels.
    var previous = 0;
    for (var level = 0; level < Hero.maxLevel; level++) {
      double lerp(int from, int to) {
        var t = level / (Hero.maxLevel - 1);
        return (1.0 - t) * from + t * to;
      }

      // Figure out how many total attribute points should have been
      // distributed by this level.
      var points = lerp(totalMin, totalMax).toInt();
      var gained = points - previous;

      // Distribute the points across the attributes.
      for (var point = 0; point < gained; point++) {
        // The "error" is how far a attribute's current value is from where it
        // should ideally be at this level. The attribute with the largest
        // error is the one who gets this point.
        var worstError = -100.0;
        var worstAttributes = <Attribute>[];

        for (var attribute in _max.keys) {
          var ideal = lerp(min[attribute], _max[attribute]);
          var error = ideal - current[attribute];

          // TODO: If multiple attributes have the same error, this always
          // prefers the first one (i.e. Strength before Agility, etc.). Would
          // be nice to mix that up. But note that we can't use rng() here
          // because this code needs to be deterministic so that gains don't
          // get reshuffled when loaded from storage.
          if (error > worstError) {
            worstAttributes = [attribute];
            worstError = error;
          } else if (error == worstError) {
            worstAttributes.add(attribute);
          }
        }

        // Increment the attribute whose value is furthest from the ideal.
        var attribute = random.item(worstAttributes);
        current[attribute]++;
      }

      _attributes.add(new Map<Attribute, int>.from(current));
      previous = points;
    }
  }

  String get name => _race.name;

  /// The maximum number of points of [attribute] the hero will gain.
  int max(Attribute attribute) => _max[attribute];

  int valueAtLevel(Attribute attribute, int level) =>
      _attributes[level - 1][attribute];
}
