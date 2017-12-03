import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/bolt.dart';
import '../skills.dart';
import 'mastery.dart';

class WhipMastery extends MasterySkill {
  // TODO: Tune.
  static double _whipScale(int level) => lerpDouble(level, 1, 20, 0.2, 0.7);

  // TODO: Better name.
  String get name => "Whip Mastery";
  String get description =>
      "Whips and flails are difficult to use well, but deadly even at a "
          "distance when mastered.";
  String get weaponType => "whip";

  Command get command => new WhipCommand();

  String levelDescription(int level) {
    var damage = (_whipScale(level) * 100).toInt();
    return "Ranged whip attacks have $damage% of the damage of a regular "
        "attack.";
  }
}

// TODO: Copy/paste from ArcheryCommand. Unify?
class WhipCommand extends MasteryCommand implements TargetCommand {
  String get name => "Whip";
  String get weaponType => "whip";

  num getRange(Game game) => 3;

  Action getTargetAction(Game game, Vec target) {
    var hit = game.hero.createMeleeHit();
    hit.scaleDamage(
        WhipMastery._whipScale(game.hero.skills[Skills.whipMastery]));

    // TODO: Better effect.
    return new BoltAction(target, hit, range: getRange(game), canMiss: true);
  }
}
