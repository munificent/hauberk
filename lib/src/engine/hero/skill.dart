import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/combat.dart';
import '../core/game.dart';
import 'hero.dart';
import 'hero_class.dart';
import 'lore.dart';

/// An immutable unique skill a hero may learn.
///
/// This class does not contain how good a hero is at the skill. It is more the
/// *kind* of skill.
abstract class Skill {
  String get name;
  String get description;

  int get maxLevel;

  Skill get prerequisite => null;

  String levelDescription(int level);

  /// Gives the skill a chance to modify the hit the hero is about to perform.
  void modifyAttack(Hero hero, Hit hit, int level) {}

  /// Gives the skill a chance to add new defenses to the hero.
  Defense getDefense(Hero hero, int level) => null;

  /// Gives the skill a chance to modify the hit the hero is about to receive.
  void modifyDefense(Hit hit) {}

  // TODO: Requirements.
  // - Must be discovered by finding certain items. (I.e. a spellbook or
  //   weapon of a certain type.)
}

/// Additional interface for active skills that expose a command the player
/// can invoke.
///
/// Some skills require additional data to be performed -- a target position
/// or a direction. Those will implement one of the subclasses, [TargetSkill]
/// or [DirectionSkill].
abstract class UsableSkill extends Skill {
  /// Override this to validate that the [Command] can be used right now. For
  /// example, this is only `true` for the archery skill when the hero has a
  /// ranged weapon equipped.
  bool canUse(Game game);
}

/// A skill that can be directly used to perform an action.
abstract class ActionSkill extends UsableSkill {
  Action getAction(Game game, int level);
}

/// A skill that requires a target position to perform.
abstract class TargetSkill extends UsableSkill {
  /// The maximum range of the target from the hero.
  num getRange(Game game);

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Command].
  Action getTargetAction(Game game, int level, Vec target);
}

/// A skill that requires a direction to perform.
abstract class DirectionSkill extends UsableSkill {
  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Command].
  Action getDirectionAction(Game game, int level, Direction dir);
}

/// Disciplines are the primary [Skill]s of warriors.
///
/// A discipline is "trained", which means to perform an in-game action related
/// to the discipline. For example, killing monsters with a sword trains the
/// [Swordfighting] discipline.
///
/// The underlying data used to track progress in disciplines is stored in the
/// hero's [Lore].
abstract class Discipline extends Skill {
  /// Determines what level this discipline is at given [lore].
  int calculateLevel(HeroClass heroClass, Lore lore) {
    var training = trained(lore);
    for (var level = 1; level <= maxLevel; level++) {
      if (training < trainingNeeded(heroClass, level)) return level - 1;
    }

    return maxLevel;
  }

  /// How close the hero is to reaching the next level in this skill, in
  /// percent, or `null` if this skill is at max level.
  int percentUntilNext(HeroClass heroClass, Lore lore) {
    var level = calculateLevel(heroClass, lore);
    if (level == maxLevel) return null;

    var points = trained(lore);
    var current = trainingNeeded(heroClass, level);
    var next = trainingNeeded(heroClass, level + 1);
    return 100 * (points - current) ~/ (next - current);
  }

  /// The quantity of training the hero has in this discipline.
  int trained(Lore lore);

  /// How much training is needed for a hero of [heroClass] to reach [level],
  /// or `null` if the hero cannot train this skill.
  int trainingNeeded(HeroClass heroClass, int level) {
    var profiency = heroClass.proficiency(this);
    if (profiency == 0.0) return null;

    return (baseTrainingNeeded(level) / profiency).ceil();
  }

  /// How much training is needed for to reach [level], ignoring class
  /// proficiency.
  int baseTrainingNeeded(int level);
}

/// Spells are the primary skill for mages.
// TODO: More docs.
abstract class Spell extends Skill {
  /// The amount of [Intellect] the hero must possess to use this spell
  /// effectively.
  int get complexity;

  int get focusCost;

  Skill get _school {
    // It should be a direct or indirect prerequisite of this one.
    var skill = prerequisite;
    while (skill != null) {
      if (skill is SchoolSkill) return skill;
      skill = skill.prerequisite;
    }

    throw "Spell skill does not have a school as a prerequisite.";
  }

  int adjustedFocusCost(Hero hero) {
    return (focusCost * SchoolSkill.focusScale(hero.skills[_school])).toInt();
  }

  double effectiveness(Game game) =>
      game.hero.intellect.effectivenessScale(complexity);

  int failureChance(Game game) => game.hero.intellect.failureChance(complexity);

  Action getTargetAction(Game game, int level, Vec target) {
    var action = onGetTargetAction(game, level, target);
    return new FocusAction(adjustedFocusCost(game.hero), action);
  }

  Action onGetTargetAction(Game game, int level, Vec target) => null;

  Action getAction(Game game, int level) {
    var action = onGetAction(game, level);
    return new FocusAction(adjustedFocusCost(game.hero), action);
  }

  Action onGetAction(Game game, int level) => null;
}

// TODO: Redo this now that all skills aren't treated the same.
/// Base class for spell school skills.
abstract class SchoolSkill extends Skill {
  // TODO: Tune.
  static double focusScale(int level) {
    if (level == 0) return 1.0;
    return lerpDouble(level, 1, 20, 1.0, 0.2);
  }

  // TODO: Tune.
  int get maxLevel => 20;

  @override
  String levelDescription(int level) {
    var percent = ((1.0 - focusScale(level)) * 100).toInt();
    return "Reduce the focus cost of $name spells by $percent%.";
  }
}

/// A collection of [Skill]s and the hero's level in them.
class SkillSet {
  final Map<Skill, int> _levels;

  SkillSet() : this._({});

  SkillSet._(this._levels);

  int operator [](Skill skill) => _levels[skill] ?? 0;

  void operator []=(Skill skill, int value) {
    if (value == 0) {
      _levels.remove(skill);
    } else {
      _levels[skill] = value;
    }
  }

  /// All the skills the hero has at least one level in.
  Iterable<Skill> get all => _levels.keys;

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

  /// Whether the hero is aware of the existence of this skill.
  // TODO: Set this.
  bool isDiscovered(Skill skill) => true;

  SkillSet clone() => new SkillSet._(new Map.from(_levels));

  void update(SkillSet other) {
    _levels.clear();
    _levels.addAll(other._levels);
  }

  void forEach(void Function(Skill, int) callback) {
    _levels.forEach(callback);
  }
}

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
double lerpDouble(num value, num min, num max, double outMin, double outMax) {
  assert(min < max);

  if (value <= min) return outMin;
  if (value >= max) return outMax;

  var t = (value - min) / (max - min);
  return outMin + t * (outMax - outMin);
}

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
int lerpInt(int value, int min, int max, int outMin, int outMax) =>
    lerpDouble(value, min, max, outMin.toDouble(), outMax.toDouble()).round();
