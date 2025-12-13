import '../../../engine.dart';

class DualWield extends Skill {
  // TODO: Tune.
  @override
  int get maxLevel => 10;

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
  double modifyHeft(Hero hero, int level, double heftModifier) {
    // Have to be dual-wielding.
    if (hero.equipment.weapons.length == 2) {
      return heftModifier * _heftModifier(level);
    }

    return heftModifier;
  }

  double _heftModifier(int level) => lerpDouble(level, 1, maxLevel, 1.0, 0.5);
}
