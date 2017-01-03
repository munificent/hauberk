import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'action/action.dart';
import 'action/condition.dart';
import 'action/element.dart';
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

  /// The bonus applied to the defender's base dodge ability. A higher bonus
  /// makes it more likely the attack will make contact.
  int get strikeBonus => _strikeBonus;
  int _strikeBonus = 0;

  /// The average damage. The actual damage will be a `Rng.triangleInt` centered
  /// on this with a range of 1/2 of its value.
  final int baseDamage;

  /// Additional damage added to [baseDamage] after the multiplier has been
  /// applied.
  int get damageBonus => _damageBonus;
  int _damageBonus = 0;

  /// The multiplier for [baseDamage].
  num get damageScale => _damageScale;
  num _damageScale = 1.0;

  /// The average damage inflicted by the attack.
  num get averageDamage => baseDamage * damageScale + damageBonus;

  /// The element for the attack.
  Element get element => _element;
  Element _element = Element.none;

  Attack(this.verb, this.baseDamage, [Element element, this.noun])
      : _element = element != null ? element : Element.none;

  /// Creates an [Attack] intended to be passed to [combine].
  Attack.modifier({Element element, int strikeBonus, int damageBonus,
    num damageScale})
      : verb = "",
        noun = null,
        baseDamage = 0,
        _element = element != null ? element : Element.none,
        _strikeBonus = strikeBonus != null ? strikeBonus : 0,
        _damageBonus = damageBonus != null ? damageBonus : 0,
        _damageScale = damageScale != null ? damageScale : 1.0;

  /// Returns a new attack identical to this one but with [offset] added.
  Attack addDamage(int offset) => _clone().._damageBonus += offset;

  /// Returns a new attack identical to this one but with [element].
  Attack brand(Element element) => _clone().._element = element;

  /// Returns a new attack identical to this one but with [bonus] added to the
  /// strike modifier.
  Attack addStrike(int bonus) => _clone().._strikeBonus += bonus;

  /// Returns a new attack identical to this one but with damage scaled by
  /// [factor].
  Attack multiplyDamage(num factor) => _clone().._damageScale *= factor;

  /// Creates a new attack that combines this one with [modifier].
  Attack combine(Attack modifier) {
    var result = _clone();
    result._strikeBonus += modifier._strikeBonus;
    result._damageBonus += modifier._damageBonus;
    result._damageScale *= modifier._damageScale;

    if (modifier.element != Element.none) {
      result._element = modifier._element;
    }

    return result;
  }

  /// Performs a melee [attack] from [attacker] to [defender] in the course of
  /// [action].
  ///
  /// Returns `true` if the attack connected.
  bool perform(Action action, Actor attacker, Actor defender, {bool canMiss}) {
    if (canMiss == null) canMiss = true;

    var attackNoun = noun != null ? noun : attacker;

    // See if the attack hits.
    if (canMiss) {
      var dodge = defender.dodge + strikeBonus;
      var strike = rng.inclusive(1, 100);

      // There's always at least a 5% chance of missing and a 5% chance of
      // hitting, regardless of all modifiers.
      strike = strike.clamp(5, 95);

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
      action.log('{1} do[es] no damage to {2}.', attackNoun,
          defender);
      return true;
    }

    attacker.onDamage(action, defender, damage);
    if (defender.takeDamage(action, damage, attackNoun, attacker)) return true;

    // Any resistance cancels all side effects.
    if (resistance <= 0) {
      _elementalSideEffect(defender, action, damage);
      // TODO: Should we log a message to let the player know the side effect
      // was resisted?
    }

    // TODO: Pass in and use element.
    action.addEvent(EventType.hit, actor: defender, other: damage);
    action.log('{1} ${verb} {2}.', attackNoun, defender);
    return true;
  }

  void _elementalSideEffect(Actor defender, Action action, int damage) {
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

  int _rollDamage(int armor, int resistance) {
    var resistScale = 1 / (1 + resistance);

    // Calculate in cents so that we don't do as much rounding until after
    // armor is taken into account.
    var damageCents = (averageDamage * resistScale * 100).toInt();
    var rolled = rng.triangleInt(damageCents, damageCents ~/ 2);
    rolled *= getArmorMultiplier(armor);
    return (rolled / 100).round();
  }

  String toString() {
    var result = baseDamage.toString();

    if (damageBonus > 0) {
      result += "+${damageBonus}";
    } else if (damageBonus < 0) {
      result += "${damageBonus}";
    }

    if (damageScale != 1.0) {
      result += "x$damageScale";
    }

    if (element != Element.none) {
      result += " $element";
    }

    return result;
  }

  void _copyTo(Attack other) {
    other._strikeBonus = strikeBonus;
    other._damageBonus = damageBonus;
    other._damageScale = damageScale;
  }

  Attack _clone() {
    var attack = new Attack(verb, baseDamage, element, noun);
    _copyTo(attack);
    return attack;
  }
}

class RangedAttack extends Attack {
  /// The maximum range of the attack.
  final int range;

  RangedAttack(Noun noun, String verb, int baseDamage, Element element, this.range)
      : super(verb, baseDamage, element, noun);

  RangedAttack _clone() {
    var attack = new RangedAttack(noun, verb, baseDamage, element, range);
    _copyTo(attack);
    return attack;
  }
}