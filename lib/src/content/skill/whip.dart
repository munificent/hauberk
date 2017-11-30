import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/bolt.dart';
import '../skills.dart';
import 'mastery.dart';

class WhipMastery extends MasterySkill {
  // TODO: Better name.
  String get name => "Whip Mastery";
  String get weaponType => "whip";

  Command get command => new WhipCommand();
}

// TODO: Copy/paste from ArcheryCommand. Unify?
class WhipCommand extends MasteryCommand implements TargetCommand {
  String get name => "Whip";
  String get weaponType => "whip";

  num getRange(Game game) => 3;

  Action getTargetAction(Game game, Vec target) {
    var hit = game.hero.createMeleeHit();

    var scale =
        lerpDouble(game.hero.skills[Skills.whipMastery], 1, 20, 0.2, 0.7);
    hit.scaleDamage(scale);

    // TODO: Better effect.
    return new BoltAction(target, hit, range: getRange(game), canMiss: true);
  }
}
