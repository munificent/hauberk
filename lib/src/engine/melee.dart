library hauberk.engine.melee;

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'action/action.dart';
import 'action/condition.dart';
import 'action/element.dart';
import 'actor.dart';
import 'element.dart';
import 'game.dart';
import 'log.dart';

class Attack {
  /// The thing performing the attack. If `null`, then the attacker will be
  /// used.
  final Noun noun;

  /// A verb string describing the attack: "hits", "fries", etc.
  final String verb;

  /// The bonus applied to the defender's base dodge ability. A higher bonus
  /// makes it more likely the attack will make contact.
  final num strikeBonus;

  /// The average damage. The actual damage will be a `Rng.triangleInt` centered
  /// on this with a range of 1/2 of its value.
  final num baseDamage;

  /// Additional damage added to [baseDamage] after the multiplier has been
  /// applied.
  final num damageBonus;

  /// The multiplier for [baseDamage].
  final num damageScale;

  /// The average damage inflicted by the attack.
  num get averageDamage => baseDamage * damageScale + damageBonus;

  /// The element for the attack.
  final Element element;

  /// The defender's armor.
  final num armor;

  /// The defender's level of resistance to the attack's element.
  ///
  /// Zero means no resistance. Everything above that reduces damage by
  /// 1/(resistance + 1), so that one resists is half damage, two is third, etc.
  /// Secondary effects from the element are nullified if the defender has any
  /// resistance.
  final int resistance;

  /// The maximum range of a missile attack, or `0` if the attack isn't ranged.
  final int range;

  bool get isRanged => range != 0;

  Attack(String verb, num baseDamage, Element element, [Noun noun, int range])
      : this._(noun, verb, 0.0, baseDamage, 0.0, 1.0, element, 0, 0,
          range != null ? range : 0);

  Attack._(this.noun, this.verb, this.strikeBonus, this.baseDamage,
      this.damageBonus, this.damageScale, this.element, this.armor,
      this.resistance, this.range);

  /// Returns a new attack identical to this one but with [offset] added.
  Attack addDamage(num offset) {
    return new Attack._(noun, verb, strikeBonus, baseDamage,
        damageBonus + offset, damageScale, element, armor, resistance, range);
  }

  /// Returns a new attack identical to this one but with [element].
  Attack brand(Element element) {
    return new Attack._(noun, verb, strikeBonus, baseDamage, damageBonus,
        damageScale, element, armor, resistance, range);
  }

  /// Returns a new attack identical to this one but with [bonus] added to the
  /// strike modifier.
  Attack addStrike(num bonus) {
    return new Attack._(noun, verb, strikeBonus + bonus, baseDamage,
        damageBonus, damageScale, element, armor, resistance, range);
  }

  /// Returns a new attack identical to this one but with damage scaled by
  /// [factor].
  Attack multiplyDamage(num factor) {
    return new Attack._(noun, verb, strikeBonus, baseDamage, damageBonus,
        damageScale * factor, element, armor, resistance, range);
  }

  /// Returns a new attack with [armor] added to it.
  Attack addArmor(num armor) {
    return new Attack._(noun, verb, strikeBonus, baseDamage, damageBonus,
        damageScale, element, this.armor + armor, resistance, range);
  }

  /// Returns a new attack with [resist] added to it.
  Attack addResistance(int resist) {
    return new Attack._(noun, verb, strikeBonus, baseDamage, damageBonus,
        damageScale, element, this.armor + armor, resistance + resist, range);
  }

  /// Performs a melee [attack] from [attacker] to [defender] in the course of
  /// [action].
  ActionResult perform(Action action, Actor attacker, Actor defender,
      {bool canMiss}) {
    var attack = defender.defend(this);
    return attack._perform(action, attacker, defender, canMiss: canMiss);
  }

  ActionResult _perform(Action action, Actor attacker, Actor defender,
      {bool canMiss}) {
    if (canMiss == null) canMiss = true;

    var attackNoun = noun != null ? noun : attacker;

    // See if the attack hits.
    if (canMiss) {
      var dodge = defender.dodge + strikeBonus;
      var strike = rng.inclusive(1, 100);

      // There's always at least a 5% chance of missing and a 5% chance of
      // hitting, regardless of all modifiers.
      strike = clamp(5, strike, 95);

      if (strike < dodge) {
        return action.succeed('{1} miss[es] {2}.', attackNoun, defender);
      }
    }

    // Roll for damage.
    var damage = _rollDamage();

    if (damage == 0) {
      // Armor cancelled out all damage.
      return action.succeed('{1} do[es] no damage to {2}.', attackNoun,
          defender);
    }

    attacker.onDamage(action, defender, damage);
    if (defender.takeDamage(action, damage, attackNoun, attacker)) {
      return action.succeed();
    }

    if (resistance == 0) _elementalSideEffect(defender, action, damage);

    // TODO: Pass in and use element.
    action.addEvent(new Event(EventType.HIT, actor: defender, value: damage));
    return action.succeed('{1} ${verb} {2}.', attackNoun, defender);
  }

  void _elementalSideEffect(Actor defender, Action action, int damage) {
    // Apply any element-specific effects.
    switch (element) {
      case Element.NONE:
        // No effect.
        break;

      case Element.AIR:
        // TODO: Teleport.
        break;

      case Element.EARTH:
        // TODO: Cuts?
        break;

      case Element.FIRE:
        action.addAction(new BurnAction(damage), defender);
        break;

      case Element.WATER:
        // TODO: Push back.
        break;

      case Element.ACID:
        // TODO: Destroy items.
        break;

      case Element.COLD:
        action.addAction(new FreezeAction(damage), defender);
        break;

      case Element.LIGHTNING:
        // TODO: Break glass. Recharge some items?
        break;

      case Element.POISON:
        action.addAction(new PoisonAction(damage), defender);
        break;

      case Element.DARK:
        // TODO: Blind.
        break;

      case Element.LIGHT:
        action.addAction(new DazzleAction(damage), defender);
        break;

      case Element.SPIRIT:
        // TODO: Drain experience.
        break;
    }
  }

  int _rollDamage() {
    // Calculate in cents so that we don't do as much rounding until after
    // armor is taken into account.
    var damageCents = (averageDamage * 100).toInt();
    var rolled = rng.triangleInt(damageCents, damageCents ~/ 2);
    rolled *= getArmorMultiplier(armor);
    return (rolled / 100).round();
  }

  String toString() {
    var result = baseDamage.toInt().toString();

    if (damageBonus > 0) {
      result += "+${damageBonus.toInt()}";
    } else if (damageBonus < 0) {
      result += "${damageBonus.toInt()}";
    }

    if (damageScale != 1.0) {
      result += "x$damageScale";
    }

    if (element != Element.NONE) {
      result += " $element";
    }

    return result;
  }
}

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
num getArmorMultiplier(num armor) {
  // Damage is never increased.
  return 1.0 / (1.0 + math.max(0, armor) / 40.0);
}
