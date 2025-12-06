import '../../../engine.dart';

class BattleHardening extends Skill {
  @override
  int get maxLevel => 40;

  @override
  String get description =>
      "Years of taking hits have turned your skin as "
      "hard as cured leather.";

  @override
  String get name => "Battle Hardening";

  @override
  int modifyArmor(HeroSave hero, int level, int armor) => armor + level;

  @override
  String levelDescription(int level) => "Increases armor by $level.";
}
