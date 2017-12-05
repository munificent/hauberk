import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/bolt.dart';
import 'mastery.dart';

class Archery extends MasterySkill implements TargetSkill {
  // TODO: Tune.
  static int focusCost(int level) => lerpInt(level, 1, 20, 300, 1);

  String get name => "Archery";
  String get description =>
      "Kill your foe without risking harm to yourself by unleashing a volley "
      "of arrows from far away.";

  String get weaponType => "bow";

  String levelDescription(int level) =>
      "Firing an arrow costs ${focusCost(level)} focus.";

  num getRange(Game game) {
    var hit = game.hero.createRangedHit();
    return hit.range;
  }

  Action getTargetAction(Game game, int level, Vec target) {
    var hit = game.hero.createRangedHit();
    var focus = Archery.focusCost(level);
    return new FocusAction(focus, new BoltAction(target, hit, canMiss: true));
  }
}
