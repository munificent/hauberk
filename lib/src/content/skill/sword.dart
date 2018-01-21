import '../../engine.dart';
import 'mastery.dart';

class Swordfighting extends MasterySkill {
  static int _parryDefense(int level) => level ~/ 2 + 1;

  String get name => "Swordfighting";
  String get description =>
      "The most elegant tool for the most refined of martial arts.";
  String get weaponType => "sword";

  String levelDescription(int level) =>
      "Parrying increases dodge by ${_parryDefense(level)}.";

  Defense getDefense(Hero hero, int level) =>
      new Defense(level ~/ 2 + 1, "{1} parr[y|ies] {2}.");
}
