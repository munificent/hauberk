import '../items/item_type.dart';
import 'skill.dart';

/// The hero's class.
class HeroClass {
  final String name;

  final String description;

  final Map<Skill, double> _proficiency;

  /// Generates items a hero of this class should start with.
  final Drop startingItems;

  HeroClass(this.name, this.description, this._proficiency, this.startingItems);

  /// How adept heroes of this class are at a given skill.
  ///
  /// A proficiency of 1.0 is normal. Zero means "can't acquire at all". Numbers
  /// larger than 1.0 make the skill easier to acquire or more powerful.
  double proficiency(Skill skill) => _proficiency[skill] ?? 1.0;
}
