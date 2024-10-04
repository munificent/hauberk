import '../../engine/action/item.dart';
import '../../engine/action/toss.dart';
import '../../engine/core/combat.dart';
import '../../engine/items/inventory.dart';
import '../../engine/items/item.dart';
import '../target_dialog.dart';
import 'item_dialog.dart';

/// The action the user wants to perform on the selected item.
abstract class ItemCommand {
  /// Locations of items that can be used with this command. When a command
  /// allows multiple locations, players can switch between them.
  List<ItemLocation> get allowedLocations => const [
        ItemLocation.inventory,
        ItemLocation.onGround,
        ItemLocation.equipment
      ];

  /// If the player must select how many items in a stack, returns `true`.
  bool get needsCount;

  bool get showPrices => false;

  /// The verb to describe this command in the help bar.
  String get helpVerb;

  /// The query shown to the user when selecting an item in this mode from the
  /// [ItemDialog].
  String query(ItemLocation location);

  /// The query shown to the user when selecting a quantity for an item in this
  /// mode from the [ItemDialog].
  String queryCount(ItemLocation location) => throw UnimplementedError();

  /// Returns `true` if [item] is a valid selection for this command.
  bool canSelect(Item item);

  /// Called when a valid item has been selected.
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location);

  int getPrice(Item item) => item.price;

  void transfer(
      ItemDialog dialog, Item item, int count, ItemCollection destination) {
    if (!destination.canAdd(item)) {
      dialog.gameScreen.game.log
          .error("Not enough room for ${item.clone(count)}.");
      dialog.dirty();
      return;
    }

    if (count == item.count) {
      // Moving the entire stack.
      destination.tryAdd(item);
      dialog.items.remove(item);
    } else {
      // Splitting the stack.
      destination.tryAdd(item.splitStack(count));
      dialog.items.countChanged();
    }

    afterTransfer(dialog, item, count);
    dialog.ui.pop();
  }

  void afterTransfer(ItemDialog dialog, Item item, int count) {}
}

class DropItemCommand extends ItemCommand {
  @override
  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  @override
  bool get needsCount => true;

  @override
  String get helpVerb => "Drop";

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory => "Drop which item?",
      ItemLocation.equipment => "Unequip and drop which item?",
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  String queryCount(ItemLocation location) => 'Drop how many?';

  @override
  bool canSelect(Item item) => true;

  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    dialog.gameScreen.game.hero
        .setNextAction(DropAction(location, item, count));
    dialog.ui.pop();
  }
}

class UseItemCommand extends ItemCommand {
  @override
  bool get needsCount => false;

  @override
  String get helpVerb => "Use";

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory || ItemLocation.equipment => 'Use which item?',
      ItemLocation.onGround => 'Pick up and use which item?',
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  bool canSelect(Item item) => item.canUse;

  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    dialog.gameScreen.game.hero.setNextAction(UseAction(location, item));
    dialog.ui.pop();
  }
}

class EquipItemCommand extends ItemCommand {
  @override
  bool get needsCount => false;

  @override
  String get helpVerb => "Equip";

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory => 'Equip which item?',
      ItemLocation.equipment => 'Unequip which item?',
      ItemLocation.onGround => 'Pick up and equip which item?',
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  bool canSelect(Item item) => item.canEquip;

  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    dialog.gameScreen.game.hero.setNextAction(EquipAction(location, item));
    dialog.ui.pop();
  }
}

class TossItemCommand extends ItemCommand {
  @override
  bool get needsCount => false;

  @override
  String get helpVerb => "Toss";

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory => 'Throw which item?',
      ItemLocation.equipment => 'Unequip and throw which item?',
      ItemLocation.onGround => 'Pick up and throw which item?',
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  bool canSelect(Item item) => item.canToss;

  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    // Create the hit now so range modifiers can be calculated before the
    // target is chosen.
    var hit = item.toss!.attack.createHit();
    dialog.gameScreen.game.hero.modifyHit(hit, HitType.toss);

    // Now we need a target.
    dialog.ui.goTo(TargetDialog(dialog.gameScreen, hit.range, (target) {
      dialog.gameScreen.game.hero
          .setNextAction(TossAction(location, item, hit, target));
    }));
  }
}

// TODO: It queries for a count. But if there is only a single item, the hero
// automatically picks up the whole stack. Should it do the same here?
class PickUpItemCommand extends ItemCommand {
  @override
  List<ItemLocation> get allowedLocations => const [ItemLocation.onGround];

  @override
  bool get needsCount => true;

  @override
  String get helpVerb => "Pick up";

  @override
  String query(ItemLocation location) => 'Pick up which item?';

  @override
  String queryCount(ItemLocation location) => 'Pick up how many?';

  @override
  bool canSelect(Item item) => true;

  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    // Pick up item and return to the game
    dialog.gameScreen.game.hero.setNextAction(PickUpAction(item));
    dialog.ui.pop();
  }
}

abstract class _PutItemCommand extends ItemCommand {
  @override
  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  @override
  bool get needsCount => true;

  @override
  String get helpVerb => "Put";

  @override
  String query(ItemLocation location) => "Put which item?";

  @override
  String queryCount(ItemLocation location) => "Put how many?";

  @override
  bool canSelect(Item item) => true;
}

class PutCrucibleItemCommand extends _PutItemCommand {
  final void Function() _onTransfer;

  PutCrucibleItemCommand(this._onTransfer);

  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    transfer(dialog, item, count, dialog.gameScreen.game.hero.save.crucible);
  }

  @override
  void afterTransfer(ItemDialog dialog, Item item, int count) {
    dialog.gameScreen.game.log
        .message("You place ${item.clone(count)} into the crucible.");
    _onTransfer();
  }
}

class PutHomeItemCommand extends _PutItemCommand {
  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    transfer(dialog, item, count, dialog.gameScreen.game.hero.save.home);
  }

  @override
  void afterTransfer(ItemDialog dialog, Item item, int count) {
    dialog.gameScreen.game.log
        .message("You put ${item.clone(count)} safely into your home.");
  }
}

// TODO: Require confirmation when selling an item if it isn't a stack?
class SellItemCommand extends ItemCommand {
  final Inventory _shop;

  SellItemCommand(this._shop);

  @override
  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  @override
  bool get needsCount => true;

  @override
  bool get showPrices => true;

  @override
  String get helpVerb => "Sell";

  @override
  String query(ItemLocation location) => "Sell which item?";

  @override
  String queryCount(ItemLocation location) => "Sell how many?";

  @override
  bool canSelect(Item item) => item.price != 0;

  @override
  int getPrice(Item item) => (item.price * 0.75).floor();

  @override
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    transfer(dialog, item, count, _shop);
  }

  @override
  void afterTransfer(ItemDialog dialog, Item item, int count) {
    var itemText = item.clone(count).toString();
    var price = getPrice(item) * count;
    // TODO: The help text overlaps the log pane, so this isn't very useful.
    dialog.gameScreen.game.log.message("You sell $itemText for $price gold.");
    dialog.gameScreen.game.hero.gold += price;
  }
}
