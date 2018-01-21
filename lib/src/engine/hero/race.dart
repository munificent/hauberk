import 'package:piecemeal/piecemeal.dart';

import 'attribute.dart';
import 'hero.dart';

/// The hero's species.
class Race {
  final String name;

  final String description;

  /// The average number of points a hero of this race will attain by the max
  /// level for each attribute.
  final Map<Attribute, int> attributes;

  Race(this.name, this.description, this.attributes);

  /// Determines how the hero's attributes should increase at each level based
  /// on this race.
  RaceAttributes rollAttributes() {
    // Pick specific values for each attribute.
    var rolled = <Attribute, int>{};
    for (var attribute in attributes.keys) {
      var average = attributes[attribute];
      var value = rng.triangleInt(average, average ~/ 3) + rng.taper(0, 2);
      rolled[attribute] = value;
    }

    return new RaceAttributes(this, rolled);
  }
}

// TODO: Make the engine actually use these.
/// Tracks the attribute points gained at each level due to the hero's race.
class RaceAttributes {
  final Race _race;
  final Map<Attribute, int> _max;
  final Map<int, Map<Attribute, int>> _gains = {};

  RaceAttributes(this._race, this._max) {
    var current = <Attribute, int>{};
    var total = 0;
    for (var attribute in _max.keys) {
      total += _max[attribute];
      current[attribute] = 0;
    }

    // Distribute the total points evenly across the levels.
    var previous = 0;
    for (var level = 2; level <= Hero.maxLevel; level++) {
      var levelMap =
          new Map<Attribute, int>.fromIterable(_max.keys, value: (_) => 0);
      _gains[level] = levelMap;

      // Figure out how many points of any attribute are gained at this level.
      var points = (total * (level / Hero.maxLevel)).toInt();
      var gained = points - previous;

      // Figure out which attributes are most in need of being raised.
      for (var point = 0; point < gained; point++) {
        // The "error" is how far a attribute's current value is from where it
        // should ideally be at this level. The attribute with the largest
        // error is the one who gets this point.
        var worstError = -100.0;
        Attribute worstAttribute;

        for (var attribute in _max.keys) {
          var ideal = _max[attribute] * (level / Hero.maxLevel);
          var error = ideal - current[attribute];

          // TODO: If multiple attributes have the same error, this always
          // prefers the first one (i.e. Strength before Agility, etc.). Would
          // be nice to mix that up. But note that we can't use rng() here
          // because this code needs to be deterministic so that gains don't
          // get reshuffled when loaded from storage.
          if (error > worstError) {
            worstAttribute = attribute;
            worstError = error;
          }
        }

        // Increment the attribute whose value is furthest from the ideal.
        levelMap[worstAttribute]++;
        current[worstAttribute]++;
      }

      previous = points;
    }
  }

  String get name => _race.name;

  /// The maximum number of points of [attribute] the hero will gain.
  int max(Attribute attribute) => _max[attribute];

  /// The number of points [attribute] increases at [level].
  int gain(int level, Attribute attribute) => _gains[level][attribute];
}
