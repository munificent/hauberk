import '../../engine.dart';

class BattleHardening extends Skill {
  @override
  String get description =>
      "Years of taking hits have turned your skin as "
      "hard as cured leather.";

  @override
  String get name => "Battle Hardening";

  @override
  int modifyArmor(HeroSave hero, int armor) {
    var level = hero.skills.level(this);
    return armor + _armorModifier(level);
  }

  @override
  String levelDescription(int level) =>
      "Increases armor by ${_armorModifier(level)}.";

  int _armorModifier(int level) => level * 4;
}
