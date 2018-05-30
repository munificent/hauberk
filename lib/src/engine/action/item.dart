import 'package:piecemeal/piecemeal.dart';

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

    if (item.emanationLevel > 0) {
      game.stage.actorEmanationChanged();
    }

    if (result.remaining == 0) {
      game.stage.removeItem(item, actor.pos);
    } else {
      log("{1} [don't|doesn't] have room for {2}.", actor,
          item.clone(result.remaining));
    }

    hero.gainItemSkills(item);
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
      succeed('{1} take[s] off and drop[s] {2}.', actor, dropped);
    } else {
      succeed('{1} drop[s] {2}.', actor, dropped);
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
      return alternate(new UnequipAction(location, item));
    }

    if (!hero.equipment.canEquip(item)) {
      return fail('{1} cannot equip {2}.', actor, item);
    }

    var equipped = item;
    removeItem();
    var unequipped = hero.equipment.equip(equipped);

    // Add the previously equipped item to inventory.
    if (unequipped != null) {
      var result = hero.inventory.tryAdd(unequipped, wasUnequipped: true);
      if (result.remaining == 0) {
        log('{1} unequip[s] {2}.', actor, unequipped);
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

    return succeed('{1} equip[s] {2}.', actor, equipped);
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Equipment] to his
/// [Inventory]. If there is no room in the inventory, it will drop to the
/// ground.
class UnequipAction extends ItemAction {
  UnequipAction(ItemLocation location, Item item) : super(location, item);

  ActionResult onPerform() {
    removeItem();
    var result = hero.inventory.tryAdd(item, wasUnequipped: true);
    if (result.remaining == 0) {
      return succeed('{1} unequip[s] {2}.', actor, item);
    }

    // No room in inventory, so drop it.
    game.stage.addItem(item, actor.pos);
    return succeed(
        "{1} [don't|doesn't] have room for {2} and {2 he} drops to "
        "the ground.",
        actor,
        item);
  }
}

/// [Action] for using an [Item] from the [Hero]'s [Inventory] or the ground.
/// If the Item is equippable, then using it means equipping it.
class UseAction extends ItemAction {
  UseAction(ItemLocation location, Item item) : super(location, item);

  ActionResult onPerform() {
    // If it's equippable, then using it just equips it.
    if (item.canEquip) {
      return alternate(new EquipAction(location, item));
    }

    if (!item.canUse) {
      return fail("{1} can't be used.", item);
    }

    // TODO: Some items should not be usable when certain conditions are active.
    // For example, you cannot read scrolls when dazzled or blinded.

    var useAction = item.use();

    if (item.count == 0) {
      // The stack is used up, delete it.
      removeItem();
    } else {
      countChanged();
    }

    return alternate(useAction);
  }
}

/// Base class for actions that permanently destroy items.
abstract class DestroyAction extends Action {
  final int _chance;
  final String _flag;
  final String _message;

  DestroyAction(this._chance, this._flag, this._message);

  /// Tries to destroy [items] where each item with [flag] has a one in [chance]
  /// chance of being destroyed.
  ///
  /// Handles splitting stacks and logging errors. Returns the list of
  /// completely destroyed items so they can be removed from whatever collection
  /// contains them.
  List<Item> _destroyItems(Iterable<Item> items) {
    var destroyed = <Item>[];

    for (var item in items) {
      if (!item.flags.contains(_flag)) continue;

      // See how much of the stack is destroyed.
      var destroyedCount = 0;
      for (var i = 0; i < item.count; i++) {
        if (rng.oneIn(_chance)) destroyedCount++;
      }

      if (destroyedCount == item.count) {
        // TODO: Effect.
        log("{1} $_message!", item);
        destroyed.add(item);
      } else if (destroyedCount > 0) {
        var destroyedPart = item.splitStack(destroyedCount);
        // TODO: Effect.
        log("{1} $_message!", destroyedPart);
      }
    }

    return destroyed;
  }
}

class DestroyOnFloorAction extends DestroyAction {
  final Vec _pos;

  DestroyOnFloorAction(this._pos, int chance, String flag, String message)
      : super(chance, flag, message);

  ActionResult onPerform() {
    var destroyed = _destroyItems(game.stage.itemsAt(_pos));
    for (var item in destroyed) {
      game.stage.removeItem(item, _pos);
    }

    // TODO: If the item takes effect when destroyed, do that here.

    return ActionResult.success;
  }
}

class DestroyInInventoryAction extends DestroyAction {
  DestroyInInventoryAction(int chance, String flag, String message)
      : super(chance, flag, message);

  ActionResult onPerform() {
    // TODO: If monsters have inventories, need to handle that here.
    if (actor is! Hero) return ActionResult.success;

    // TODO: Do same thing for equipment slots if there are any destroyable
    // equippable items.
    for (var item in _destroyItems(hero.inventory)) {
      hero.inventory.remove(item);
    }

    // TODO: If the item takes effect when destroyed, do that here.

    return ActionResult.success;
  }
}
