import '../engine.dart';

class Classes {
  static final adventurer = new HeroClass("Adventurer", "TODO");
  static final warrior = new HeroClass("Warrior", "TODO");
  static final mage = new HeroClass("Mage", "TODO");
  static final rogue = new HeroClass("Rogue", "TODO");
  static final priest = new HeroClass("Priest", "TODO");

  // TODO: Specialist subclasses.

  /// All of the known classes.
  static final List<HeroClass> all = [
    adventurer,
    warrior,
    mage,
    rogue,
    priest
  ];
}
