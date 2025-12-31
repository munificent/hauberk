import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../debug.dart';
import '../action/action.dart';
import '../hero/hero.dart';
import 'actor.dart';
import 'element.dart';
import 'game.dart';
import 'log.dart';

/// Armor reduces damage by an inverse curve such that increasing armor has
/// less and less effect. Damage is reduced to the following:
///
///     armor damage
///     ------------
///     0     100%
///     40    50%
///     80    33%
///     120   25%
///     160   20%
///     ...   etc.
num getArmorMultiplier(int armor) {
  // Damage is never increased.
  return 1.0 / (1.0 + math.max(0, armor) / 40.0);
}

class Attack {
  /// The thing performing the attack. If `null`, then the attacker will be
  /// used.
  final Noun? noun;

  /// A verb string describing the attack: "hits", "fries", etc.
  final String verb;

  final int damage;

  // TODO: Some kind of minimum range would be good to prevent players from
  // using bows at close range and to make bows a little less powerful. However,
  // doing that requires figuring out what happens if a monster is within the
  // minimum range and the hero fires *past* it.
  final int range;

  final Element element;

  Attack(this.noun, this.verb, this.damage, [int? range, Element? element])
    : range = range ?? 0,
      element = element ?? Element.none;

  bool get isRanged => range > 0;

  Hit createHit() => Hit._(this);

  @override
  String toString() {
    var result = damage.toString();
    if (element != Element.none) result = "$element $result";
    if (range > 0) result += "@$range";
    return result;
  }
}

enum HitType { melee, ranged, toss }

final class Bonus {
  final int amount;
  final String reason;

  Bonus(this.amount, this.reason);
}

final class Scale {
  final double amount;
  final String reason;

  Scale(this.amount, this.reason);
}

class Hit {
  final Attack _attack;

  final List<Scale> _strikeScales = [];
  final List<Bonus> _strikeBonuses = [];

  final List<Scale> _damageScales = [];
  final List<Bonus> _damageBonuses = [];

  Element _brand = Element.none;

  int get range {
    if (_attack.range == 0) return 0;
    return math.max(1, (_attack.range * _rangeScale).round());
  }

  double _rangeScale = 1.0;

  double get _strikeScale {
    return _strikeScales.fold(1.0, (total, scale) => total * scale.amount);
  }

  double get _strikeBonus {
    return _strikeBonuses.fold(1, (total, bonus) => total + bonus.amount);
  }

  double get _damageScale {
    return _damageScales.fold(1.0, (total, scale) => total * scale.amount);
  }

  double get _damageBonus {
    return _damageBonuses.fold(1, (total, bonus) => total + bonus.amount);
  }

  Element get element {
    if (_brand != Element.none) return _brand;
    return _attack.element;
  }

  double get averageDamage => _attack.damage * _damageScale + _damageBonus;

  // TODO: This is just used for the game screen weapon display. Show the
  // bonuses and stuff more explicitly there and get rid of this.
  /// The average amount of damage this hit causes, with two decimal points of
  /// precision.
  String get damageString {
    return ((averageDamage * 100).toInt() / 100).toString();
  }

  Hit._(this._attack);

  void addStrike(int bonus, String reason) {
    if (bonus == 0) return;
    _strikeBonuses.add(Bonus(bonus, reason));
  }

  void scaleStrike(double factor, String reason) {
    if (factor == 1.0) return;
    _strikeScales.add(Scale(factor, reason));
  }

  void addDamage(int offset, String reason) {
    if (offset == 0) return;
    _damageBonuses.add(Bonus(offset, reason));
  }

  void scaleDamage(double factor, String reason) {
    if (factor == 1.0) return;
    _damageScales.add(Scale(factor, reason));
  }

  void brand(Element element) {
    // TODO: What if it's already branded? How do they compose?
    if (element != Element.none) _brand = element;
  }

  void scaleRange(double factor) {
    _rangeScale *= factor;
  }

