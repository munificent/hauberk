import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';

abstract class MasterySkill extends Skill {
  String get weaponType;

  double _damageScale(int level) =>
      lerpDouble(level, 1, Skill.modifiedMax, 1.1, 4.0);

  @override
  void modifyHit(
    Hero hero,
    Monster? monster,
    Item? weapon,
    Hit hit,
    int level,
  ) {
    // Only for weapons that this mastery applies to.
    if (weapon == null || weapon.type.weaponType != weaponType) return;

    hit.scaleDamage(_damageScale(level), 'mastery');
  }

  @override
  String levelDescription(int level) {
    var damage = (_damageScale(level) - 1.0).fmtPercent();
    var a = "aeiou".contains(weaponType[0]) ? "an" : "a";
    return "Melee attacks inflict +$damage damage when using $a "
        "$weaponType.";
  }
}

// TODO: These should be more powerful and drain focus.
abstract class MasteryAbility extends Ability {
  String get weaponType;

  @override
  String? unusableReason(Game game) {
    if (_hasWeapon(game.hero)) return null;

    return "No $weaponType equipped";
  }

  bool _hasWeapon(Hero hero) =>
      hero.equipment.weapons.any((item) => item.type.weaponType == weaponType);
}

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
