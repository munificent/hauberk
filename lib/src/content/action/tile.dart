import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../item/drops.dart';
import '../tiles.dart';

/// Open a barrel and place its drops.
class OpenBarrelAction extends Action {
  final Vec _pos;

  OpenBarrelAction(this._pos);

  ActionResult onPerform() {
    game.stage[_pos].type = Tiles.openBarrel;
    addEvent(EventType.openBarrel, pos: _pos);

    // TODO: More interesting drop.
    // TODO: Take the barrel's place into account.
    // TODO: Chance of monster (rat, spider) in barrel?
    if (rng.percent(lerpInt(game.depth, 1, Option.maxDepth, 40, 10))) {
      log("The barrel is empty.", actor);
    } else {
      var drop = parseDrop("food", game.depth);
      game.stage.placeDrops(_pos, MotilitySet.walk, drop);

      log("{1} open[s] the barrel.", actor);
    }

    return ActionResult.success;
  }
}
