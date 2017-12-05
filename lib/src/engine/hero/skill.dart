import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/combat.dart';
import '../core/game.dart';
import 'hero.dart';

/// An immutable unique skill a hero may learn.
///
/// This class does not contain how good a hero is at the skill. It is more the
/// *kind* of skill.
abstract class Skill {
  static final might = new Might();
  static final flexibility = new Flexibility();
  static final toughness = new Toughness();
  static final education = new Education();
  static final discipline = new Discipline();

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
/// Some commands require additional data to be performed -- a target position
/// or a direction. Those will implement one of the subclasses, [TargetSkill]
/// or [DirectionSkill].
abstract class CommandSkill extends Skill {
  /// Override this to validate that the [Command] can be used right now. For
  /// example, this is only `true` for the archery skill when the hero has a
  /// ranged weapon equipped.
  bool canUse(Game game);

  // TODO: Add getAction() here when there are commands that don't require a
  // target or direction.
}

/// A skill that requires a target position to perform.
abstract class TargetSkill extends CommandSkill {
  /// The maximum range of the target from the hero.
  num getRange(Game game);

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Command].
  Action getTargetAction(Game game, Vec target);
}

/// A skill that requires a direction to perform.
abstract class DirectionSkill extends CommandSkill {
  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Command].
  Action getDirectionAction(Game game, Direction dir);
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
    if (!isKnown(skill)) return false;
    if (this[skill] >= skill.maxLevel) return false;

    // Must have some level of the prerequisite.
    if (skill.prerequisite != null && this[skill.prerequisite] == 0) {
      return false;
    }

    return true;
  }

  /// Whether the hero is aware of the existence of this skill.
  // TODO: Set this.
  bool isKnown(Skill skill) => true;

  SkillSet clone() => new SkillSet._(new Map.from(_levels));

  void update(SkillSet other) {
    _levels.clear();
    _levels.addAll(other._levels);
  }

  void forEach(void Function(Skill, int) callback) {
    _levels.forEach(callback);
  }
}

/// In order to increase the hero's base attributes, there is a skill for each
/// one.
abstract class AttributeSkill extends Skill {
  int get maxLevel => 40;

  String get attribute;
  String get description => "Increases $attribute.";

  String levelDescription(int level) => "Increases $attribute by $level.";
}

class Might extends AttributeSkill {
  String get name => "Might";
  String get attribute => "strength";
}

class Flexibility extends AttributeSkill {
  String get name => "Flexibility";
  String get attribute => "agility";
}

class Toughness extends AttributeSkill {
  String get name => "Toughness";
  String get attribute => "fortitude";
}

class Education extends AttributeSkill {
  Education();

  String get name => "Education";
  String get attribute => "intellect";
}

class Discipline extends AttributeSkill {
  String get name => "Discipline";
  String get attribute => "will";
}

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
double lerpDouble(int value, int min, int max, double outMin, double outMax) {
  assert(value >= min);
  assert(value <= max);
  assert(min < max);

  var t = (value - min) / (max - min);
  return outMin + t * (outMax - outMin);
}

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
int lerpInt(int value, int min, int max, int outMin, int outMax) =>
    lerpDouble(value, min, max, outMin.toDouble(), outMax.toDouble()).round();
