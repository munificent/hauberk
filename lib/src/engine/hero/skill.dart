import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/combat.dart';
import '../core/game.dart';
import '../monster/breed.dart';
import '../monster/monster.dart';
import 'hero.dart';
import 'hero_class.dart';
import 'hero_save.dart';
import 'lore.dart';
import 'stat.dart';

/// An immutable unique skill a hero may learn.
///
/// This class does not contain how good a hero is at the skill. It is more the
/// *kind* of skill.
abstract class Skill implements Comparable<Skill> {
  static int _nextSortOrder = 0;

  final int _sortOrder = _nextSortOrder++;

  String get name;

  String get description;

  /// The name shown when using the skill.
  ///
  /// By default, this is the same as the name of the skill, but it differs
  /// for some.
  String get useName => name;

  // TODO: Different messages for gain and lose?
  /// Message displayed when the hero reaches [level] in the skill.
  String gainMessage(int level);

  /// Message displayed when the hero first discovers this skill.
  String get discoverMessage;

  int get maxLevel;

  // TODO: Not used right now. Might be useful for rogue skills.
  /*
  Skill get prerequisite => null;
  */

  /// Determines what level [hero] has in this skill.
  int calculateLevel(HeroSave hero) =>
      onCalculateLevel(hero, hero.skills.points(this));

  int onCalculateLevel(HeroSave hero, int points);

  /// Called when the hero takes damage.
  void takeDamage(Hero hero, int damage) {}

  /// Called the first time the hero has seen a monster of [breed].
  void seeBreed(Hero hero, Breed breed) {}

  /// Called when the hero kills [monster].
  void killMonster(Hero hero, Action action, Monster monster) {}

  /// Called when the hero is dual-wielding two weapons.
  void dualWield(Hero hero) {}

  // TODO: Rename to "modifyHit".
  /// Gives the skill a chance to modify the [hit] the [hero] is about to
  /// perform on [monster].
  void modifyAttack(Hero hero, Monster? monster, Hit hit, int level) {}

  /// Modifies the hero's base armor.
  int modifyArmor(HeroSave hero, int level, int armor) => armor;

  /// Gives the skill a chance to add new defenses to the hero.
  Defense? getDefense(Hero hero, int level) => null;

  /// Gives the skill a chance to adjust the [heftModifier] applied to the base
  /// heft of a weapon.
  double modifyHeft(Hero hero, int level, double heftModifier) => heftModifier;

  /// Gives the skill a chance to modify the hit the hero is about to receive.
// TODO: Not currently used.
//  void modifyDefense(Hit hit) {}

  @override
  int compareTo(Skill other) => _sortOrder.compareTo(other._sortOrder);
}

/// Additional interface for active skills that expose a command the player
/// can invoke.
///
/// Some skills require additional data to be performed -- a target position
/// or a direction. Those will implement one of the subclasses, [TargetSkill]
/// or [DirectionSkill].
mixin UsableSkill implements Skill {
  /// The focus cost to use the skill, with proficiency applied.
  int focusCost(HeroSave hero, int level) => 0;

  /// If the skill cannot currently be used (for example Archery when a bow is
  /// not equipped), returns the reason why. Otherwise, returns `null` to
  /// indicate the skill is usable.
  String? unusableReason(Game game) => null;

  /// If this skill has a focus or fury cost, wraps [action] in an appropriate
  /// action to spend that.
  Action _wrapActionCost(HeroSave hero, int level, Action action) {
    if (focusCost(hero, level) > 0) {
      return FocusAction(focusCost(hero, level), action);
    }

    return action;
  }
}

/// A skill that can be directly used to perform an action.
mixin ActionSkill implements UsableSkill {
  Action getAction(Game game, int level) {
    return _wrapActionCost(game.hero.save, level, onGetAction(game, level));
  }

  Action onGetAction(Game game, int level);
}

/// A skill that requires a target position to perform.
mixin TargetSkill implements UsableSkill {
  bool get canTargetSelf => false;

  /// The maximum range of the target from the hero.
  int getRange(Game game);

  Action getTargetAction(Game game, int level, Vec target) {
    return _wrapActionCost(
        game.hero.save, level, onGetTargetAction(game, level, target));
  }

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Skill].
  Action onGetTargetAction(Game game, int level, Vec target);
}

/// A skill that requires a direction to perform.
mixin DirectionSkill implements UsableSkill {
  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Skill].
  Action getDirectionAction(Game game, int level, Direction dir) {
    return _wrapActionCost(
        game.hero.save, level, onGetDirectionAction(game, level, dir));
  }

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Skill].
  Action onGetDirectionAction(Game game, int level, Direction dir);
}

