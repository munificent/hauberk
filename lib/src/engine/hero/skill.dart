import 'dart:math' as math;

import '../core/combat.dart';
import '../item/item.dart';
import '../monster/monster.dart';
import 'ability.dart';
import 'hero.dart';
import 'hero_save.dart';
import 'stat.dart';

/// An immutable unique skill a hero may learn.
///
/// This class does not contain how good a hero is at the skill. It is more the
/// *kind* of skill.
abstract class Skill implements Comparable<Skill> {
  /// The highest level a skill can have just from spending experience,
  /// ignoring any class-specific restrictions.
  static const baseMax = 10;

  /// The highest level a skill can have after all equipment modifiers are
  /// applied.
  static const modifiedMax = 15;

  static int experienceCostAt(int baseExperience, int level) {
    // Level 1 is [baseExperience] and every level above that is 1.5x the
    // previous level. In other wors, it works like compound interest:
    // https://en.wikipedia.org/wiki/Compound_interest
    return (baseExperience * math.pow(1 + 0.8, level - 1)).toInt();
  }

  static int _nextSortOrder = 0;

  final int _sortOrder = _nextSortOrder++;

  String get name;

  String get description;

  /// The experience cost to reach level one in this skill.
  int get baseExperience => 1000;

  // TODO: May want this to be per-level at some point if there are skills that
  // grant multiple abilities at different levels.
  /// If this skill grants an ability, the ability.
  Ability? get ability => _ability;
  late final Ability? _ability = initializeAbility();

  String levelDescription(int level);

  /// The amount of experience to increase the skill to [level] from the
  /// previous level.
  int experienceCost(HeroSave hero, int level) {
    return experienceCostAt(baseExperience, level);
  }

  /// Gives the skill a chance to modify the melee [hit] the [hero] is about to
  /// perform on [monster] when using [weapon].
  void modifyHit(
    Hero hero,
    Monster? monster,
    Item? weapon,
    Hit hit,
    int level,
  ) {}

  /// Gives the skill a chance to modify the ranged [hit] the [hero] is about to
  /// fire using [weapon].
  void modifyRangedHit(Hero hero, Item? weapon, Hit hit, int level) {}

  /// Modifies the hero's base armor.
  int modifyArmor(HeroSave hero, int level, int armor) => armor;

  /// Gives the skill a chance to add new defenses to the hero.
  Iterable<Defense> defenses(Hero hero, int level) => const [];

  /// Gives the skill a chance to adjust the [heftModifier] applied to the base
  /// heft of a weapon.
  double modifyHeft(Hero hero, int level, double heftModifier) => heftModifier;

  /// Called once for the skill to create its [Ability] if it has one.
  Ability? initializeAbility() => null;

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

enum SpellStatus {
  /// The hero hasn't learned the spell, but could.
  learnable,

  /// The hero has already learned as many spells as their [Intellect] allows
  /// so can't learn this (or any other spell) right now.
  notEnoughIntellect,

  /// The hero's level in the spell's spell school isn't high enough to learn
  /// this spell.
  notEnoughSchool,

  /// The hero has learned and currently knows the spell.
  known,

  /// The hero learned the spell but forgot it because their [Intellect] is
  /// currently too low.
  forgotten,
}
