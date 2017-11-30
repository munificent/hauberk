import '../../engine.dart';
import 'mastery.dart';

class Swordfighting extends MasterySkill {
  String get name => "Swordfighting";
  String get weaponType => "sword";

  Defense getDefense(Hero hero, int level) =>
      new Defense(level ~/ 2 + 1, "{1} parr[y|ies] {2}.");
}
