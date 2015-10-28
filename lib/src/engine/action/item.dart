library hauberk.engine.action.item;

import 'action.dart';
import '../items/inventory.dart';
import '../items/item.dart';

/// Base class for an [Action] that works with an existing [Item] in the game.
abstract class ItemAction extends Action {
  /// The location of the item in the game.
  final ItemLocation location;

  /// The index of the item in the collection where its located.
  final int itemIndex;

  /// Gets the referenced item.
  Item get item {
    switch (location) {
      case ItemLocation.onGround:
        return game.stage.itemsAt(actor.pos)[itemIndex];

      case ItemLocation.inventory:
        return hero.inventory[itemIndex];

      case ItemLocation.equipment:
        return hero.equipment[itemIndex];
    }

    throw "unreachable";
  }

  ItemAction(this.location, this.itemIndex);

  /// Removes the item from its current location so it can be placed elsewhere.
  Item removeItem() {
    var item;

    switch (location) {
      case ItemLocation.onGround:
        item = game.stage.itemsAt(actor.pos)[itemIndex];
        game.stage.removeItem(item);
        break;

      case ItemLocation.inventory:
        item = hero.inventory.removeAt(itemIndex);
        break;

      case ItemLocation.equipment:
        item = hero.equipment.removeAt(itemIndex);
        break;
    }

    item.pos = actor.pos;
    return item;
  }
}

/// [Action] for picking up an [Item] off the ground.
class PickUpAction extends Action {
  final int index;

  PickUpAction(this.index);

  ActionResult onPerform() {
    if (index == -1) return fail('There is nothing here.');

    var item = game.stage.itemsAt(actor.pos)[index];

    if (!hero.inventory.tryAdd(item)) {
      return fail("{1} [don't|doesn't] have room for {2}.", actor, item);
    }

    game.stage.removeItem(item);

    log('{1} pick[s] up {2}.', actor, item);

    game.quest.pickUpItem(game, item);
    return succeed();
  }
}

/// [Action] for dropping an [Item] from the [Hero]'s [Inventory] or [Equipment]
/// onto the ground.
class DropAction extends ItemAction {
  DropAction(ItemLocation location, int index)
      : super(location, index);

  ActionResult onPerform() {
    var dropped = removeItem();
    game.stage.items.add(dropped);

    if (location == ItemLocation.equipment) {
      return succeed('{1} take[s] off and drop[s] {2}.', actor, dropped);
    } else {
      return succeed('{1} drop[s] {2}.', actor, dropped);
    }
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Inventory] to his
/// [Equipment]. May cause a currently equipped Item to become unequipped. If
/// there is no room in the Inventory for that Item, it will drop to the ground.
class EquipAction extends ItemAction {
  EquipAction(ItemLocation location, int index)
      : super(location, index);

  ActionResult onPerform() {
    // If it's already equipped, unequip it.
    if (location == ItemLocation.equipment) {
      return alternate(new UnequipAction(location, itemIndex));
    }

    if (!hero.equipment.canEquip(item)) {
      return fail('{1} cannot equip {2}.', actor, item);
    }

    var equipped = removeItem();
    var unequipped = hero.equipment.equip(equipped);

    // Add the previously equipped item to inventory.
    if (unequipped != null) {
      if (hero.inventory.tryAdd(unequipped, wasUnequipped: true)) {
        log('{1} unequip[s] {2}.', actor, unequipped);
      } else {
        // No room in inventory, so drop it.
        unequipped.pos = actor.pos;
        game.stage.items.add(unequipped);
        log("{1} [don't|doesn't] have room for {2} and {2 he} drops to the "
            "ground.", actor, unequipped);
      }
    }

    return succeed('{1} equip[s] {2}.', actor, equipped);
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Equipment] to his
/// [Inventory]. If there is no room in the inventory, it will drop to the
/// ground.
class UnequipAction extends ItemAction {
  UnequipAction(ItemLocation location, int index)
      : super(location, index);

  ActionResult onPerform() {
    var item = removeItem();

    if (hero.inventory.tryAdd(item, wasUnequipped: true)) {
      return succeed('{1} unequip[s] {2}.', actor, item);
    }

    // No room in inventory, so drop it.
    item.pos = actor.pos;
    game.stage.items.add(item);
    return succeed("{1} [don't|doesn't] have room for {2} and {2 he} drops to "
        "the ground.", actor, item);
  }
}

/// [Action] for using an [Item] from the [Hero]'s [Inventory] or the ground.
/// If the Item is equippable, then using it means equipping it.
class UseAction extends ItemAction {
  UseAction(ItemLocation location, int index)
      : super(location, index);

  ActionResult onPerform() {
    // If it's equippable, then using it just equips it.
    if (item.canEquip) {
      return alternate(new EquipAction(location, itemIndex));
    }

    if (!item.canUse) {
      return fail("{1} can't be used.", item);
    }

    return alternate(removeItem().use());
  }
}
