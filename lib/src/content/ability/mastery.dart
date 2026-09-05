import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

// TODO: I think we can probably get rid of this. The mastery skills already
// boost melee damage, which is probably enough?
abstract class MasteryAction extends Action {
  final double damageScale;

  MasteryAction(this.damageScale);

  String get weaponType;

  /// Attempts to hit the [Actor] at [pos], if any.
  int? attack(Vec pos) {
    var defender = game.stage.actorAt(pos);
    if (defender == null) return null;

    // If dual-wielding two weapons of the mastered type, both are used.
    var weapons = hero.equipment.weapons.toList();
    var hits = hero.createMeleeHits(defender);
    assert(weapons.length == hits.length);

    var damage = 0;
    for (var i = 0; i < weapons.length; i++) {
      if (weapons[i].type.weaponType != weaponType) continue;

      var hit = hits[i];
      hit.scaleDamage(damageScale, 'mastery');
      damage += hit.perform(this, actor, defender);

      if (!defender.isAlive) break;
    }

    return damage;
  }

  @override
  double get noise => Sound.attackNoise;
}

class WeaponTypeRequirement extends Requirement {
  final String _weaponType;

  WeaponTypeRequirement(this._weaponType);

  @override
  String get description {
    // TODO: Use Noun stuff for this?
    var a = "aeiou".contains(_weaponType[0]) ? "an" : "a";
    return "You must have $a $_weaponType equipped.";
  }

  @override
  String? check(Game game) {
    if (game.hero.equipment.weapons.any(
      (item) => item.type.weaponType == _weaponType,
    )) {
      return null;
    }

    return "No $_weaponType equipped";
  }
}
