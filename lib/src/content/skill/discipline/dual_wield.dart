import '../../../engine.dart';

class DualWield extends Discipline {
  // TODO: Tune.
  @override
  int get maxLevel => 10;

  static double _heftModifier(int level) => lerpDouble(level, 1, 10, 1.5, 0.7);

  @override
  String get name => "Dual-wield";

  @override
  String get description =>
      "Attack with a weapon in each hand as effectively as other lesser "
      "warriors do with only a single weapon in their puny arms.";

  @override
  String levelDescription(int level) =>
      "Total heft when dual-wielding is scaled by "
      "${(_heftModifier(level) * 100).toInt()}%.";

  @override
  int baseTrainingNeeded(int level) {
    // As soon as it's discovered, reach level 1.
    level--;

    return 100 * level * level * level;
  }

  @override
  void dualWield(Hero hero) {
    hero.discoverSkill(this);
  }

  @override
  double modifyHeft(Hero hero, int level, double heftModifier) {
    // Have to be dual-wielding.
    if (hero.equipment.weapons.length == 2) {
      return heftModifier * _heftModifier(level);
    }

    return heftModifier;
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
