/// [Action] for picking up an [Item] off the ground.
class PickUpAction extends Action {
  ActionResult onPerform() {
    final item = game.level.itemAt(actor.pos);
    if (item == null) {
      return fail('There is nothing here.');
    }

    if (!hero.inventory.tryAdd(item)) {
      return fail("{1} [don't|doesn't] have room for {2}.", actor, item);
    }

    // Remove it from the level.
    // TODO(bob): Hackish.
    for (var i = 0; i < game.level.items.length; i++) {
      if (game.level.items[i] == item) {
        game.level.items.removeRange(i, 1);
        break;
      }
    }

    return succeed('{1} pick[s] up {2}.', actor, item);
  }
}

/// [Action] for dropping an [Item] from the [Hero]'s [Inventory] onto the
/// ground.
class DropAction extends Action {
  final int index;

  DropAction(this.index);

  ActionResult onPerform() {
    final item = hero.inventory.remove(index);
    item.pos = hero.pos;
    game.level.items.add(item);

    return succeed('{1} drop[s] {2}.', actor, item);
  }
}

/// [Action] for moving an [Item] from the [Hero]'s [Inventory] to his
/// [Equipment]. May cause a currently equipped Item to become unequipped. If
/// there is no room in the Inventory for that Item, it will drop to the ground.
class EquipAction extends Action {
  final int index;

  EquipAction(this.index);

  ActionResult onPerform() {
    final item = hero.inventory[index];

    if (!hero.equipment.canEquip(item)) {
      return fail('{1} cannot equip {2}.', actor, item);
    }

    final unequipped = hero.equipment.equip(item);
    hero.inventory.remove(index);

    // Add the previously equipped item to inventory.
    if (unequipped != null) {
      if (hero.inventory.tryAdd(unequipped)) {
        game.log.add('{1} unequip[s] {2}.', actor, unequipped);
      } else {
        // No room in inventory, so drop it.
        item.pos = hero.pos;
        game.level.items.add(item);
        game.log.add("{1} [don't|doesn't] have room for {2} and {2 he} drops to the ground.",
          actor, unequipped);
      }
    }

    return succeed('{1} equip[s] {2}.', actor, item);
  }
}

/// [Action] for using an [Item]. If the Item is equippable, then using it
/// means equipping it.
class UseAction extends Action {
  // TODO(bob): Right now, it assumes you always use an inventory item. May
  // want to support using items on the ground at some point.
  final int index;

  UseAction(this.index);

  ActionResult onPerform() {
    final item = hero.inventory[index];

    // If it's equippable, then using it just equips it.
    if (item.canEquip) {
      return alternate(new EquipAction(index));
    }

    final use = item.use;
    if (use == null) {
      return fail("{1} can't be used.", item);
    }

    hero.inventory.remove(index);
    use(game, this);

    return succeed();
  }
}
