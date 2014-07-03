library dngn.engine.melee;

import 'dart:math' as math;

import '../util.dart';
import 'action_base.dart';
import 'action_magic.dart';
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

  Attack(String verb, num baseDamage, Element element, [Noun noun])
      : this._(noun, verb, baseDamage, 0.0, 1.0, element, 0);

  Attack._(this.noun, this.verb, this.baseDamage, this.damageBonus,
      this.damageScale, this.element, this.armor);

  /// Returns a new attack identical to this one but with [offset] added.
  Attack addDamage(num offset) {
    return new Attack._(noun, verb, baseDamage, damageBonus + offset,
        damageScale, element, armor);
  }

  /// Returns a new attack identical to this one but with damage scaled by
  /// [factor].
  Attack multiplyDamage(num factor) {
    return new Attack._(noun, verb, baseDamage, damageBonus,
        damageScale * factor, element, armor);
  }

  /// Returns a new attack with [armor] added to it.
  Attack addArmor(num armor) {
    return new Attack._(noun, verb, baseDamage, damageBonus, damageScale,
        element, this.armor + armor);
  }

  /// Performs a melee [attack] from [attacker] to [defender] in the course of
  /// [action].
  ActionResult perform(Action action, Actor attacker, Actor defender) {
    var attack = defender.defend(this);
    return attack._perform(action, attacker, defender);
  }

  ActionResult _perform(Action action, Actor attacker, Actor defender) {
    var attackNoun = noun != null ? noun : attacker;

    // Roll for damage.
    var damage = _rollDamage();

    if (damage == 0) {
      // Armor cancelled out all damage.
      return action.succeed('{1} miss[es] {2}.', attackNoun, defender);
    }

    attacker.onDamage(action, defender, damage);
    if (defender.takeDamage(action, damage, attackNoun, attacker)) {
      return action.succeed();
    }

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
        // TODO: Burn items.
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
        // TODO: Blind.
        break;

      case Element.SPIRIT:
        // TODO: Drain experience.
        break;
    }

    action.addEvent(new Event.hit(defender, damage));
    return action.succeed('{1} ${verb} {2}.', attackNoun, defender);
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
    var result = baseDamage.toString();
    if (damageBonus != 0 || damageScale != 1.0) {
      result += " ($damageBonus, $damageScale)";
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
