import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';
import 'item_view.dart';
import 'target_dialog.dart';

/// Modal dialog for letting the user perform an [Action] on an [Item]
/// accessible to the [Hero].
class ItemDialog extends Screen<Input> {
  final GameScreen _gameScreen;

  /// The command the player is trying to perform on an item.
  final _ItemCommand _command;

  /// The current location being shown to the player.
  ItemLocation _location = ItemLocation.inventory;

  /// If the player needs to select a quantity for an item they have already
  /// chosen, this will be the index of the item.
  Item _selectedItem;

  /// The number of items the player selected.
  int _count;

  /// Whether the shift key is currently pressed.
  bool _shiftDown = false;

  /// The current item being inspected or `null` if there is none.
  Item _inspected;

  bool get isTransparent => true;

  /// True if the item dialog supports tabbing between item lists.
  bool get canSwitchLocations => _command.allowedLocations.length > 1;

  ItemDialog.drop(this._gameScreen) : _command = _DropItemCommand();

  ItemDialog.use(this._gameScreen) : _command = _UseItemCommand();

  ItemDialog.toss(this._gameScreen) : _command = _TossItemCommand();

  ItemDialog.pickUp(this._gameScreen)
      : _command = _PickUpItemCommand(),
        _location = ItemLocation.onGround;

  ItemDialog.equip(this._gameScreen)
      : _command = _EquipItemCommand(),
        _location = ItemLocation.inventory;

  ItemDialog.sell(this._gameScreen, Inventory shop)
      : _command = _SellItemCommand(shop),
        _location = ItemLocation.inventory;

  ItemDialog.put(this._gameScreen)
      : _command = _PutItemCommand(),
        _location = ItemLocation.inventory;

  bool handleInput(Input input) {
    switch (input) {
      case Input.ok:
        if (_selectedItem != null) {
          _command.selectItem(this, _selectedItem, _count, _location);
          return true;
        }
        break;

      case Input.cancel:
        if (_selectedItem != null) {
          // Go back to selecting an item.
          _selectedItem = null;
          dirty();
        } else {
          ui.pop();
        }
        return true;

      case Input.n:
        if (_selectedItem != null) {
          if (_count < _selectedItem.count) {
            _count++;
            dirty();
          }
          return true;
        }
        break;

      case Input.s:
        if (_selectedItem != null) {
          if (_count > 1) {
            _count--;
            dirty();
          }
          return true;
        }
        break;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (keyCode == KeyCode.shift) {
      _shiftDown = true;
      dirty();
      return true;
    }

    if (alt) return false;

    // Can't switch view or select an item while selecting a count.
    if (_selectedItem != null) return false;

    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      _selectItem(keyCode - KeyCode.a);
      return true;
    }

    if (keyCode == KeyCode.tab && canSwitchLocations) {
      _advanceLocation(shift ? -1 : 1);
      dirty();
      return true;
    }

    return false;
  }

