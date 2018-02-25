import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';

// TODO: Trained skills for:
// - Taking damage, which increases armor.
// - Dodging attacks, which increases dodge.

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

  // TODO: The fact that this only counts kills and not the difficulty of the
  // monster means players are incentivized to grind weak monsters to raise
  // this. Is that OK?
  int trained(Lore lore) => lore.killsUsing(weaponType);

  // TODO: Tune.
  /// How much training is needed to reach [level].
  int baseTrainingNeeded(int level) => 10 * level * level;
}

abstract class MasteryAction extends Action {
  final double _damageScale;

  MasteryAction(this._damageScale);

  /// Attempts to hit the [Actor] at [pos], if any.
  void attack(Vec pos) {
    var defender = game.stage.actorAt(pos);
    if (defender == null) return;

    var hit = actor.createMeleeHit(defender);
    hit.scaleDamage(_damageScale);
    hit.perform(this, actor, defender);
  }

  double get noise => Sound.attackNoise;
}
