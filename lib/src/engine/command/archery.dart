library hauberk.engine.command.archery;

import '../action/action.dart';
import '../action/bolt.dart';
import '../game.dart';
import '../hero/command.dart';

class ArcheryCommand extends TargetCommand {
  String get name => "Archery";

  num getMinRange(Game game) => 1.5;
  num getMaxRange(Game game) => game.hero.equipment.weapon.attack.range;

  bool canUse(Game game) {
    // Get the equipped ranged weapon, if any.
    var weapon = game.hero.equipment.weapon;
    return weapon != null && weapon.attack.isRanged;
  }

  Action getTargetAction(Game game, Vec target) {
    var weapon = game.hero.equipment.weapon;
    return new BoltAction(game.hero.pos, target, weapon.attack);
  }
}
