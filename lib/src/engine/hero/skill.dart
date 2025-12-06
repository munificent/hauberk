import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/combat.dart';
import '../core/game.dart';
import '../items/item.dart';
import '../monster/monster.dart';
import 'hero.dart';
import 'hero_save.dart';

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

  int get maxLevel;

  String levelDescription(int level);

  /// The amount of experience to increase the skill to [level] from the
  /// previous level or `null` if it can't be raised to that level.
  int? experienceCost(HeroSave hero, int level) {
    if (level > maxLevel) return null;

    // TODO: Implement for real.
    return 1234;
  }

  /// Gives the skill a chance to modify the [hit] the [hero] is about to
  /// perform on [monster] when using [weapon].
  void modifyHit(
    Hero hero,
    Monster? monster,
    Item? weapon,
    Hit hit,
    int level,
  ) {}

  /// Modifies the hero's base armor.
  int modifyArmor(HeroSave hero, int level, int armor) => armor;

  /// Gives the skill a chance to add new defenses to the hero.
  Defense? getDefense(Hero hero, int level) => null;

  /// Gives the skill a chance to adjust the [heftModifier] applied to the base
  /// heft of a weapon.
  double modifyHeft(Hero hero, int level, double heftModifier) => heftModifier;

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
      game.hero.save,
      level,
      onGetTargetAction(game, level, target),
    );
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
      game.hero.save,
      level,
      onGetDirectionAction(game, level, dir),
    );
  }

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Skill].
  Action onGetDirectionAction(Game game, int level, Direction dir);
}

// TODO: Remove this class?
/// A collection of [Skill]s and the hero's progress in them.
class SkillSet {
  /// The levels the hero has gained in each skill.
  ///
  /// If a skill is at level zero here, it means the hero has discovered the
  /// skill, but not gained it. If not present in the map at all, the hero has
  /// not discovered it.
  final Map<Skill, int> _levels;

  SkillSet() : _levels = {};

  SkillSet.from(this._levels);

  /// All the skills the hero has at least one level in.
  Iterable<Skill> get acquired => _levels.keys;

  /// Gets the current level of [skill] or 0 if the skill isn't known.
  int level(Skill skill) => _levels[skill] ?? 0;

  void setLevel(Skill skill, int level) {
    assert(level > 0 && level <= skill.maxLevel);
    _levels[skill] = level;
  }

  SkillSet clone() => SkillSet.from({..._levels});
}
