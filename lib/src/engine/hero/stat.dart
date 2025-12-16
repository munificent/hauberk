import 'dart:math' as math;

import '../core/math.dart';
import '../hero/hero_save.dart';

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
  T? _value;

  /// The current value.
  T get value => _value!;

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

enum Stat {
  strength("Strength"),
  agility("Agility"),
  vitality("Vitality"),
  intellect("Intellect");

  /// How much experience it takes to raise a stat by a single point given that
  /// the hero's total number of base stat points for all stats is [statTotal]
  /// and the race affects the stat with [raceScale].
  static int experienceCostAt(int statTotal, double raceScale) {
    // When a race is better at a stat, the cost goes down.
    var baseCost = (400 * (1.0 / raceScale));

    // As the hero's total stats increase, it gets harder and harder to raise
    // more stats. Also, as their stats get higher, they are also generally
    // stronger and are killing monsters which yield more experience, so we
    // curve the cost upwards significantly.
    var totalScale = lerpDouble(
      statTotal,
      10 * Stat.values.length,
      Stat.baseMax * Stat.values.length,
      1.0,
      25.0,
    );
    var totalCurve = math.pow(totalScale, 3.0);

    return (baseCost * totalCurve).toInt();
  }

  /// The maximum base value a stat can have before any modifiers are applied.
  static const baseMax = 40;

  /// The maximum value a stat can have after modifiers are applied.
  static const modifiedMax = 50;

  final String name;

  String get abbreviation => name.substring(0, 3);

  const Stat(this.name);
}

abstract class StatBase extends Property<int> {
  String get name => stat.name;

  Stat get stat;

  String get _gainAdjective;

  String get _loseAdjective;

  int _statOffset(HeroSave hero) => 0;

  /// The value of the stat before any modifiers are applied.
  int get baseValue => _baseValue;
  int _baseValue = 0;

  void initialize(HeroSave hero, int value) {
    _baseValue = value;
    _value = _calculateValue(hero);
  }

  void refresh(HeroSave hero, [int? newBaseValue]) {
    if (newBaseValue != null) _baseValue = newBaseValue;
    var newValue = _calculateValue(hero);

    update(newValue, (previous) {
      var gain = newValue - previous;
      if (gain > 0) {
        hero.log.gain(
          "You feel $_gainAdjective! Your $name increased by $gain.",
        );
      } else {
        hero.log.error(
          "You feel $_loseAdjective! Your $name decreased by ${-gain}.",
        );
      }
    });
  }

  // TODO: Passing in save is kind of weird.
  int experienceCost(HeroSave save) {
    var total =
        save.strength.baseValue +
        save.agility.baseValue +
        save.vitality.baseValue +
        save.intellect.baseValue;
    return Stat.experienceCostAt(total, save.race.statScale(stat));
  }

  int _calculateValue(HeroSave hero) =>
      (_baseValue + _statOffset(hero) + hero.statBonus(stat)).clamp(
        1,
        Stat.modifiedMax,
      );

  @override
  String toString() => name;
}

class Strength extends StatBase {
  static int maxFuryAt(int strength) {
    if (strength < 10) return 0;
    return (strength - 8) ~/ 2;
  }

  static double tossRangeScaleAt(int strength) {
    if (strength <= 20) return lerpDouble(strength, 1, 20, 0.1, 1.0);
    if (strength <= 30) return lerpDouble(strength, 20, 30, 1.0, 1.5);
    if (strength <= 40) return lerpDouble(strength, 30, 40, 1.5, 1.8);
    if (strength <= 50) return lerpDouble(strength, 40, 50, 1.8, 2.0);
    return lerpDouble(strength, 50, 60, 2.0, 2.1);
  }

  @override
  Stat get stat => Stat.strength;

  @override
  String get _gainAdjective => "mighty";

  @override
  String get _loseAdjective => "weak";

  @override
  int _statOffset(HeroSave hero) => weightOffset(hero);

  /// How much the hero's weight affects strength.
  int weightOffset(HeroSave hero) => -hero.weight;

  /// The highest fury level the hero can reach.
  int get maxFury => maxFuryAt(value);

  double get tossRangeScale => tossRangeScaleAt(value);

  /// The damage multiplier for a given [fury].
  ///
  /// Each point of fury adds another `0.1` to the multiplier.
  double furyScale(int fury) => 1.0 + fury * 0.1;

  /// Calculates the melee damage scaling factor based on the hero's strength
  /// relative to the weapon's [heft].
  double heftScale(int heft) {
    var relative = (value - heft).clamp(-10, 50);

    if (relative < 0) {
      // Note there is an immediate step down to 0.6 at -1.
      return lerpDouble(relative, -10, -1, 0.0, 0.6);
    } else {
      return lerpDouble(relative, 0, 50, 1.0, 2.0);
    }
  }
}

class Agility extends StatBase {
  static int dodgeBonusAt(int value) {
    if (value <= 10) return lerpInt(value, 1, 10, -50, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 20);
    return lerpInt(value, 30, 60, 20, 60);
  }

  static int strikeBonusAt(int value) {
    if (value <= 10) return lerpInt(value, 1, 10, -30, 0);
    if (value <= 30) return lerpInt(value, 10, 30, 0, 20);
    return lerpInt(value, 30, 60, 20, 50);
  }

  @override
  Stat get stat => Stat.agility;

  @override
  String get _gainAdjective => "dextrous";

  @override
  String get _loseAdjective => "clumsy";

  // TODO: Subtract encumbrance.

  int get dodgeBonus => dodgeBonusAt(value);

  int get strikeBonus => strikeBonusAt(value);
}

class Vitality extends StatBase {
  /// A somewhat gentle curve from 10 to 400.
  static int maxHealthAt(int value) => (math.pow(value, 1.458) + 9).toInt();

  @override
  Stat get stat => Stat.vitality;

  @override
  String get _gainAdjective => "tough";

  @override
  String get _loseAdjective => "sickly";

  int get maxHealth => maxHealthAt(value);
}

class Intellect extends StatBase {
  static int maxFocusAt(int value) {
    if (value <= 10) return lerpInt(value, 1, 10, 0, 20);
    return lerpInt(value, 10, 50, 20, 200);
  }

  static int spellCountAt(int value) {
    return lerpInt(value, 10, 40, 0, 15);
  }

  @override
  Stat get stat => Stat.intellect;

  @override
  String get _gainAdjective => "smart";

  @override
  String get _loseAdjective => "stupid";

  int get maxFocus => maxFocusAt(value);

  int get spellCount => spellCountAt(value);

  double spellFocusScale(int complexity) {
    var relative = value - complexity.clamp(0, 50);
    return lerpDouble(relative, 0, 50, 1.0, 0.2);
  }
}