  bool keyUp(int keyCode, {bool shift, bool alt}) {
    if (keyCode == KeyCode.shift) {
      _shiftDown = false;
      dirty();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    var itemCount = 0;
    switch (_location) {
      case ItemLocation.inventory:
        itemCount = Option.inventoryCapacity;
        break;
      case ItemLocation.equipment:
        itemCount = _gameScreen.game.hero.equipment.slots.length;
        break;
      case ItemLocation.onGround:
        // TODO: Define this constant somewhere. Make the game engine try not
        // to place more than this many items per tile.
        itemCount = 5;
        break;
    }

    int itemsLeft;
    int itemsTop;
    int itemsWidth;
    if (_gameScreen.itemPanel.isVisible) {
      switch (_location) {
        case ItemLocation.inventory:
          itemsTop = _gameScreen.itemPanel.inventoryTop;
          break;
        case ItemLocation.equipment:
          itemsTop = _gameScreen.itemPanel.equipmentTop;
          break;
        case ItemLocation.onGround:
          if (_gameScreen.itemPanel.onGroundVisible) {
            itemsTop = _gameScreen.itemPanel.onGroundTop;
          } else {
            itemsTop = 0;
          }
          break;
      }

      // Always make it at least 2 wider than the item panel. That way, with
      // the letters, the items stay in the same position.
      itemsWidth = math.max(46, _gameScreen.itemPanel.bounds.width + 2);
      itemsLeft = terminal.width - itemsWidth;
    } else {
      itemsWidth = 46;
      itemsLeft = _gameScreen.stagePanel.bounds.right - itemsWidth;
      itemsTop = _gameScreen.stagePanel.bounds.y;
    }

    var itemView = _ItemDialogItemView(this);
    itemView
        .render(terminal.rect(itemsLeft, itemsTop, itemsWidth, itemCount + 2));

    String query;
    if (_selectedItem == null) {
      if (_shiftDown) {
        query = "Inspect which item?";
      } else {
        query = _command.query(_location);
      }
    } else {
      query = _command.queryCount(_location) + " $_count";
    }

    _renderHelp(terminal, query);

    if (_inspected != null) {
      var y = itemsTop + itemView.itemY(_inspected) + 1;
      y = y.clamp(0, terminal.height - 20);
      drawInspector(terminal.rect(itemsLeft - 34, y, 34, 20),
          _gameScreen.game.hero.save, _inspected);
    }
  }

  void _renderHelp(Terminal terminal, String query) {
    var helpKeys = <String, String>{};
    if (_selectedItem == null) {
      if (_shiftDown) {
        helpKeys["A-Z"] = "Inspect item";
      } else {
        helpKeys["A-Z"] = "Select item";
        helpKeys["Shift"] = "Inspect";
      }
    } else {
      helpKeys["↕"] = "Change quantity";
    }

    if (canSwitchLocations) {
      helpKeys["Tab"] = "Switch view";
    }

    Draw.helpKeys(terminal, helpKeys, query);
  }

  bool _canSelect(Item item) {
    if (_shiftDown) return true;

    if (_selectedItem != null) return item == _selectedItem;
    return _command.canSelect(item);
  }

  void _selectItem(int index) {
    var items = _getItems().slots.toList();
    if (index >= items.length) return;

    // Can't select an empty equipment slot.
    if (items[index] == null) return;

    if (_shiftDown) {
      _inspected = items[index];
      dirty();
    } else {
      if (!_command.canSelect(items[index])) return;

      if (items[index].count > 1 && _command.needsCount) {
        _selectedItem = items[index];
        _count = _selectedItem.count;
        dirty();
      } else {
        // Either we don't need a count or there's only one item.
        _command.selectItem(this, items[index], 1, _location);
      }
    }
  }

  ItemCollection _getItems() {
    switch (_location) {
      case ItemLocation.inventory:
        return _gameScreen.game.hero.inventory;
      case ItemLocation.equipment:
        return _gameScreen.game.hero.equipment;
      case ItemLocation.onGround:
        return _gameScreen.game.stage.itemsAt(_gameScreen.game.hero.pos);
    }

    throw "unreachable";
  }

  /// Rotates through the viewable locations the player can select an item from.
  void _advanceLocation(int offset) {
    var index = _command.allowedLocations.indexOf(_location);
    var count = _command.allowedLocations.length;
    _location = _command.allowedLocations[(index + count + offset) % count];
  }
}

class _ItemDialogItemView extends ItemView {
  final ItemDialog _dialog;

  ItemCollection get items => _dialog._getItems();

  bool get canSelectAny => true;

  bool get capitalize => _dialog._shiftDown;

  bool get showPrices => _dialog._command.showPrices;

  Item get inspectedItem => _dialog._inspected;

  bool canSelect(Item item) => _dialog._canSelect(item);

  int getPrice(Item item) => _dialog._command.getPrice(item);

  _ItemDialogItemView(this._dialog);

  void render(Terminal terminal) {
    Draw.frame(
        terminal, 0, 0, terminal.width, terminal.height, UIHue.selection);
    terminal.writeAt(2, 0, " ${items.name} ", UIHue.selection);

    super.render(terminal.rect(1, 1, terminal.width - 2, terminal.height - 2));
  }
}

/// The action the user wants to perform on the selected item.
abstract class _ItemCommand {
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

  /// The query shown to the user when selecting an item in this mode from
  /// [view].
  String query(ItemLocation location);

  /// The query shown to the user when selecting a quantity for an item in this
  /// mode from [view].
  String queryCount(ItemLocation location) => null;

  /// Returns `true` if [item] is a valid selection for this command.
  bool canSelect(Item item);

  /// Called when a valid item has been selected.
  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location);

  int getPrice(Item item) => item.price;

  void transfer(
      ItemDialog dialog, Item item, int count, ItemCollection destination) {
    if (!destination.canAdd(item)) {
      dialog._gameScreen.game.log
          .error("Not enough room for ${item.clone(count)}.");
      dialog.dirty();
      return;
    }

    if (count == item.count) {
      // Moving the entire stack.
      destination.tryAdd(item);
      dialog._getItems().remove(item);
    } else {
      // Splitting the stack.
      destination.tryAdd(item.splitStack(count));
      dialog._getItems().countChanged();
    }

    afterTransfer(dialog, item, count);
    dialog.ui.pop();
  }