  /// Performs a melee [Hit] from [attacker] to [defender] in the course of
  /// [action].
  ///
  /// Returns the amount of damage done if the attack connected or `null` if
  /// it missed.
  int perform(Action action, Actor? attacker, Actor defender, {bool? canMiss}) {
    canMiss ??= true;

    // Even if the hero can't fully see what's happening, it's important to give
    // them some information if the attack affects them. Generate a message
    // based on what they can see about the hit.
    var canSeeAttacker = false;
    if (attacker is Hero) {
      // The hero sees what they themselves do.
      canSeeAttacker = true;
    } else if (attacker != null &&
        action.game.stage.isVisibleToHero(attacker)) {
      // The hero sees what visible monsters do.
      canSeeAttacker = true;
    } else if (defender is Hero && _attack.noun != null) {
      // The hero sees if a thing hits them (even if they don't see where it
      // came from).
      canSeeAttacker = true;
    } else if (action.game.stage.isVisibleToHero(defender) &&
        _attack.noun != null) {
      // The hero see if a thing hits a visible monster (even if they don't see
      // where it came from).
      canSeeAttacker = true;
    }

    var canSeeDefender = false;
    if (defender is Hero) {
      // The hero sees themselves.
      canSeeDefender = true;
    } else if (action.game.stage.isVisibleToHero(defender)) {
      // The hero sees what hits visible monsters.
      canSeeDefender = true;
    }

    // If the attack itself doesn't have a noun ("the arrow hits"), use the
    // attacker ("the wolf bites").
    var attackNoun = canSeeAttacker
        ? (_attack.noun ?? attacker)!
        : Noun('something');
    var defenderNoun = canSeeDefender ? defender : Noun('something');

    if (defender is Hero) {
      defender.receiveAttack(this);
    }

    // See if any defense blocks the attack.
    // TODO: Instead of a single "canMiss" flag, consider having each defense
    // define the set of elements it can block and then apply them based on
    // that.
    if (canMiss) {
      var strikeRoll = rng.inclusive(1, 100);
      var strike = strikeRoll * _strikeScale + _strikeBonus;
      var defenses = defender.defenses.toList();

      if (Debug.logCombat) {
        var strikeMods = [
          for (var scale in _strikeScales)
            'x ${scale.amount.toStringAsFixed(2)} (${scale.reason})',
          for (var bonus in _strikeBonuses)
            '+ ${bonus.amount} (${bonus.reason})',
        ].join(' ');
        action.game.log.debug('strike: $strikeRoll $strikeMods');

        var defenseString = [
          for (var defense in defenses)
            '${defense.amount} (${defense.message})',
        ].join(' ');
        action.game.log.debug('defense: $defenseString');
      }

      // Shuffle defenses so the message shown isn't biased by their order (just
      // their relative amounts).
      rng.shuffle(defenses);
      for (var defense in defenses) {
        strike -= defense.amount;
        if (strike < 0) {
          if (canSeeAttacker || canSeeDefender) {
            action.log(defense.message, defenderNoun, attackNoun);
          }
          return 0;
        }
      }
    }

    // Roll for damage.
    var armor = defender.armor;
    var resistance = defender.resistance(element);
    var damage = _rollDamage(action.game.log, armor, resistance);

    if (damage == 0) {
      // Armor cancelled out all damage.
      // TODO: Should still affect monster alertness.
      if (canSeeAttacker || canSeeDefender) {
        action.log('{1} do[es] no damage to {2}.', attackNoun, defenderNoun);
      }
      return 0;
    }

    if (attacker != null) {
      attacker.onGiveDamage(action, defender, damage);
    }

    if (defender.takeDamage(action, damage, attackNoun, attacker)) {
      return damage;
    }

    // Any resistance cancels all side effects.
    if (resistance <= 0) {
      var sideEffect = element.attackAction(damage);
      if (sideEffect != null) {
        action.addAction(sideEffect, defender);
      }

      // TODO: Should we log a message to let the player know the side effect
      // was resisted?
    }

    action.addEvent(
      EventType.hit,
      actor: defender,
      element: element,
      other: damage,
    );
    if (canSeeAttacker || canSeeDefender) {
      action.log('{1} ${_attack.verb} {2}.', attackNoun, defenderNoun);
    }
    return damage;
  }

  int _rollDamage(Log log, int armor, int resistance) {
    var resistScale = 1.0 / (1.0 + resistance);

    // Calculate in cents so that we don't do as much rounding until after
    // armor is taken into account.
    var damage = (_attack.damage * _damageScale + _damageBonus) * resistScale;
    var damageCents = (damage * 100).toInt();

    var armorScale = getArmorMultiplier(armor);
    var rolled =
        rng.triangleInt(damageCents, damageCents ~/ 2).toDouble() * armorScale;

    if (Debug.logCombat) {
      var damageString = [
        '(',
        _attack.damage,
        for (var scale in _damageScales)
          'x ${scale.amount.toStringAsFixed(2)} (${scale.reason})',
        for (var bonus in _damageBonuses) '+ ${bonus.amount} (${bonus.reason})',
        ')',
        if (resistScale != 1.0) 'x ${resistScale.toStringAsFixed(2)} (resist)',
        if (armorScale != 1.0) 'x ${armorScale.toStringAsFixed(2)} (armor)',
      ].join(' ');

      log.debug('damage: $damageString');
    }

    return (rolled / 100).round();
  }
}

/// TODO: Flags for which kinds of attacks (melee, ranged, magic) the dodge
/// can apply to?
class Defense {
  final int amount;
  final String message;

  Defense(this.amount, this.message);
}
