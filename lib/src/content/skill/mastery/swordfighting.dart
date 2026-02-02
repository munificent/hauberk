import '../../../engine.dart';
import 'mastery.dart';

class Swordfighting extends MasterySkill {
  static int _parryDefense(int level) =>
      lerpInt(level, 1, Skill.maxLevel, 5, 30);

  @override
  String get name => "Swordfighting";

  @override
  String get description =>
      "The most elegant tool for the most refined of martial arts.";

  @override
  String get weaponType => "sword";

  @override
  String levelDescription(int level) =>
      "${super.levelDescription(level)} Parrying increases dodge by "
      "${_parryDefense(level)}.";

  @override
  Iterable<Defense> defenses(Hero hero, int level) sync* {
    // The hero can parry with both swords if dual-wielding.
    for (var weapon in hero.equipment.weapons) {
      if (weapon.type.weaponType == "sword") {
        // TODO: Should the parrying ability depend on the sword's damage?
        yield Defense(_parryDefense(level), "{1} parr[y|ies] {2}.");
      }
    }
  }
}
