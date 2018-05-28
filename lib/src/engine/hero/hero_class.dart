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
  // TODO: Probably want more fine-grained control over how this affects
  // various skills. For example, we'll probably want to tune focus cost and
  // complexity for spells independently of each other.
}
