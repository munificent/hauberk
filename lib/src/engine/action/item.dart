library hauberk.engine.action.item;

import 'action.dart';

/// [Action] for picking up an [Item] off the ground.
class PickUpAction extends Action {
  ActionResult onPerform() {
    // TODO: Handle stacks on the ground.
    final item = game.stage.itemAt(actor.pos);
    if (item == null) {
      return fail('There is nothing here.');
    }

    if (!hero.inventory.tryAdd(item)) {
      return fail("{1} [don't|doesn't] have room for {2}.", actor, item);
    }

    game.stage.removeItem(item);

    log('{1} pick[s] up {2}.', actor, item);

    game.quest.pickUpItem(game, item);
    return succeed();
  }
}

/// [Action] for dropping an [Item] from the [Hero]'s [Inventory] onto the
/// ground.
class DropInventoryAction extends Action {
  final int index;

  DropInventoryAction(this.index);

  ActionResult onPerform() {
    final item = hero.inventory.removeAt(index);
    item.pos = hero.pos;
    game.stage.items.add(item);

    return succeed('{1} drop[s] {2}.', actor, item);
  }
}

/// [Action] for dropping an [Item] from the [Hero]'s [Equipment] onto the
/// ground.
class DropEquipmentAction extends Action {
  final int index;

  DropEquipmentAction(this.index);

  ActionResult onPerform() {
    final item = hero.equipment.removeAt(index);
    item.pos = hero.pos;
    game.stage.items.add(item);

    return succeed('{1} take[s] off and drop[s] {2}.', actor, item);
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Inventory] to his
/// [Equipment]. May cause a currently equipped Item to become unequipped. If
/// there is no room in the Inventory for that Item, it will drop to the ground.
class EquipAction extends Action {
  final int index;
  final bool isOnGround;

  EquipAction(this.index, this.isOnGround);

  ActionResult onPerform() {
    var item = isOnGround
        ? game.stage.itemsAt(actor.pos)[index]
        : hero.inventory[index];

    if (!hero.equipment.canEquip(item)) {
      return fail('{1} cannot equip {2}.', actor, item);
    }

    final unequipped = hero.equipment.equip(item);

    if (isOnGround) {
      game.stage.removeItem(item);
    } else {
      hero.inventory.removeAt(index);
    }

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

    return succeed('{1} equip[s] {2}.', actor, item);
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Equipment] to his
/// [Inventory]. If there is no room in the inventory, it will drop to the
/// ground.
class UnequipAction extends Action {
  final int index;

  UnequipAction(this.index);

  ActionResult onPerform() {
    final item = hero.equipment.removeAt(index);

    if (hero.inventory.tryAdd(item, wasUnequipped: true)) {
      return succeed('{1} unequip[s] {2}.', actor, item);
    }

    // No room in inventory, so drop it.
    item.pos = actor.pos;
    game.stage.items.add(item);
    return succeed("{1} [don't|doesn't] have room for {2} and {2 he} drops to the ground.",
        actor, item);
  }
}

/// [Action] for using an [Item] from the [Hero]'s [Inventory] or the ground.
/// If the Item is equippable, then using it means equipping it.
class UseAction extends Action {
  final int index;
  final bool isOnGround;

  UseAction(this.index, this.isOnGround);

  ActionResult onPerform() {
    final item = isOnGround
        ? game.stage.itemsAt(actor.pos)[index]
        : hero.inventory[index];

    // If it's equippable, then using it just equips it.
    if (item.canEquip) {
      return alternate(new EquipAction(index, isOnGround));
    }

    if (!item.canUse) {
      return fail("{1} can't be used.", item);
    }

    if (isOnGround) {
      game.stage.removeItem(item);
    } else {
      hero.inventory.removeAt(index);
    }

    return alternate(item.use());
  }
}
