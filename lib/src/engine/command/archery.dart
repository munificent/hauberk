import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/bolt.dart';
import '../game.dart';
import '../hero/command.dart';

class ArcheryCommand extends TargetCommand {
  String get name => "Archery";

  num getRange(Game game) {
    var hit = game.hero.createRangedHit();
    return hit.range;
  }

  bool canUse(Game game) {
    // Get the equipped ranged weapon, if any.
    var weapon = game.hero.equipment.weapon;
    return weapon != null && weapon.attack.isRanged;
  }

  Action getTargetAction(Game game, Vec target) {
    var hit = game.hero.createRangedHit();
    return new BoltAction(target, hit, canMiss: true);
  }
}
