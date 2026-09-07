import 'dart:math' as math;

import 'hero_save.dart';
import 'power.dart';

/// An immutable unique skill a hero may learn.
///
/// This class does not contain how good a hero is at the skill. It is more the
/// *kind* of skill.
abstract class Skill with Capability implements Comparable<Skill> {
  /// The highest level a skill can have just from spending experience,
  /// ignoring any class-specific restrictions.
  static const baseMax = 10;

  /// The highest level a skill can have after all equipment modifiers are
  /// applied.
  static const modifiedMax = 15;

  static int experienceCostAt(int baseExperience, int level) {
    // Level 1 is [baseExperience] and every level above that is 1.8x the
    // previous level. In other wors, it works like compound interest:
    // https://en.wikipedia.org/wiki/Compound_interest
    return (baseExperience * math.pow(1.8, level - 1)).toInt();
  }

  static int _nextSortOrder = 0;

  final int _sortOrder = _nextSortOrder++;

  String get name;

  String get description;

  /// The experience cost to reach level one in this skill.
  int get baseExperience => 1000;

  String levelDescription(int level);

  /// The amount of experience to increase the skill to [level] from the
  /// previous level.
  int experienceCost(HeroSave hero, int level) {
    return experienceCostAt(baseExperience, level);
  }

  @override
  int compareTo(Skill other) => _sortOrder.compareTo(other._sortOrder);
}

/// A collection of [Skill]s and the hero's progress in them.
class SkillSet {
  /// The levels the hero has gained in each skill.
  final Map<Skill, int> _gainedLevels;

  /// Level offsets from equipment or other modifiers.
  final Map<Skill, int> _bonusLevels = {};

  SkillSet() : _gainedLevels = {};

  SkillSet.from(this._gainedLevels);

  /// All the skills the hero has at least one level in.
  Iterable<Skill> get acquired => _gainedLevels.keys;

  /// Gets the hero's current innate level in [skill], excluding any bonuses.
  int baseLevel(Skill skill) => _gainedLevels[skill] ?? 0;

  /// Gets the total equipment-related bonuses applied to [skill].
  int bonus(Skill skill) => _bonusLevels[skill] ?? 0;

  /// Gets the current level of [skill] including any bonuses.
  int level(Skill skill) => (baseLevel(skill) + (_bonusLevels[skill] ?? 0))
      .clamp(0, Skill.modifiedMax);

  void setLevel(Skill skill, int level) {
    assert(level > 0 && level <= Skill.baseMax);
    _gainedLevels[skill] = level;
  }

  void refreshBonuses(HeroSave hero) {
    var previousBonuses = {..._bonusLevels};
    _bonusLevels.clear();
    for (var item in hero.equipment) {
      item.skillBonuses.forEach((skill, bonus) {
        _bonusLevels.putIfAbsent(skill, () => 0);
        _bonusLevels[skill] = _bonusLevels[skill]! + bonus;
      });
    }

    // Let the player know what changed.
    _bonusLevels.forEach((skill, newBonus) {
      var oldBonus = previousBonuses[skill] ?? 0;
      if (oldBonus != newBonus) {
        // TODO: Better message.
        hero.log.gain("You are at level ${level(skill)} in ${skill.name}.");
      }
    });
  }

  SkillSet clone() => SkillSet.from({..._gainedLevels});
}
