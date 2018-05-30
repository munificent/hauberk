import 'dart:math' as math;

import '../hero/hero.dart';
import 'skill.dart';

class Stat {
  static const strength = const Stat("Strength");
  static const agility = const Stat("Agility");
  static const fortitude = const Stat("Fortitude");
  static const intellect = const Stat("Intellect");
  static const will = const Stat("Will");

  static const all = const [strength, agility, fortitude, intellect, will];

  final String name;

  const Stat(this.name);
}

abstract class StatBase {
  final Hero _hero;

  StatBase(this._hero);

  String get name => _stat.name;

  Stat get _stat;
  int get _penalty => 0;

  int get value =>
      (_hero.race.valueAtLevel(_stat, _hero.level) - _penalty).clamp(1, 60);
}

class Strength extends StatBase {
  Strength(Hero hero) : super(hero);

  Stat get _stat => Stat.strength;
  int get _penalty => _hero.weight;

  double get tossRangeScale {
    if (value <= 20) return lerpDouble(value, 1, 20, 0.1, 1.0);
    if (value <= 30) return lerpDouble(value, 20, 30, 1.0, 1.5);
    if (value <= 40) return lerpDouble(value, 30, 40, 1.5, 1.8);
    if (value <= 50) return lerpDouble(value, 40, 50, 1.8, 2.0);
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
}

class Agility extends StatBase {
  Agility(Hero hero) : super(hero);

  Stat get _stat => Stat.agility;

  // TODO: Subtract encumbrance.
  int get value =>
      _hero.race.valueAtLevel(Stat.agility, _hero.level).clamp(1, 60);

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
}

// TODO: "Vitality"?
class Fortitude extends StatBase {
  Fortitude(Hero hero) : super(hero);

  Stat get _stat => Stat.fortitude;

  int get maxHealth => (math.pow(value, 1.4) - 0.5 * value + 30).toInt();
}

class Intellect extends StatBase {
  Intellect(Hero hero) : super(hero);

  Stat get _stat => Stat.intellect;

  int get maxFocus => (math.pow(value, 1.3) * 2).ceil();
}

class Will extends StatBase {
  Will(Hero hero) : super(hero);

  Stat get _stat => Stat.will;
}
