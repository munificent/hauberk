import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../ai/flow.dart';
import '../game.dart';
import '../hero/hero.dart';
import '../items/item.dart';

/// These actions are side effects from taking elemental damage.

abstract class DestroyItemMixin extends Action {
  /// Tries to destroy [items] where each item with [flag] has a one in [chance]
  /// chance of being destroyed.
  ///
  /// Handles splitting stacks and logging errors. Returns the list of
  /// completely destroyed items so they can be removed from whatever collection
  /// contains them.
  List<Item> destroyItems(
      Iterable<Item> items, int chance, String flag, String message) {
    var destroyed = <Item>[];

    for (var item in items) {
      if (!item.flags.contains(flag)) continue;

      // See how much of the stack is destroyed.
      var destroyedCount = 0;
      for (var i = 0; i < item.count; i++) {
        if (rng.oneIn(chance)) destroyedCount++;
      }

      if (destroyedCount == item.count) {
        // TODO: Effect.
        log("{1} $message!", item);
        destroyed.add(item);
      } else if (destroyedCount > 0) {
        var destroyedPart = item.splitStack(destroyedCount);
        // TODO: Effect.
        log("{1} $message!", destroyedPart);
      }
    }

    return destroyed;
  }

  void destroyInventory(int chance, String flag, String message) {
    // TODO: If monsters have inventories, need to handle that here.
    if (actor is! Hero) return;

    // TODO: Do same thing for equipment slots if there are any destroyable
    // equippable items.
    for (var item in destroyItems(hero.inventory, chance, flag, message)) {
      hero.inventory.remove(item);
    }
  }
}

class BurnAction extends Action with DestroyItemMixin {
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