/// Disciplines are the primary [Skill]s of warriors.
///
/// A discipline is "trained", which means to perform an in-game action related
/// to the discipline. For example, killing monsters with a sword trains the
/// Swordfighting discipline.
///
/// The underlying data used to track progress in disciplines is stored in the
/// hero's [Lore].
abstract class Discipline extends Skill {
  @override
  String gainMessage(int level) => "You have reached level $level in $name.";

  @override
  String get discoverMessage => "{1} can begin training in $name.";

  String levelDescription(int level);

  @override
  int onCalculateLevel(HeroSave hero, int points) {
    var training = hero.skills.points(this);
    for (var level = 1; level <= maxLevel; level++) {
      if (training < trainingNeeded(hero.heroClass, level)!) return level - 1;
    }

    return maxLevel;
  }

  /// How close the hero is to reaching the next level in this skill, in
  /// percent, or `null` if this skill is at max level.
  int? percentUntilNext(HeroSave hero) {
    var level = calculateLevel(hero);
    if (level == maxLevel) return null;

    var points = hero.skills.points(this);
    var current = trainingNeeded(hero.heroClass, level)!;
    var next = trainingNeeded(hero.heroClass, level + 1)!;
    return 100 * (points - current) ~/ (next - current);
  }

  /// How much training is needed for a hero of [heroClass] to reach [level],
  /// or `null` if the hero cannot train this skill.
  int? trainingNeeded(HeroClass heroClass, int level) {
    var profiency = heroClass.proficiency(this);
    if (profiency == 0.0) return null;

    return (baseTrainingNeeded(level) / profiency).ceil();
  }

  /// How much training is needed for to reach [level], ignoring class
  /// proficiency.
  int baseTrainingNeeded(int level);
}

/// A collection of [Skill]s and the hero's progress in them.
class SkillSet {
  /// The levels the hero has gained in each skill.
  ///
  /// If a skill is at level zero here, it means the hero has discovered the
  /// skill, but not gained it. If not present in the map at all, the hero has
  /// not discovered it.
  final Map<Skill, int> _levels;

  /// How many points the hero has earned towards the next level of each skill.
  final Map<Skill, int> _points;

  SkillSet()
      : _levels = {},
        _points = {};

  SkillSet.from(this._levels, this._points);

  /// All the skills the hero knows about.
  Iterable<Skill> get discovered => _levels.keys.toList()..sort();

  /// All the skills the hero actually has.
  Iterable<Skill> get acquired =>
      _levels.keys.where((skill) => _levels[skill]! > 0);

  /// Gets the current level of [skill] or 0 if the skill isn't known.
  int level(Skill skill) => _levels[skill] ?? 0;

  /// Gets the current points in [skill] or 0 if the skill isn't known.
  int points(Skill skill) => _points[skill] ?? 0;

  void earnPoints(Skill skill, int points) {
    points += this.points(skill);
    _points[skill] = points;
  }

  /// Learns that [skill] exists.
  ///
  /// Returns `true` if the hero wasn't already aware of this skill.
  bool discover(Skill skill) {
    if (_levels.containsKey(skill)) return false;

    _levels[skill] = 0;
    return true;
  }

  bool gain(Skill skill, int level) {
    level = math.min(level, skill.maxLevel);

    if (_levels[skill] == level) return false;

    // Don't discover the skill if not already known.
    if (level == 0 && !_levels.containsKey(skill)) return false;

    _levels[skill] = level;
    return true;
  }

  /* TODO: Not used right now. Might be useful for rogue skills.
  /// Whether the hero can raise the level of this skill.
  bool canGain(Skill skill) {
    if (!isDiscovered(skill)) return false;
    if (this[skill] >= skill.maxLevel) return false;

    // Must have some level of the prerequisite.
    if (skill.prerequisite != null && this[skill.prerequisite] == 0) {
      return false;
    }

    return true;
  }
  */

  /// Whether the hero is aware of the existence of this skill.
  bool isDiscovered(Skill skill) => _levels.containsKey(skill);

  /// Whether the hero knows of and has learned this skill.
  bool isAcquired(Skill skill) =>
      _levels.containsKey(skill) && _levels[skill]! > 0;

  SkillSet clone() => SkillSet.from(Map.from(_levels), Map.from(_points));

  void update(SkillSet other) {
    _levels.clear();
    _levels.addAll(other._levels);

    _points.clear();
    _points.addAll(other._points);
  }
}
