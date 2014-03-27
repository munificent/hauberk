library dngn.engine.melee;

import 'dart:math' as math;

import '../util.dart';
import 'action_base.dart';
import 'actor.dart';
import 'element.dart';
import 'game.dart';
import 'hero.dart';
import 'log.dart';

class Attack {
  /// The thing performing the attack. If `null`, then the attacker will be
  /// used.
  final Noun noun;

  /// A verb string describing the attack: "hits", "fries", etc.
  final String verb;

  /// The average damage. The actual damage will be a `Rng.triangleInt` centered
  /// on this with a range of 1/2 of its value.
  final int damage;

  /// The element for the attack.
  final Element element;

  Attack(this.verb, this.damage, this.element, [this.noun]);

  /// Returns a new attack identical to this one but with [damageModifier]
  /// applied.
  Attack modifyDamage(int damageModifier) {
    return new Attack(verb, damage + damageModifier, element, noun);
  }

  /// Performs a melee [attack] from [attacker] to [defender] in the course of
  /// [action].
  ActionResult perform(Action action, Actor attacker, Actor defender) {
    final hit = new Hit(this);
    defender.takeHit(hit);

    final attackNoun = noun != null ? noun : attacker;

    // Roll for damage.
    final damage = hit.rollDamage();

    if (damage == 0) {
      // Armor cancelled out all damage.
      return action.succeed('{1} miss[es] {2}.', attackNoun, defender);
    }

    attacker.onDamage(defender, damage);
    defender.onDamaged(attacker, damage);
    defender.health.current -= damage;

    if (defender.health.current == 0) {
      action.addEvent(new Event.kill(defender));

      action.log('{1} kill[s] {2}.', attackNoun, defender);
      defender.onDied(attacker);
      attacker.onKilled(defender);

      if (defender is! Hero) {
        action.game.stage.actors.remove(defender);
      }

      return action.succeed();
    }

    action.addEvent(new Event.hit(defender, damage));
    return action.succeed('{1} ${verb} {2}.', attackNoun, defender);
  }

  String toString() => "$damage $element";
}

class Hit {
  /// The attack.
  final Attack attack;

  int armor = 0;

  Hit(this.attack);

  int rollDamage() {
    var damage = rng.triangleInt(attack.damage, attack.damage ~/ 2);
    damage *= getArmorMultiplier(armor);
    return damage.round().toInt();
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
num getArmorMultiplier(int armor) {
  // Damage is never increased.
  return 1.0 / (1.0 + math.max(0, armor) / 40.0);
}