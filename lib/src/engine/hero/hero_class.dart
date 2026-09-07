import '../item/item_type.dart';
import 'power.dart';
import 'skill.dart';

/// The hero's class.
class HeroClass {
  final String name;

  final String description;

  /// The maximum skill level that skills in a domain can have.
  ///
  /// If the [Domain] isn't present, then the class can't learn skills in it
  /// at all.
  final Map<Domain, int> domainCaps;

  final List<Power> powers;

  /// Generates items a hero of this class should start with.
  final Drop startingItems;

  HeroClass(
    this.name,
    this.description,
    this.domainCaps,
    this.powers,
    this.startingItems,
  );

  /// The maximum level of [skill] that a hero with this class can attain or
  /// `0` if they can't learn this skill at all.
  ///
  /// This is the maximum base value before equipment modifiers are applied.
  int skillCap(Skill skill) => domainCaps[skill.domain] ?? 0;
}
