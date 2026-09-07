import '../engine.dart';

class DualWield extends Power {
  @override
  String get name => "Dual Wield";

  @override
  String get description =>
      "Attack with a weapon in each hand as effectively as lesser weaklings "
      "do with only a single weapon in their puny arms.";

  @override
  double modifyHeft(Hero hero, List<Item> weapons, double totalHeft) {
    if (weapons.isEmpty) return totalHeft;

    // If dual-wielding, take the average of their total heft.
    return totalHeft / weapons.length;
  }
}

class QuickStudy extends Power {
  @override
  String get name => "Quick Study";

  @override
  String get description => "Gain 10% more experience when killing a monster.";

  @override
  double modifyExperience(Hero hero, Monster monster, double experience) {
    return experience * 1.1;
  }
}
