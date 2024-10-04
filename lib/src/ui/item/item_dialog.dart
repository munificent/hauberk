import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../../engine.dart';
import '../draw.dart';
import '../game_screen.dart';
import '../input.dart';
import 'item_command.dart';
import 'item_renderer.dart';

/// Modal dialog for letting the user perform an [Action] on an [Item]
/// accessible to the [Hero].
///
/// This overlays an item panel on the right side of the main screen and makes
/// it look like one of those panels has become active.
class ItemDialog extends Screen<Input> {
  final GameScreen gameScreen;

  /// The command the player is trying to perform on an item.
  final ItemCommand _command;

  /// The current location being shown to the player.
  ItemLocation _location = ItemLocation.inventory;

  /// If the player needs to select a quantity for an item they have already
  /// chosen, this will be the index of the item.
  Item? _selectedItem;

  /// The number of items the player selected.
  int _count = -1;

  /// Whether the shift key is currently pressed.
  bool _shiftDown = false;

  /// The current item being inspected or `null` if there is none.
  Item? _inspected;

  @override
  bool get isTransparent => true;

  /// True if the item dialog supports tabbing between item lists.
  bool get canSwitchLocations => _command.allowedLocations.length > 1;

  ItemDialog.drop(this.gameScreen) : _command = DropItemCommand();

  ItemDialog.use(this.gameScreen) : _command = UseItemCommand();

  ItemDialog.toss(this.gameScreen) : _command = TossItemCommand();

  ItemDialog.pickUp(this.gameScreen)
      : _command = PickUpItemCommand(),
        _location = ItemLocation.onGround;

  ItemDialog.equip(this.gameScreen) : _command = EquipItemCommand();

  ItemDialog.sell(this.gameScreen, Inventory shop)
      : _command = SellItemCommand(shop);

  ItemDialog.putCrucible(this.gameScreen, void Function() onTransfer)
      : _command = PutCrucibleItemCommand(onTransfer);

  ItemDialog.putHome(this.gameScreen) : _command = PutHomeItemCommand();

  ItemCollection get items {
    var hero = gameScreen.game.hero;
    return switch (_location) {
      ItemLocation.inventory => hero.inventory,
      ItemLocation.equipment => hero.equipment,
      ItemLocation.onGround => gameScreen.game.stage.itemsAt(hero.pos),
      _ => throw StateError("Unexpected location."),
    };
  }

  @override
  bool handleInput(Input input) {
    if (_selectedItem case var selected?) {
      switch (input) {
        case Input.ok:
          _command.selectItem(this, selected, _count, _location);
          return true;

        case Input.cancel:
          // Go back to selecting an item.
          _selectedItem = null;
          dirty();
          return true;

        case Input.n when _count < selected.count:
          _count++;
          dirty();
          return true;

        case Input.s when _count > 1:
          _count--;
          dirty();
          return true;
      }
    } else if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (keyCode == KeyCode.shift) {
      _shiftDown = true;
      dirty();
      return true;
    }

    if (alt) return false;

    if (_shiftDown && keyCode == KeyCode.escape) {
      _inspected = null;
      dirty();
      return true;
    }

    // Can't switch view or select an item while selecting a count.
    if (_selectedItem != null) return false;

    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      _selectItem(keyCode - KeyCode.a);
      return true;
    }

    if (keyCode == KeyCode.tab && !_shiftDown && canSwitchLocations) {
      _advanceLocation(shift ? -1 : 1);
      dirty();
      return true;
    }

    return false;
  }

  @override
  bool keyUp(int keyCode, {required bool shift, required bool alt}) {
    if (keyCode == KeyCode.shift) {
      _shiftDown = false;
      dirty();
      return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal) {
    var itemCount = 0;
    switch (_location) {
      case ItemLocation.inventory:
        itemCount = Option.inventoryCapacity;
      case ItemLocation.equipment:
        itemCount = gameScreen.game.hero.equipment.slots.length;
      case ItemLocation.onGround:
        // TODO: Define this constant somewhere. Make the game engine try not
        // to place more than this many items per tile.
        itemCount = 5;
    }

    int itemsLeft;
    int itemsTop;
    int itemsWidth;
    if (gameScreen.itemPanel.isVisible) {
      itemsTop = switch (_location) {
        ItemLocation.inventory => gameScreen.itemPanel.inventoryTop,
        ItemLocation.equipment => gameScreen.itemPanel.equipmentTop,
        ItemLocation.onGround when gameScreen.itemPanel.onGroundVisible =>
          gameScreen.itemPanel.onGroundTop,
        ItemLocation.onGround => 0,
        _ => throw StateError("Unexpected location."),
      };

      // Always make it at least 2 wider than the item panel. That way, with
      // the letters, the items stay in the same position.
      itemsWidth = math.max(
          preferredItemListWidth, gameScreen.itemPanel.bounds.width + 2);
      itemsLeft = terminal.width - itemsWidth;
    } else {
      itemsWidth = preferredItemListWidth;
      itemsLeft = gameScreen.stagePanel.bounds.right - itemsWidth;
      itemsTop = gameScreen.stagePanel.bounds.y;
    }

    renderItems(terminal, items,
        left: itemsLeft,
        top: itemsTop,
        width: itemsWidth,
        itemSlotCount: itemCount,
        save: gameScreen.game.hero.save,
        canSelectAny: true,
        capitalize: _selectedItem == null && _shiftDown,
        showPrices: _command.showPrices,
        inspectedItem: _inspected,
        canSelect: _canSelect,
        getPrice: _command.getPrice);

    String query;
    if (_selectedItem == null) {
      if (_shiftDown) {
        query = "Inspect which item?";
      } else {
        query = _command.query(_location);
      }
    } else {
      query = "${_command.queryCount(_location)} $_count";
    }

    _renderHelp(terminal, query);
  }

  void _renderHelp(Terminal terminal, String query) {
    Map<String, String> helpKeys;
    if (_selectedItem == null) {
      if (_shiftDown) {
        helpKeys = {
          "A-Z": "Inspect item",
          if (_inspected != null) "`": "Hide inspector"
        };
      } else {
        helpKeys = {
          "A-Z": "Select item",
          "Shift": "Inspect item",
          if (canSwitchLocations) "Tab": "Switch view"
        };
      }
    } else {
      helpKeys = {
        "OK": _command.helpVerb,
        "↕": "Change quantity",
        "`": "Cancel"
      };
    }

    Draw.helpKeys(terminal, helpKeys, query);
  }

  bool _canSelect(Item item) {
    if (_shiftDown && _selectedItem == null) return true;

    if (_selectedItem != null) return item == _selectedItem;
    return _command.canSelect(item);
  }

  void _selectItem(int index) {
    var items = this.items.slots.toList();
    if (index >= items.length) return;

    // Can't select an empty equipment slot.
    var item = items[index];
    if (item == null) return;

    if (_shiftDown) {
      _inspected = item;
      dirty();
    } else {
      if (!_command.canSelect(item)) return;

      if (item.count > 1 && _command.needsCount) {
        _selectedItem = item;
        _inspected = null;
        _count = item.count;
        dirty();
      } else {
        // Either we don't need a count or there's only one item.
        _command.selectItem(this, item, 1, _location);
      }
    }
  }

  /// Rotates through the viewable locations the player can select an item from.
  void _advanceLocation(int offset) {
    var index = _command.allowedLocations.indexOf(_location);
    var count = _command.allowedLocations.length;
    _location = _command.allowedLocations[(index + count + offset) % count];
  }
}
