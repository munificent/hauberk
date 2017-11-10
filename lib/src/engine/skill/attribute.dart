import 'dart:math' as math;

import 'skill.dart';

/// In order to increase the hero's base attributes, there is a skill for each
/// one.
abstract class AttributeSkill extends Skill {
  int get maxLevel => 40;
}

class Strength extends AttributeSkill {
  static double tossRangeScale(int value) {
    if (value <= 20) return lerpDouble(value, 1, 20, 0.1, 1.0);
    if (value <= 30) return lerpDouble(value, 20, 30, 1.0, 1.5);
    if (value <= 40) return lerpDouble(value, 30, 40, 1.5, 1.8);
    if (value <= 30) return lerpDouble(value, 40, 50, 1.8, 2.0);
    return lerpDouble(value, 50, 60, 2.0, 2.1);
  }

  /// Calculates the melee damage scaling factor based on the hero's strength
  /// relative to the weapon's heft.
  ///
  /// Here, [value] is the hero's strength *minus* the weapon's heft, so
  /// may be a negative number.
  static double scaleHeft(int value) {
    value = value.clamp(-20, 50);

    if (value < -10) return lerpDouble(value, -20, -10, 0.05, 0.3);

    // Note that there is an immediate step down to 0.8 at -1.
    if (value < 0) return lerpDouble(value, -10, -1, 0.3, 0.8);

    if (value < 20) return lerpDouble(value, 0, 20, 1.0, 2.0);
    return lerpDouble(value, 20, 50, 2.0, 3.0);
  }

  String get name => "Strength";
}

class Agility extends AttributeSkill {
  static int dodgeBonus(int value) {
    if (value <= 10) return lerpInt(value, 1, 10, -50, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 30);
    return lerpInt(value, 30, 60, 30, 60);
  }

  static int strikeBonus(int value) {
    if (value <= 10) return lerpInt(value, 1, 10, -30, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 20);
    return lerpInt(value, 30, 60, 20, 50);
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
