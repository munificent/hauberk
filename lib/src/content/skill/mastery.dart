import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

bool _hasWeapon(Hero hero, String weaponType) {
  // Must have the right weapon equipped.
  var weapon = hero.equipment.weapon;
  if (weapon == null) return false;

  return weapon.type.weaponType == weaponType;
}

abstract class MasterySkill extends Skill {
  // TODO: Tune.
  int get maxLevel => 20;

  Skill get prerequisite => Skill.strength;

  String get weaponType;

  void modifyAttack(Hero hero, Hit hit, int level) {
    if (!_hasWeapon(hero, weaponType)) return;

    // TODO: Tune.
    hit.scaleDamage(lerpDouble(level, 1, maxLevel, 1.05, 2.0));
  }
}

abstract class MasteryCommand extends Command {
  String get weaponType;

  bool canUse(Game game) => _hasWeapon(game.hero, weaponType);
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

  int get noise => Option.noiseHit;
}
