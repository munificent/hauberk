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
  final num damage;

  /// The element for the attack.
  final Element element;

  /// The defender's armor.
  final num armor;

  Attack(this.verb, this.damage, this.element, [this.noun])
      : armor = 0;

  Attack._(this.noun, this.verb, this.damage, this.element, this.armor);

  // TODO: Instead of applying add and multiply bonuses eagerly, Attack should
  // compound them and only apply them at the end. This way:
  // - The game screen can show them split out.
  // - We can ensure bonuses stack the right way.

  /// Returns a new attack identical to this one but with [offset] added.
  Attack addDamage(num offset) {
    return new Attack._(noun, verb, damage + offset, element, armor);
  }

  /// Returns a new attack identical to this one but with damage scaled by
  /// [factor].
  Attack multiplyDamage(num factor) {
    return new Attack._(noun, verb, damage * factor, element, armor);
  }

  /// Returns a new attack with [armor] added to it.
  Attack addArmor(num armor) {
    return new Attack._(noun, verb, damage, element, this.armor + armor);
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
    var baseDamage = damage.toInt();
    var rolled = rng.triangleInt(baseDamage, baseDamage ~/ 2);
    rolled *= getArmorMultiplier(armor);
    return damage.round();
  }

  String toString() => "$damage $element";
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
