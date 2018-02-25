import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/combat.dart';
import '../core/game.dart';
import '../monster/monster.dart';
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

  /// Message displayed when the hero first discovers this skill.
  String get discoverMessage;

  int get maxLevel;

  // TODO: Remove?
  Skill get prerequisite => null;

  /// Whether this skill has been acquired if it is at [level].
  ///
  /// Each kind of skill has different rules for what it means to be acquired.
  /// Trained skills must be leveled past zero, spells merely need to be
  /// discovered and not too complex, etc.
  bool isAcquired(Hero hero, int level);

  /// Gives the skill a chance to modify the [hit] the [hero] is about to
  /// perform on [monster].
  void modifyAttack(Hero hero, Monster monster, Hit hit, int level) {}

  /// Gives the skill a chance to add new defenses to the hero.
  Defense getDefense(Hero hero, int level) => null;

  /// Gives the skill a chance to modify the hit the hero is about to receive.
  void modifyDefense(Hit hit) {}
}

/// Additional interface for active skills that expose a command the player
/// can invoke.
///
/// Some skills require additional data to be performed -- a target position
/// or a direction. Those will implement one of the subclasses, [TargetSkill]
/// or [DirectionSkill].
abstract class UsableSkill implements Skill {
  /// If the skill cannot currently be used (for example Archery when a bow is
  /// not equipped), returns the reason why. Otherwise, returns `null` to
  /// indicate the skill is usable.
  String unusableReason(Game game) => null;
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
  String get discoverMessage => "{1} can begin training in $name.";

  bool isAcquired(Hero hero, int level) => level > 0;

  String levelDescription(int level);

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
///
/// Spells do not need to be explicitly trained or learned. As soon as one is
/// discovered, as long as it's not too complex, the hero can use it.
abstract class Spell extends Skill implements UsableSkill {
  String get discoverMessage => '{1} can learn the spell "$name".';

  /// Spells are not leveled.
  int get maxLevel => 1;

  /// The amount of [Intellect] the hero must possess to use this spell
  /// effectively.
  int get complexity;

  int get focusCost;

  String expertiseDescription(Hero hero) =>
      onExpertiseDescription(expertise(hero));

  String onExpertiseDescription(int expertise);

  bool isAcquired(Hero hero, int level) => expertise(hero) >= 0;

  String unusableReason(Game game) => null;

  // TODO: Take bonuses into account.
  int expertise(Hero hero) => hero.intellect.value - complexity;

  Action getTargetAction(Game game, int level, Vec target) {
    var action = onGetTargetAction(game, level, target);
    return new FocusAction(focusCost, action);
  }

  Action onGetTargetAction(Game game, int level, Vec target) => null;

  Action getAction(Game game, int level) {
    var action = onGetAction(game, level);
    return new FocusAction(focusCost, action);
  }

  Action onGetAction(Game game, int level) => null;
}

/// A collection of [Skill]s and the hero's level in them.
class SkillSet {
  /// The levels the hero has gained in each skill.
  ///
  /// If a skill is at level zero here, it means the hero has discovered the
  /// skill, but not gained it. If not present in the map at all, the hero has
  /// not discovered it.
  final Map<Skill, int> _levels;

  SkillSet([Map<Skill, int> skills]) : _levels = skills ?? {};

  int operator [](Skill skill) => _levels[skill] ?? 0;

  /// All the skills the hero knows about.
  Iterable<Skill> get discovered => _levels.keys;

  /// All the skills the hero actually has.
  Iterable<Skill> acquired(Hero hero) =>
      _levels.keys.where((skill) => skill.isAcquired(hero, _levels[skill]));

  /// Learns that [skill] exists.
  ///
  /// Returns `true` if the hero wasn't already aware of this skill.
  bool discover(Skill skill) {
    if (_levels.containsKey(skill)) return false;

    _levels[skill] = 0;
    return true;
  }

  bool gain(Skill skill, int level) {
    if (_levels[skill] == level) return false;

    // Don't discover the skill if not already known.
    if (level == 0 && !_levels.containsKey(skill)) return false;

    _levels[skill] = level;
    return true;
  }

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
  bool isDiscovered(Skill skill) => _levels.containsKey(skill);

  SkillSet clone() => new SkillSet(new Map.from(_levels));

  void update(SkillSet other) {
    _levels.clear();
    _levels.addAll(other._levels);
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
