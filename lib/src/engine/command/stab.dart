import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/fury.dart';
import '../game.dart';
import '../hero/command.dart';

/// A melee attack that repeatedly stabs an adjacent monster.
class StabCommand extends DirectionCommand {
  String get name => "Stab";

  bool canUse(Game game) {
    // Must have a dagger equipped.
    var weapon = game.hero.equipment.weapon;
    if (weapon == null) return false;

    return weapon.type.weaponType == "dagger";
  }

  Action getDirectionAction(Game game, Direction dir) => new StabAction(dir);
}
