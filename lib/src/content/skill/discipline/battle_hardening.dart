import 'dart:math' as math;

import '../../../engine.dart';

class BattleHardening extends Discipline {
  int get maxLevel => 40;

  String get description => "Years of taking hits have turned your skin as "
      "hard as cured leather.";

  String get name => "Battle Hardening";

  void takeDamage(Hero hero, int damage) {
    if (hero.skills.discover(this)) {
      // TODO: Copy/pasting log code here is lame.
      hero.game.log.gain(discoverMessage, hero);
    }

    // A point is one tenth of the hero's health.
    var points = (10 * damage / hero.maxHealth).ceil();

    hero.skills.earnPoints(this, points);
    hero.refreshSkill(this);
  }

  int modifyArmor(Hero hero, int level) => level;

  String levelDescription(int level) => "Increases armor by $level.";

  int baseTrainingNeeded(int level) => (60 * math.pow(1.5, level)).ceil();
}
