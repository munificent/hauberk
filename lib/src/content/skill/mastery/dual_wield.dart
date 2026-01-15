import '../../../engine.dart';

class DualWield extends Skill {
  @override
  String get name => "Dual-wield";

  @override
  String get description =>
      "Attack with a weapon in each hand as effectively as other lesser "
      "warriors do with only a single weapon in their puny arms.";

  @override
  String levelDescription(int level) =>
      "Total heft when dual-wielding is scaled by "
      "${_heftModifier(level).fmtPercent()}.";

  @override
  double modifyHeft(Hero hero, int level, double heftModifier) {
    // Have to be dual-wielding.
    if (hero.equipment.weapons.length == 2) {
      return heftModifier * _heftModifier(level);
    }

    return heftModifier;
  }

  double _heftModifier(int level) =>
      lerpDouble(level, 1, Skill.maxLevel, 1.0, 0.5);
}
