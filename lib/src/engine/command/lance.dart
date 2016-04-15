import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/fury.dart';
import '../game.dart';
import '../hero/command.dart';

// TODO: When pole-arms exist, have a 2-tile stab for spears and a 3-tile stab
// for polearms.
/// A piercing melee attack that penetrates a row of adjacent monsters.
class LanceCommand extends DirectionCommand {
  String get name => "Stab";

  bool canUse(Game game) {
    // Must have a spear equipped.
    var weapon = game.hero.equipment.weapon;
    if (weapon == null) return false;

    return weapon.type.categories.contains("spear");
  }

  Action getDirectionAction(Game game, Direction dir) => new LanceAction(dir);
}
