import 'dart:math' as math;

/// Attribute have a natural range from 10 to 50. That's the range of values a
/// stat may have before any equipment or statuses come into play. External
/// effects increase the range to 0 to 60, so all stats have well-defined
/// semantics across that entire range.
///
/// Zero means the hero is nearly incapacitated. Zero strength is practically
/// paralyzed. Zero intellect is catatonic.
///
/// Ten means a weak but healthy human. Twenty is about average for a
/// run-of-the-mill citizen but below average for a heroic adventuruer. Thirty
/// is impressive. Forty is heroic. Fifty is practically superhuman. Sixty is
/// literally superhuman.
///
/// The natural range is chosen such that when a hero is fully leveled up, they
/// can only max a couple of stats. This helps ensure that endgame play still
/// has variety.
///
/// The numbers I currently have in mind for this are:
///
/// - All attributes start at 10.
/// - A new hero starts with 12 free points they can spend to raise attributes.
/// - Every level gained gives 2 more points.
/// - Max level is 50 (so 49 levels *gained* since it starts at 1).
/// - That gives a total of 110 earnable points.
///
/// If a player spent them making a maximally unbalanced set of attributes,
/// that would lead to 50, 50, 40, 10, 10. So two maxed, one boosted, and two
/// untouched. A balanced set would be 32 for all attributes, which is right in
/// the middle of the range.
// TODO: How do permanent attribute gain potions effect this? Even with those, I
// don't want you to be able to max out all attributes. Options:
// - No attribute gain consumables.
// - Retain a max total number of gained attribute points (110). Once all
//   attributes have been raised by that total number of points, no more can be
//   spent. ("Your body cannot contain that much power.")
//
//   This could mean leaving unspent points on the table forever if the player
//   both maxes their level and finds attribute gain potions. We could balance
//   that by having ways to permanently *spend* attributes such as using them to
//   imbue equipment.
abstract class Attribute {
  static final strength = new Strength();
  static final agility = new Agility();
  static final fortitude = new Fortitude();
  static final intellect = new Intellect();
  static final will = new Will();

  static final all = [strength, agility, fortitude, intellect, will];

  /// Starting natural value for an attribute;
  static const initialValue = 10;

  /// The total number of points a hero may have across all attributes.
  ///
  /// Setting an overall limit prevents players from maxing out all attributes.
  /// Instead, they have to choose which to specialize in all the way up to the
  /// end game.
  static const totalMax = 160;

  /// The highest value an attribute can have before equipment and other
  /// bonuses come into play.
  static const naturalMax = 50;

  String get name;
}

// missile range
// damage bonus
class Strength extends Attribute {
  static double tossRangeScale(int strength) {
    if (strength <= 20) return _lerpDouble(strength, 1, 20, 0.1, 1.0);
    if (strength <= 30) return _lerpDouble(strength, 20, 30, 1.0, 1.5);
    if (strength <= 40) return _lerpDouble(strength, 30, 40, 1.5, 1.8);
    if (strength <= 30) return _lerpDouble(strength, 40, 50, 1.8, 2.0);
    return _lerpDouble(strength, 50, 60, 2.0, 2.1);
  }

  String get name => "Strength";
}

// strike bonus
// dodge bonus
// thief skills
class Agility extends Attribute {
  String get name => "Agility";
}

// max health
// poison duration
// resist physical effects
// affect food consumption?
class Fortitude extends Attribute {
  static int maxHealth(int value) =>
      (math.pow(value, 1.5) - 0.5 * value + 30).toInt();

  String get name => "Fortitude";
}

// spell power
// resist mental effects
// max mana?
class Intellect extends Attribute {
  String get name => "Intellect";
}

// resist "spiritual" effects
// max mana?
class Will extends Attribute {
  String get name => "Will";
}

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
double _lerpDouble(int value, int min, int max, double outMin, double outMax) {
  assert(value >= min);
  assert(value <= max);
  assert(min < max);

  var t = (value - min) / (max - min);
  return outMin + t * (outMax - outMin);
}
