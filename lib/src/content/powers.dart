import '../engine.dart';

class DualWield extends Power {
  @override
  String get name => "Dual-wield";

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
