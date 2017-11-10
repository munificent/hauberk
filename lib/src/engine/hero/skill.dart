import 'dart:math' as math;

import '../attack.dart';
import '../command/archery.dart';
import 'command.dart';

// TODO: Should all skills be in engine or content?

/// An immutable unique skill a hero may learn.
///
/// This class does not contain how good a hero is at the skill. It is more the
/// *kind* of skill.
abstract class Skill {
  static final strength = new Strength();
  static final agility = new Agility();
  static final fortitude = new Fortitude();
  static final intellect = new Intellect();
  static final will = new Will();

  static final List<Skill> all = [
    strength,
    agility,
    fortitude,
    intellect,
    will,
    new Archery()
  ];

  static final Map<String, Skill> _byName =
      new Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    assert(_byName.containsKey(name));
    return _byName[name];
  }

  String get name;

  // TODO: Can we give all skills the same max level?
  int get maxLevel;

  Skill get prerequisite => null;

  /// The [Command] this skill provides, or null if it is stricly passive.
  Command get command => null;

  /// Gives the skill a chance to modify the hit the hero is about to perform.
  void modifyAttack(Hit hit) {}

  /// Gives the skill a chance to modify the hit the hero is about to receive.
  void modifyDefense(Hit hit) {}

  // TODO: Requirements.
  // - Prerequisite skill(s).
  // - Minimum stat.
  // - Must be discovered by finding certain items. (I.e. a spellbook or
  //   weapon of a certain type.)
}

abstract class AttributeSkill extends Skill {
  int get maxLevel => 40;
}

// TODO: Get rid of Attribute classes and rename.
class Strength extends AttributeSkill {
  static double tossRangeScale(int value) {
    if (value <= 20) return _lerpDouble(value, 1, 20, 0.1, 1.0);
    if (value <= 30) return _lerpDouble(value, 20, 30, 1.0, 1.5);
    if (value <= 40) return _lerpDouble(value, 30, 40, 1.5, 1.8);
    if (value <= 30) return _lerpDouble(value, 40, 50, 1.8, 2.0);
    return _lerpDouble(value, 50, 60, 2.0, 2.1);
  }

  /// Calculates the melee damage scaling factor based on the hero's strength
  /// relative to the weapon's heft.
  ///
  /// Here, [value] is the hero's strength *minus* the weapon's heft, so
  /// may be a negative number.
  static double scaleHeft(int value) {
    value = value.clamp(-20, 50);

    if (value < -10) return _lerpDouble(value, -20, -10, 0.05, 0.3);

    // Note that there is an immediate step down to 0.8 at -1.
    if (value < 0) return _lerpDouble(value, -10, -1, 0.3, 0.8);

    if (value < 20) return _lerpDouble(value, 0, 20, 1.0, 2.0);
    return _lerpDouble(value, 20, 50, 2.0, 3.0);
  }

  String get name => "Strength";
}

class Agility extends AttributeSkill {
  static int dodgeBonus(int value) {
    if (value <= 10) return _lerpInt(value, 1, 10, -50, 0);
    if (value <= 30) return _lerpInt(value, 10, 30, 0, 30);
    return _lerpInt(value, 30, 60, 30, 60);
  }

  static int strikeBonus(int value) {
    if (value <= 10) return _lerpInt(value, 1, 10, -30, 0);
    if (value <= 30) return _lerpInt(value, 10, 30, 0, 20);
    return _lerpInt(value, 30, 60, 20, 50);
  }

  String get name => "Agility";
}

class Fortitude extends AttributeSkill {
  static int maxHealth(int value) =>
      (math.pow(value, 1.5) - 0.5 * value + 30).toInt();

  String get name => "Fortitude";
}

class Intellect extends AttributeSkill {
  String get name => "Intellect";
}

class Will extends AttributeSkill {
  String get name => "Will";
}

class Archery extends Skill {
  // TODO: Tune.
  int get maxLevel => 20;

  String get name => "Archery";

  Skill get prerequisite => Skill.strength;

  Command get command => new ArcheryCommand();
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

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
double _lerpDouble(int value, int min, int max, double outMin, double outMax) {
  assert(value >= min);
  assert(value <= max);
  assert(min < max);

  var t = (value - min) / (max - min);
  return outMin + t * (outMax - outMin);
}

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
int _lerpInt(int value, int min, int max, int outMin, int outMax) =>
    _lerpDouble(value, min, max, outMin.toDouble(), outMax.toDouble()).round();
