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

/// This power doesn't actually do anything. Instead, the [FlitterAbility] is
/// gated on the hero being a fae.
///
/// This is just here to show up in the new hero screen.
class Flitter extends Power {
  @override
  String get name => "Flitter";

  @override
  String get description =>
      "Take flight and soar over the ground, at least until you get tired.";
}
