import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../ai/flow.dart';
import '../game.dart';
import '../hero/hero.dart';

/// These actions are side effects from taking elemental damage.

abstract class DestroyInventoryMixin extends Action {
  void destroyInventory(int chance, String flag, String message) {
    // TODO: If monsters have inventories, need to handle that here.
    if (actor is! Hero) return;

    // TODO: Do same thing for equipment slots if there are any flammable
    // equippable items.
    for (var i = 0; i < hero.inventory.length; i++) {
      var item = hero.inventory[i];
      if (item.flags.contains(flag) && rng.oneIn(chance)) {
        // TODO: Effect.
        log("{1} $message!", item);
        hero.inventory.removeAt(i);
        i--;
      }
    }
  }
}

class BurnAction extends Action with DestroyInventoryMixin {
  ActionResult onPerform() {
    destroyInventory(5, "flammable", "burns up");

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.success;
  }
}

class WindAction extends Action {
  ActionResult onPerform() {
    // Move the actor to a random reachable tile.
    var flow = new Flow(game.stage, actor.pos, maxDistance: 2);
    var positions = flow
        .findAll()
        .where((pos) => game.stage.actorAt(pos) == null)
        .toList();
    if (positions.isEmpty) return ActionResult.failure;

    log("{1} [are|is] thrown by the wind!", actor);
    addEvent(EventType.wind, actor: actor, pos: actor.pos);
    actor.pos = rng.item(positions);

    return ActionResult.success;
  }
}
