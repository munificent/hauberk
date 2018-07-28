import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';

// TODO: More disciplines:
// - Dodging attacks, which increases dodge.
// - Fury. Increases damage when health is low. Trained by killing monsters
//   when near death.

abstract class MasteryDiscipline extends Discipline implements UsableSkill {
  // TODO: Tune.
  int get maxLevel => 20;

  String get weaponType;

  double _damageScale(int level) => lerpDouble(level, 1, maxLevel, 1.05, 2.0);

  void modifyAttack(Hero hero, Monster monster, Hit hit, int level) {
    if (!_hasWeapon(hero)) return;

    // TODO: Tune.
    hit.scaleDamage(_damageScale(level));
  }

  String levelDescription(int level) {
    var damage = ((_damageScale(level) - 1.0) * 100).toInt();
    return "Melee attacks inflict $damage% more damage when using a "
        "$weaponType.";
  }

  String unusableReason(Game game) {
    if (_hasWeapon(game.hero)) return null;

    return "No $weaponType equipped.";
  }

  bool _hasWeapon(Hero hero) {
    // Must have the right weapon equipped.
    var weapon = hero.equipment.weapon;
    if (weapon == null) return false;

    return weapon.type.weaponType == weaponType;
  }

  void killMonster(Hero hero, Action action, Monster monster) {
    // Have to have killed the monster by hitting it.
    if (action is! AttackAction) return;

    var weapon = hero.equipment.weapon;
    if (weapon == null) return;

    hero.skills.earnPoints(this, (monster.experienceCents / 1000).ceil());
    hero.refreshSkill(this);
  }

  // TODO: Tune.
  int baseTrainingNeeded(int level) => 100 * level * level * level;
}

abstract class MasteryAction extends Action {
  final double damageScale;

  MasteryAction(this.damageScale);

  /// Attempts to hit the [Actor] at [pos], if any.
  int attack(Vec pos) {
    var defender = game.stage.actorAt(pos);
    if (defender == null) return null;

    var hit = actor.createMeleeHit(defender);
    hit.scaleDamage(damageScale);
    return hit.perform(this, actor, defender);
  }

  double get noise => Sound.attackNoise;
}
