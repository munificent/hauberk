import '../../../engine.dart';

class DualWield extends Discipline {
  // TODO: Tune.
  @override
  int get maxLevel => 10;

  static double _heftModifier(int level) => lerpDouble(level, 0, 10, 1.0, 0.5);

  @override
  String get name => "Dual-wield";

  @override
  String get description =>
      "Attack with a weapon in each hand as effectively as other lesser "
      "warriors do with only a single weapon in their puny arms.";

  @override
  String levelDescription(int level) => "Reduces heft when dual-wielding by "
      "${((1.0 - _heftModifier(level)) * 100).toInt()}%.";

  @override
  int baseTrainingNeeded(int level) => 100 * level * level * level;

  @override
  void dualWield(Hero hero) {
    hero.discoverSkill(this);
  }

  @override
  double modifyHeft(Hero hero, int level, double heftModifier) {
    // Have to be dual-wielding.
    if (hero.equipment.weapons.length != 2) return heftModifier;

    return heftModifier * _heftModifier(level);
  }

  @override
  void killMonster(Hero hero, Action action, Monster monster) {
    // Have to have killed the monster by hitting it.
    if (action is! AttackAction) return;

    // Have to be dual-wielding.
    if (hero.equipment.weapons.length != 2) return;

    hero.skills.earnPoints(this, (monster.experience / 100).ceil());
    hero.refreshSkill(this);
  }
}
