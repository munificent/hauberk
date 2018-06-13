import '../../../engine.dart';
import 'mastery.dart';

class Swordfighting extends MasteryDiscipline {
  static int _parryDefense(int level) => lerpInt(level, 1, 20, 1, 10);

  String get name => "Swordfighting";
  String get description =>
      "The most elegant tool for the most refined of martial arts.";
  String get weaponType => "sword";

  String levelDescription(int level) =>
      super.levelDescription(level) +
      " Parrying increases dodge by ${_parryDefense(level)}.";

  Defense getDefense(Hero hero, int level) =>
      new Defense(_parryDefense(level), "{1} parr[y|ies] {2}.");
}
