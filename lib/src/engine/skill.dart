library dngn.engine.skill;

import '../util.dart';
import 'action_base.dart';
import 'game.dart';
import 'item.dart';
import 'melee.dart';

/// Base class for a skill. A skill is a levelable hero ability in the game.
/// The actual concrete skills are defined in content.
abstract class Skill {
  String get name;
  String getHelpText(int level);

  /// Override this to return `true` if the skill has an active use.
  bool get hasUse => false;

  /// Override this to return `true` if the skill can be used but needs a
  /// target to do so.
  bool get needsTarget => false;

  num getAttackAddBonus(int level, Item weapon, Attack attack) => 0;
  num getAttackMultiplyBonus(int level, Item weapon, Attack attack) => 0;
  int modifyHealth(int level) => 0;
  int getDropChance(int level) => 0;

  /// Override this to validate that the [Skill] can be used right now. This
  /// should only be overridden if [hasUse] is `true`. Unlike [hasUse], this
  /// should return `true` if the Skill can be used *right now*. For example,
  /// [hasUse] is always `true` for Archery, but [canUse] is only `true` when
  /// you have a bow equipped.
  ///
  /// If this is overridden and returns `false`, it should also log an
  /// appropriate message so the user knows why it failed.
  bool canUse(int level, Game game) => true;

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Skill]. If the skill needs a target, one will be passed in.
  /// Otherwise, it will be `null`.
  Action getUseAction(int level, Game game, Vec target) {
    throw 'Should be overridden in skills that have uses.';
  }
}

/// The [Hero]'s levels in each skill.
class SkillSet {
  final Map<String, Skill> _skills;
  final Map<String, int> _levels;

  SkillSet(this._skills)
      : _levels = {};

  /// Gets the skills that the [Hero] is at least at level one at.
  Iterable<Skill> get knownSkills =>
      _skills.values.where((skill) => this[skill] > 0);

  /// Gets the hero's level at [skill].
  int operator[](Skill skill) {
    int level = _levels[skill.name];
    return level == null ? 0 : level;
  }

  /// Sets the hero's level at [skill].
  operator[]=(Skill skill, int level) {
    _levels[skill.name] = level;
  }

  /// Applies [callback] to every skill in the set.
  void forEach(void callback(Skill skill, int level)) {
    for (final skill in _skills.values) callback(skill, this[skill]);
  }
}