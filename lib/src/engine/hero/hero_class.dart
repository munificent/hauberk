import 'skill.dart';

/// The hero's class.
class HeroClass {
  final String name;

  final String description;

  final Map<Skill, double> _proficiency;

  HeroClass(this.name, this.description, this._proficiency);

  /// How good heroes of this class are at gaining a given skill.
  ///
  /// A proficiency of 1.0 is normal. Zero means "can't gain at all". Numbers
  /// larger than 1.0 make it easier to gain and less than 1.0 harder.
  double proficiency(Skill skill) => _proficiency[skill] ?? 1.0;

  // TODO: Make this do something. (See docs/skills and classes.txt.)
  // It should:
  // - Scale how much experience is needed to level up.
  // - Scale how much training is needed to improve a skill.
  // - Scale the focus cost of spells.
  // - Scale the gold cost of tricks.
  // - Scale the piety cost of prayers and granted powers.
}
