import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/bolt.dart';
import '../skills.dart';
import 'mastery.dart';

class Archery extends MasterySkill {
  // TODO: Tune.
  static int focusCost(int level) => lerpInt(level, 1, 20, 300, 1);

  String get name => "Archery";
  String get description =>
      "Kill your foe without risking harm to yourself by unleashing a volley "
          "of arrows from far away.";

  String get weaponType => "bow";

  Command get command => new ArcheryCommand();

  String levelDescription(int level) =>
      "Firing an arrow costs ${focusCost(level)} focus.";
}

class ArcheryCommand extends MasteryCommand implements TargetCommand {
  String get name => "Archery";
  String get weaponType => "bow";

  num getRange(Game game) {
    var hit = game.hero.createRangedHit();
    return hit.range;
  }

  Action getTargetAction(Game game, Vec target) {
    var hit = game.hero.createRangedHit();
    var focus = Archery.focusCost(game.hero.skills[Skills.archery]);
    return new FocusAction(focus, new BoltAction(target, hit, canMiss: true));
  }
}
