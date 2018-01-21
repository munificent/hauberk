import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

// TODO: Trained skills for:
// - Taking damage, which increases armor.
// - Dodging attacks, which increases dodge.
// - Slaying different breed families.

abstract class MasterySkill extends UsableSkill implements TrainedSkill {
  // TODO: Tune.
  int get maxLevel => 20;

  String get weaponType;

  void modifyAttack(Hero hero, Hit hit, int level) {
    if (!_hasWeapon(hero)) return;

    // TODO: Tune.
    hit.scaleDamage(lerpDouble(level, 1, maxLevel, 1.05, 2.0));
  }

  bool canUse(Game game) => _hasWeapon(game.hero);

  bool _hasWeapon(Hero hero) {
    // Must have the right weapon equipped.
    var weapon = hero.equipment.weapon;
    if (weapon == null) return false;

    return weapon.type.weaponType == weaponType;
  }

  int levelForWeapon(String weaponType, int hits) {
    if (weaponType != this.weaponType) return 0;

    // TODO: Tune this. Should probably be on a curve.
    // TODO: Should take HeroClass into account.
    return math.min(hits ~/ 100, maxLevel);
  }
}

abstract class MasteryAction extends Action {
  final double _damageScale;

  MasteryAction(this._damageScale);

  /// Attempts to hit the [Actor] as [pos], if any.
  void attack(Vec pos) {
    var defender = game.stage.actorAt(pos);
    if (defender == null) return;

    var hit = actor.createMeleeHit();
    hit.scaleDamage(_damageScale);
    hit.perform(this, actor, defender);
  }

  double get noise => Sound.attackNoise;
}
