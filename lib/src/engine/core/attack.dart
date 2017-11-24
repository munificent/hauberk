import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/condition.dart';
import '../action/element.dart';
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
  final Noun noun;

  /// A verb string describing the attack: "hits", "fries", etc.
  final String verb;

  final int damage;

  final int range;

  final Element element;

  Attack(this.noun, this.verb, this.damage, [int range, Element element])
      : range = range ?? 0,
        element = element ?? Element.none;

  bool get isRanged => range > 0;

  Hit createHit() => new Hit._(this);

  String toString() {
    var result = damage.toString();
    if (element != Element.none) result = "$element $result";
    if (range > 0) result += "@$range";
    return result;
  }
}

enum HitType { melee, ranged, toss }

class Hit {
  final Attack _attack;

  int _dodgeBonus = 0;
  double _damageScale = 1.0;
  int _damageBonus = 0;
  Element _brand = Element.none;

  int get range {
    if (_attack.range == 0) return 0;

    return math.max(1, (_attack.range * _rangeScale).round());
  }

  double _rangeScale = 1.0;

  Element get element {
    if (_brand != Element.none) return _brand;
    return _attack.element;
  }

  // TODO: This is just used for the game screen weapon display. Show the
  // bonuses and stuff more explicitly there and get rid of this.
  /// The average amount of damage this hit causes, with two decimal points of
  /// precision.
  String get damageString {
    var damage = _attack.damage * _damageScale + _damageBonus;
    return ((damage * 100).toInt() / 100).toString();
  }

  Hit._(this._attack);

  void addDodge(int bonus) {
    _dodgeBonus += bonus;
  }

  void addStrike(int bonus) {
    _dodgeBonus -= bonus;
  }

  void addDamage(int offset) {
    _damageBonus += offset;
  }

  void brand(Element element) {
    // TODO: What if it's already branded? How do they compose?
    if (element != Element.none) _brand = element;
  }

  void scaleDamage(double factor) {
    _damageScale *= factor;
  }

  void scaleRange(double factor) {
    _rangeScale *= factor;
  }

  /// Performs a melee [Hit] from [attacker] to [defender] in the course of
  /// [action].
  ///
  /// Returns `true` if the attack connected.
  bool perform(Action action, Actor attacker, Actor defender, {bool canMiss}) {
    canMiss = canMiss ?? true;

    // If the attack itself doesn't have a noun ("the arrow hits"), use the
    // attacker ("the wolf bites").
    var attackNoun = _attack.noun ?? attacker;

    // See if the attack hits.
    if (canMiss) {
      var dodge = defender.dodge + _dodgeBonus;
      var strike = rng.inclusive(1, 100);

      if (strike < dodge) {
        action.log('{1} miss[es] {2}.', attackNoun, defender);
        return false;
      }
    }

    // Roll for damage.
    var armor = defender.armor;
    var resistance = defender.resistance(element);
    var damage = _rollDamage(armor, resistance);

    if (damage == 0) {
      // Armor cancelled out all damage.
      action.log('{1} do[es] no damage to {2}.', attackNoun, defender);
      return true;
    }

    attacker.onDamage(action, defender, damage);
    if (defender.takeDamage(action, damage, attackNoun, attacker)) return true;

    // Any resistance cancels all side effects.
    if (resistance <= 0) {
      _elementSideEffect(defender, action, damage);
      // TODO: Should we log a message to let the player know the side effect
      // was resisted?
    }

    // TODO: Pass in and use element.
    action.addEvent(EventType.hit, actor: defender, other: damage);
    action.log('{1} ${_attack.verb} {2}.', attackNoun, defender);
    return true;
  }

  int _rollDamage(int armor, int resistance) {
    var resistScale = 1.0 / (1.0 + resistance);

    // Calculate in cents so that we don't do as much rounding until after
    // armor is taken into account.
    var damage = (_attack.damage * _damageScale + _damageBonus) * resistScale;
    var damageCents = (damage * 100).toInt();

    var rolled = rng.triangleInt(damageCents, damageCents ~/ 2);
    rolled *= getArmorMultiplier(armor);
    return (rolled / 100).round();
  }

  void _elementSideEffect(Actor defender, Action action, int damage) {
    // Apply any element-specific effects.
    switch (element) {
      case Element.none:
        // No effect.
        break;

      case Element.air:
        // TODO: Should damage affect distance?
        action.addAction(new WindAction(), defender);
        break;

      case Element.earth:
        // TODO: Cuts?
        break;

      case Element.fire:
        action.addAction(new BurnAction(), defender);
        break;

      case Element.water:
        // TODO: Push back.
        break;

      case Element.acid:
        // TODO: Destroy items.
        break;

      case Element.cold:
        action.addAction(new FreezeAction(damage), defender);
        break;

      case Element.lightning:
        // TODO: Break glass. Recharge some items?
        break;

      case Element.poison:
        action.addAction(new PoisonAction(damage), defender);
        break;

      case Element.dark:
        action.addAction(new BlindAction(damage), defender);
        break;

      case Element.light:
        action.addAction(new DazzleAction(damage), defender);
        break;

      case Element.spirit:
        // TODO: Drain experience.
        break;
    }
  }
}
