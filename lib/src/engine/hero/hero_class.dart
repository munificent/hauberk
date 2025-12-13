import '../items/item_type.dart';
import 'skill.dart';

/// The hero's class.
class HeroClass {
  final String name;

  final String description;

  final Map<Skill, int> _skillCaps;

  /// Generates items a hero of this class should start with.
  final Drop startingItems;

  HeroClass(this.name, this.description, this._skillCaps, this.startingItems);

  /// The maximum level of [skill] that a hero with this class can attain or
  /// `0` if they can't learn this skill at all.
  int skillCap(Skill skill) => _skillCaps[skill] ?? 0;
}
