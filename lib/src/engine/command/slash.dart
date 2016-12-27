import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/fury.dart';
import '../game.dart';
import '../hero/command.dart';

/// A slashing melee attack that hits a number of adjacent monsters.
class SlashCommand extends DirectionCommand {
  String get name => "Slash";

  bool canUse(Game game) {
    // Must have a sword equipped.
    var weapon = game.hero.equipment.weapon;
    if (weapon == null) return false;

    return weapon.type.hasTag("sword");
  }

  Action getDirectionAction(Game game, Direction dir) => new SlashAction(dir);
}
