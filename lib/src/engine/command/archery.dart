import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/bolt.dart';
import '../attack.dart';
import '../game.dart';
import '../hero/command.dart';

class ArcheryCommand extends TargetCommand {
  String get name => "Archery";

  num getRange(Game game) =>
      (game.hero.equipment.weapon.attack as RangedAttack).range;

  bool canUse(Game game) {
    // Get the equipped ranged weapon, if any.
    var weapon = game.hero.equipment.weapon;
    return weapon != null && weapon.isRanged;
  }

  Action getTargetAction(Game game, Vec target) {
    var weapon = game.hero.equipment.weapon;
    return new BoltAction(target, weapon.attack, canMiss: true);
  }
}
