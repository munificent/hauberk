import 'dart:math' as math;

import '../../../engine.dart';
import 'discipline.dart';

class BattleHardening extends Discipline {
  @override
  int get maxLevel => 40;

  @override
  String get description =>
      "Years of taking hits have turned your skin as "
      "hard as cured leather.";

  @override
  String get name => "Battle Hardening";

  @override
  void takeDamage(Hero hero, int damage) {
    hero.discoverSkill(this);

    // A point is one tenth of the hero's health.
    var points = (10 * damage / hero.maxHealth).ceil();

    hero.skills.earnPoints(this, points);
    hero.refreshSkill(this);
  }

  @override
  int modifyArmor(HeroSave hero, int level, int armor) => armor + level;

  @override
  String levelDescription(int level) => "Increases armor by $level.";

  @override
  int baseTrainingNeeded(int level) => (60 * math.pow(level, 1.5)).ceil();
}
