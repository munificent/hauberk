import 'dart:math' as math;

import '../hero/hero_save.dart';
import '../core/game.dart';
import '../core/math.dart';

/// A derived property of the hero that needs to log a message when it changes.
///
/// If some property of the hero cannot be recalcuted based on other state,
/// then it is stored directly in the hero: experience points, equipment, etc.
///
/// If a property is calculated based on other state but doesn't notify the
/// user when it changes, then it can just be a getter: weight, stomach, etc.
///
/// The remaining properties use this. It stores the previously-calculated
/// value so that we can tell when a recalculation has actually changed it.
class Property<T extends num> {
  T _value;

  /// The current modified value.
  T get value => _modify(_value);

  /// A subclass can override this to modify the observed value. The updating
  /// and notifications are based on the raw base value.
  T _modify(T base) => base;

  /// Stores the new base [value]. If [value] is different from the current
  /// base value, calls [onChange], passing in the previous value. Does not take
  /// any modification into account.
  void update(T value, Function(T) onChange) {
    if (_value == value) return;

    var previous = _value;
    _value = value;

    // Don't notify when first initialized.
    if (previous != null) onChange(previous);
  }
}

class Stat {
  static const max = 60;

  static const strength = Stat("Strength");
  static const agility = Stat("Agility");
  static const fortitude = Stat("Fortitude");
  static const intellect = Stat("Intellect");
  static const will = Stat("Will");

  static const all = [
    strength,
    agility,
    fortitude,
    intellect,
    will,
  ];

  final String name;

  const Stat(this.name);
}

abstract class StatBase extends Property<int> {
  HeroSave _hero;

  String get name => _stat.name;

  Stat get _stat;

  String get _gainAdjective;

  String get _loseAdjective;

  int _modify(int base) =>
      (base + _statOffset + _hero.statBonus(_stat)).clamp(1, Stat.max);

  int get _statOffset => 0;

  void bindHero(HeroSave hero) {
    assert(_hero == null);
    _hero = hero;
    _value = _hero.race.valueAtLevel(_stat, _hero.level).clamp(1, Stat.max);
  }

  void refresh(Game game) {
    var newValue =
        _hero.race.valueAtLevel(_stat, _hero.level).clamp(1, Stat.max);
    update(newValue, (previous) {
      var gain = newValue - previous;
      if (gain > 0) {
        game.log
            .gain("You feel $_gainAdjective! Your $name increased by $gain.");
      } else {
        game.log.error(
            "You feel $_loseAdjective! Your $name decreased by ${-gain}.");
      }
    });
  }
}

class Strength extends StatBase {
  Stat get _stat => Stat.strength;

  String get _gainAdjective => "mighty";

  String get _loseAdjective => "weak";

  int get _statOffset => -_hero.weight;

  double get tossRangeScale {
    if (value <= 20) return lerpDouble(value, 1, 20, 0.1, 1.0);
    if (value <= 30) return lerpDouble(value, 20, 30, 1.0, 1.5);
    if (value <= 40) return lerpDouble(value, 30, 40, 1.5, 1.8);
    if (value <= 50) return lerpDouble(value, 40, 50, 1.8, 2.0);
    return lerpDouble(value, 50, 60, 2.0, 2.1);
  }

  /// Calculates the melee damage scaling factor based on the hero's strength
  /// relative to the weapon's [heft] and the number of [weaponsWielded] (1
  /// or 2).
  double heftScale(int heft, int weaponsWielded) {
    // TODO: Use weaponsWielded.
    var relative = (value - heft).clamp(-20, 50);

    if (relative < -10) return lerpDouble(relative, -20, -10, 0.05, 0.3);

    // Note that there is an immediate step down to 0.8 at -1.
    if (relative < 0) return lerpDouble(relative, -10, -1, 0.3, 0.8);

    if (relative < 30) return lerpDouble(relative, 0, 30, 1.0, 2.0);
    return lerpDouble(relative, 30, 50, 2.0, 3.0);
  }
}

class Agility extends StatBase {
  Stat get _stat => Stat.agility;

  String get _gainAdjective => "dextrous";

  String get _loseAdjective => "clumsy";

  // TODO: Subtract encumbrance.

  int get dodgeBonus {
    if (value <= 10) return lerpInt(value, 1, 10, -50, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 20);
    return lerpInt(value, 30, 60, 20, 60);
  }

  int get strikeBonus {
    if (value <= 10) return lerpInt(value, 1, 10, -30, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 20);
    return lerpInt(value, 30, 60, 20, 50);
  }
}

// TODO: "Vitality"?
class Fortitude extends StatBase {
  Stat get _stat => Stat.fortitude;

  String get _gainAdjective => "tough";

  String get _loseAdjective => "sickly";

  int get maxHealth => (math.pow(value, 1.4) + 1.23 * value + 18).toInt();
}

class Intellect extends StatBase {
  Stat get _stat => Stat.intellect;

  String get _gainAdjective => "smart";

  String get _loseAdjective => "stupid";

  int get maxFocus => (math.pow(value, 1.3) * 2).ceil();
}

class Will extends StatBase {
  Stat get _stat => Stat.will;

  String get _gainAdjective => "invincible";

  String get _loseAdjective => "foolish";
}
