import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/bolt.dart';
import 'mastery.dart';

class WhipMastery extends MasteryDiscipline implements TargetSkill {
  // TODO: Tune.
  static double _whipScale(int level) => lerpDouble(level, 1, 20, 0.2, 0.7);

  // TODO: Better name.
  String get name => "Whip Mastery";
  String get description =>
      "Whips and flails are difficult to use well, but deadly even at a "
      "distance when mastered.";
  String get weaponType => "whip";

  String levelDescription(int level) {
    var damage = (_whipScale(level) * 100).toInt();
    return super.levelDescription(level) +
        " Ranged whip attacks inflict $damage% of the damage of a regular "
            "attack.";
  }

  num getRange(Game game) => 3;

  Action getTargetAction(Game game, int level, Vec target) {
    var hit = game.hero.createMeleeHit();
    hit.scaleDamage(WhipMastery._whipScale(level));

    // TODO: Better effect.
    return new BoltAction(target, hit, range: getRange(game), canMiss: true);
  }
}
