import 'dart:math' as math;

import '../hero/hero.dart';
import 'skill.dart';

class Strength {
  final Hero _hero;

  int get value => (10 + _hero.skills[Skill.might] - _hero.weight).clamp(1, 60);

  double get tossRangeScale {
    if (value <= 20) return lerpDouble(value, 1, 20, 0.1, 1.0);
    if (value <= 30) return lerpDouble(value, 20, 30, 1.0, 1.5);
    if (value <= 40) return lerpDouble(value, 30, 40, 1.5, 1.8);
    if (value <= 30) return lerpDouble(value, 40, 50, 1.8, 2.0);
    return lerpDouble(value, 50, 60, 2.0, 2.1);
  }

  /// Calculates the melee damage scaling factor based on the hero's strength
  /// relative to the weapon's [heft].
  double heftScale(int heft) {
    var relative = (value - heft).clamp(-20, 50);

    if (relative < -10) return lerpDouble(relative, -20, -10, 0.05, 0.3);

    // Note that there is an immediate step down to 0.8 at -1.
    if (relative < 0) return lerpDouble(relative, -10, -1, 0.3, 0.8);

    if (relative < 30) return lerpDouble(relative, 0, 30, 1.0, 2.0);
    return lerpDouble(relative, 30, 50, 2.0, 3.0);
  }

  Strength(this._hero);
}

class Agility {
  final Hero _hero;

  // TODO: Subtract encumbrance.
  int get value => (10 + _hero.skills[Skill.flexibility]).clamp(1, 60);

  int get dodgeBonus {
    if (value <= 10) return lerpInt(value, 1, 10, -50, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 30);
    return lerpInt(value, 30, 60, 30, 60);
  }

  int get strikeBonus {
    if (value <= 10) return lerpInt(value, 1, 10, -30, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 20);
    return lerpInt(value, 30, 60, 20, 50);
  }

  Agility(this._hero);
}

class Fortitude {
  final Hero _hero;

  int get value => (10 + _hero.skills[Skill.toughness]).clamp(1, 60);

  int get maxHealth =>
      (math.pow(value, 1.4) - 0.5 * value + 30).toInt();

  Fortitude(this._hero);
}

class Intellect {
  final Hero _hero;

  int get value => (10 + _hero.skills[Skill.learning]).clamp(1, 60);

  Intellect(this._hero);
}

class Will {
  final Hero _hero;

  int get value => (10 + _hero.skills[Skill.discipline]).clamp(1, 60);

  Will(this._hero);
}