  void afterTransfer(ItemDialog dialog, Item item, int count) {}
}

class _DropItemCommand extends _ItemCommand {
  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  bool get needsCount => true;

  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory:
        return 'Drop which item?';
      case ItemLocation.equipment:
        return 'Unequip and drop which item?';
    }

    throw "unreachable";
  }

  String queryCount(ItemLocation location) => 'Drop how many?';

  bool canSelect(Item item) => true;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    dialog._gameScreen.game.hero
        .setNextAction(DropAction(location, item, count));
    dialog.ui.pop();
  }
}

class _UseItemCommand extends _ItemCommand {
  bool get needsCount => false;

  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory:
      case ItemLocation.equipment:
        return 'Use which item?';
      case ItemLocation.onGround:
        return 'Pick up and use which item?';
    }

    throw "unreachable";
  }

  bool canSelect(Item item) => item.canUse;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    dialog._gameScreen.game.hero.setNextAction(UseAction(location, item));
    dialog.ui.pop();
  }
}

class _EquipItemCommand extends _ItemCommand {
  bool get needsCount => false;

  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory:
        return 'Equip which item?';
      case ItemLocation.equipment:
        return 'Unequip which item?';
      case ItemLocation.onGround:
        return 'Pick up and equip which item?';
    }

    throw "unreachable";
  }

  bool canSelect(Item item) => item.canEquip;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    dialog._gameScreen.game.hero.setNextAction(EquipAction(location, item));
    dialog.ui.pop();
  }
}

class _TossItemCommand extends _ItemCommand {
  bool get needsCount => false;

  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory:
        return 'Throw which item?';
      case ItemLocation.equipment:
        return 'Unequip and throw which item?';
      case ItemLocation.onGround:
        return 'Pick up and throw which item?';
    }

    throw "unreachable";
  }

  bool canSelect(Item item) => item.canToss;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    // Create the hit now so range modifiers can be calculated before the
    // target is chosen.
    var hit = item.toss.attack.createHit();
    dialog._gameScreen.game.hero.modifyHit(hit, HitType.toss);

    // Now we need a target.
    dialog.ui.goTo(TargetDialog(dialog._gameScreen, hit.range, (target) {
      dialog._gameScreen.game.hero
          .setNextAction(TossAction(location, item, hit, target));
    }));
  }
}

// TODO: It queries for a count. But if there is only a single item, the hero
// automatically picks up the whole stack. Should it do the same here?
class _PickUpItemCommand extends _ItemCommand {
  List<ItemLocation> get allowedLocations => const [ItemLocation.onGround];

  bool get needsCount => true;

  String query(ItemLocation location) => 'Pick up which item?';

  String queryCount(ItemLocation location) => 'Pick up how many?';

  bool canSelect(Item item) => true;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    // Pick up item and return to the game
    dialog._gameScreen.game.hero.setNextAction(PickUpAction(item));
    dialog.ui.pop();
  }
}

class _PutItemCommand extends _ItemCommand {
  _PutItemCommand();

  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  bool get needsCount => true;

  String query(ItemLocation location) => "Put which item?";

  String queryCount(ItemLocation location) => "Put how many?";

  bool canSelect(Item item) => true;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    transfer(dialog, item, count, dialog._gameScreen.game.hero.save.home);
  }

  void afterTransfer(ItemDialog dialog, Item item, int count) {
    dialog._gameScreen.game.log
        .message("You put ${item.clone(count)} safely into your home.");
  }
}

// TODO: Require confirmation when selling an item if it isn't a stack?
class _SellItemCommand extends _ItemCommand {
  final Inventory _shop;

  _SellItemCommand(this._shop);

  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  bool get needsCount => true;

  bool get showPrices => true;

  String query(ItemLocation location) => "Sell which item?";

  String queryCount(ItemLocation location) => "Sell how many?";

  bool canSelect(Item item) => true;

  int getPrice(Item item) => (item.price * 0.75).floor();

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    transfer(dialog, item, count, _shop);
  }

  void afterTransfer(ItemDialog dialog, Item item, int count) {
    var itemText = item.clone(count).toString();
    var price = getPrice(item) * count;
    // TODO: The help text overlaps the log pane, so this isn't very useful.
    dialog._gameScreen.game.log.message("You sell $itemText for $price gold.");
    dialog._gameScreen.game.hero.gold += price;
  }
}
