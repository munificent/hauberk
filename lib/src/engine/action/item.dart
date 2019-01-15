import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../core/element.dart';
import '../hero/hero.dart';
import '../items/inventory.dart';
import '../items/item.dart';
import 'action.dart';

/// Base class for an [Action] that works with an existing [Item] in the game.
abstract class ItemAction extends Action {
  /// The location of the item in the game.
  final ItemLocation location;

  /// The item.
  final Item item;

  ItemAction(this.location, this.item);

  // TODO: There's a lot of duplication in the code that calls this to handle
  // splitting the stack in some cases or removing in others. Unify that here
  // or maybe in Item or ItemCollection.
  /// Removes the item from its current location so it can be placed elsewhere.
  void removeItem() {
    switch (location) {
      case ItemLocation.onGround:
        game.stage.removeItem(item, actor.pos);
        break;

      case ItemLocation.inventory:
        hero.inventory.remove(item);

        if (item.emanationLevel > 0) {
          game.stage.actorEmanationChanged();
        }
        break;

      case ItemLocation.equipment:
        hero.equipment.remove(item);

        if (item.emanationLevel > 0) {
          game.stage.actorEmanationChanged();
        }
        break;

      default:
        throw StateError("Invalid location.");
    }
  }

  /// Called when the action has changed the count of [item].
  void countChanged() {
    switch (location) {
      case ItemLocation.onGround:
        // TODO: Need to optimize stacks on the ground too.
        // If the hero picks up part of a floor stack, it should be reshuffled.
//        game.stage.itemsAt(actor.pos).countChanged();
        break;

      case ItemLocation.inventory:
        hero.inventory.countChanged();
        break;

      case ItemLocation.equipment:
        hero.equipment.countChanged();
        break;

      default:
        throw StateError("Invalid location.");
    }
  }
}

/// [Action] for picking up an [Item] off the ground.
class PickUpAction extends Action {
  final Item item;

  PickUpAction(this.item);

  ActionResult onPerform() {
    var result = hero.inventory.tryAdd(item);
    if (result.added == 0) {
      return fail("{1} [don't|doesn't] have room for {2}.", actor, item);
    }

    log('{1} pick[s] up {2}.', actor, item.clone(result.added));

    // TODO: Use refreshProperties()?
    if (item.emanationLevel > 0) {
      game.stage.actorEmanationChanged();
    }

    if (result.remaining == 0) {
      game.stage.removeItem(item, actor.pos);
    } else {
      log("{1} [don't|doesn't] have room for {2}.", actor,
          item.clone(result.remaining));
    }

    hero.pickUp(item);
    return ActionResult.success;
  }
}

/// [Action] for dropping an [Item] from the [Hero]'s [Inventory] or [Equipment]
/// onto the ground.
class DropAction extends ItemAction {
  /// The number of items in the stack to drop.
  final int _count;

  DropAction(ItemLocation location, Item item, this._count)
      : super(location, item);

  ActionResult onPerform() {
    Item dropped;
    if (_count == item.count) {
      // Dropping the entire stack.
      dropped = item;
      removeItem();
    } else {
      dropped = item.splitStack(_count);
      countChanged();
    }

    if (location == ItemLocation.equipment) {
      log('{1} take[s] off and drop[s] {2}.', actor, dropped);
      hero.refreshProperties();
    } else {
      log('{1} drop[s] {2}.', actor, dropped);
    }

    game.stage.addItem(dropped, actor.pos);
    return ActionResult.success;
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Inventory] to his
/// [Equipment]. May cause a currently equipped Item to become unequipped. If
/// there is no room in the Inventory for that Item, it will drop to the ground.
class EquipAction extends ItemAction {
  EquipAction(ItemLocation location, Item item) : super(location, item);

  ActionResult onPerform() {
    // If it's already equipped, unequip it.
    if (location == ItemLocation.equipment) {
      return alternate(UnequipAction(location, item));
    }

    if (!hero.equipment.canEquip(item)) {
      return fail('{1} cannot equip {2}.', actor, item);
    }

    var equipped = item;
    if (item.count == 1) {
      removeItem();
    } else {
      equipped = item.splitStack(1);
      countChanged();
    }
    var unequipped = hero.equipment.equip(equipped);

    // Add the previously equipped item to inventory.
    if (unequipped != null) {
      // Make a copy with the original count for the message.
      var copy = unequipped.clone();
      var result = hero.inventory.tryAdd(unequipped, wasUnequipped: true);
      if (result.remaining == 0) {
        log('{1} unequip[s] {2}.', actor, copy);
      } else {
        // No room in inventory, so drop it.
        game.stage.addItem(unequipped, actor.pos);
        log(
            "{1} [don't|doesn't] have room for {2} and {2 he} drops to the "
            "ground.",
            actor,
            unequipped);
      }
    }

    log("{1} equip[s] {2}.", actor, equipped);
    hero.refreshProperties();
    return ActionResult.success;
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Equipment] to his
/// [Inventory]. If there is no room in the inventory, it will drop to the
/// ground.
class UnequipAction extends ItemAction {
  UnequipAction(ItemLocation location, Item item) : super(location, item);

