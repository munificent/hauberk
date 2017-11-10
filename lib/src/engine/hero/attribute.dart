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
class Attribute {
  static final strength = new Attribute("Strength");
  static final agility = new Attribute("Agility");
  static final fortitude = new Attribute("Fortitude");
  static final intellect = new Attribute("Intellect");
  static final will = new Attribute("Will");

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

  final String name;

  Attribute(this.name);
}
