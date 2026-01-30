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
  static const maxLevel = 20;

  static int experienceCostAt(int baseExperience, int level) {
    // return (baseExperience * math.pow((level + 1) / 2, 4)).toInt();
    return (baseExperience * math.pow((level + 2) / 3, 4)).toInt();
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

// TODO: Remove this class?
/// A collection of [Skill]s and the hero's progress in them.
class SkillSet {
  /// The levels the hero has gained in each skill.
  final Map<Skill, int> _levels;

  SkillSet() : _levels = {};

  SkillSet.from(this._levels);

  /// All the skills the hero has at least one level in.
  Iterable<Skill> get acquired => _levels.keys;

  /// Gets the current level of [skill].
  int level(Skill skill) => _levels[skill] ?? 0;

  void setLevel(Skill skill, int level) {
    assert(level > 0 && level <= Skill.maxLevel);
    _levels[skill] = level;
  }

  SkillSet clone() => SkillSet.from({..._levels});
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