  ActionResult onPerform() {
    // Make a copy with the original count for the message.
    var copy = item.clone();
    removeItem();
    var result = hero.inventory.tryAdd(item, wasUnequipped: true);
    if (result.remaining == 0) {
      log('{1} unequip[s] {2}.', actor, copy);
    } else {
      // No room in inventory, so drop it.
      game.stage.addItem(item, actor.pos);
      log(
          "{1} [don't|doesn't] have room for {2} and {2 he} drops to "
          "the ground.",
          actor,
          item);
    }

    hero.refreshProperties();
    return ActionResult.success;
  }
}

/// [Action] for using an [Item].
class UseAction extends ItemAction {
  UseAction(ItemLocation location, Item item) : super(location, item);

  ActionResult onPerform() {
    if (!item.canUse) return fail("{1} can't be used.", item);

    // TODO: Some items should not be usable when certain conditions are active.
    // For example, you cannot read scrolls when dazzled or blinded.

    var useAction = item.use();

    if (item.count == 0) {
      // The stack is used up, delete it.
      removeItem();
    } else {
      countChanged();
    }

    // Using it from the ground counts as picking it up.
    if (location == ItemLocation.onGround) hero.pickUp(item);

    hero.lore.useItem(item);
    // TODO: If using an item can change hero properties, refresh them.

    return alternate(useAction);
  }
}

/// Base class for actions that permanently destroy items.
abstract class DestroyActionMixin implements Action {
  // TODO: Take damage into account when choosing the odds?

  /// Tries to destroy [items] with [element].
  ///
  /// Handles splitting stacks and logging errors. Returns the total fuel
  /// produced by all destroyed items.
  int _destroy(Element element, Iterable<Item> items, bool isHeld,
      void Function(Item) removeItem) {
    var fuel = 0;

    // Copy items to avoid concurrent modification.
    for (var item in items.toList()) {
      // TODO: Having to handle missing keys here is lame.
      var chance = item.type.destroyChance[element] ?? 0;

      // Holding an item makes it less likely to be destroyed.
      if (isHeld) chance = math.min(30, chance ~/ 2);

      if (chance == 0) continue;

      // See how much of the stack is destroyed.
      var destroyedCount = 0;
      for (var i = 0; i < item.count; i++) {
        if (rng.percent(chance)) destroyedCount++;
      }

      if (destroyedCount == item.count) {
        // TODO: Effect.
        log("{1} ${element.destroyMessage}!", item);
        removeItem(item);
      } else if (destroyedCount > 0) {
        var destroyedPart = item.splitStack(destroyedCount);
        // TODO: Effect.
        log("{1} ${element.destroyMessage}!", destroyedPart);
      }

      fuel += item.type.fuel * destroyedCount;
    }

    return fuel;
  }

  /// Attempts to destroy items on the floor that can be destroyed by [element].
  int destroyFloorItems(Vec pos, Element element) {
    var fuel = _destroy(element, game.stage.itemsAt(pos), false, (item) {
      game.stage.removeItem(item, pos);
      // TODO: If the item takes effect when destroyed, do that here.
    });

    return fuel;
  }

  /// Attempts to destroy items the actor is holding that can be destroyed by
  /// [element].
  int destroyHeldItems(Element element) {
    // TODO: If monsters have inventories, need to handle that here.
    if (actor is! Hero) return 0;

    // Any resistance prevents destruction.
    if (actor.resistance(element) > 0) return 0;

    var fuel = _destroy(element, hero.inventory, true, (item) {
      hero.inventory.remove(item);
      // TODO: If the item takes effect when destroyed, do that here.
    });

    var anyEquipmentDestroyed = false;
    fuel += _destroy(element, hero.equipment, true, (item) {
      hero.equipment.remove(item);
      // TODO: If the item takes effect when destroyed, do that here.
      anyEquipmentDestroyed = true;
    });

    if (anyEquipmentDestroyed) hero.refreshProperties();
    return fuel;
  }
}
