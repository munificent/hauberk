import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'game_screen.dart';
import 'input.dart';
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

  bool get isTransparent => true;

  /// True if the item dialog supports tabbing between item lists.
  bool get canSwitchLocations => _command.allowedLocations.length > 1;

  ItemDialog.drop(this._gameScreen) : _command = new _DropItemCommand();
  ItemDialog.use(this._gameScreen) : _command = new _UseItemCommand();
  ItemDialog.toss(this._gameScreen) : _command = new _TossItemCommand();
  ItemDialog.pickUp(this._gameScreen)
      : _command = new _PickUpItemCommand(),
        _location = ItemLocation.onGround;
  ItemDialog.unequip(this._gameScreen)
      : _command = new _UseItemCommand(),
        _location = ItemLocation.equipment;

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
    if (shift || alt) return false;

    // Can't switch view or select an item while selecting a count.
    if (_selectedItem != null) return false;

    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      _selectItem(keyCode - KeyCode.a);
      return true;
    }

    if (keyCode == KeyCode.tab && canSwitchLocations) {
      _advanceLocation();
      dirty();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    // Draw a box for the contents.
    var itemCount = _getItems().length;
    var boxHeight = math.max(itemCount + 2, 3);
    var bar = "│" + (" " * 41) + "│";
    for (var y = 1; y < boxHeight + 1; y++) {
      terminal.writeAt(0, y, bar, steelGray);
    }

    terminal.writeAt(
        0, 0, "╒═════════════════════════════════════════╕", steelGray);
    terminal.writeAt(
        0, boxHeight, "└─────────────────────────────────────────┘", steelGray);

    if (_selectedItem == null) {
      terminal.writeAt(1, 0, _command.query(_location), UIHue.selection);
    } else {
      var query = _command.queryCount(_location);
      terminal.writeAt(1, 0, query, UIHue.text);
      terminal.writeAt(query.length + 2, 0, _count.toString(), UIHue.selection);
    }

    var select =
        _selectedItem == null ? '[A-Z] Select item' : '[↕] Change quantity';
    var helpText = canSwitchLocations ? ', [Tab] Switch view' : '';

    terminal.writeAt(
        0, terminal.height - 1, '$select$helpText', UIHue.helpText);

    if (itemCount > 0) {
      if (_location == ItemLocation.equipment) {
        drawEquipment(
            terminal, 1, 2, _gameScreen.game.hero.equipment, _canSelect);
      } else {
        drawItems(terminal, 1, 2, _getItems(), _canSelect);
      }
    } else {
      String message;
      switch (_location) {
        case ItemLocation.inventory:
          message = "(Your backpack is empty.)";
          break;

        case ItemLocation.equipment:
          assert(false, "Equipment list is never empty.");
          break;

        case ItemLocation.onGround:
          message = "(There is nothing on the ground.)";
          break;
      }

      terminal.writeAt(1, 2, message, UIHue.disabled);
    }
  }

  bool _canSelect(Item item) {
    if (_selectedItem != null) return item == _selectedItem;
    return _command.canSelect(item);
  }

  void _selectItem(int index) {
    var items = _getItems().toList();
    if (index >= items.length) return;

    // Can't select an empty equipment slot.
    if (items[index] == null) return;

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

  Iterable<Item> _getItems() {
    switch (_location) {
      case ItemLocation.inventory:
        return _gameScreen.game.hero.inventory;
      case ItemLocation.equipment:
        return _gameScreen.game.hero.equipment.slots;
      case ItemLocation.onGround:
        return _gameScreen.game.stage.itemsAt(_gameScreen.game.hero.pos);
    }

    throw "unreachable";
  }

  /// Rotates through the viewable locations the player can select an item from.
  void _advanceLocation() {
    var index = _command.allowedLocations.indexOf(_location);
    _location = _command
        .allowedLocations[(index + 1) % _command.allowedLocations.length];
  }
}

void drawEquipment(Terminal terminal, int x, int y, Equipment equipment,
    [bool canSelect(Item item)]) {
  _drawItems(terminal, x, y, equipment.slots, equipment.slotTypes, canSelect);
}

/// Draws a list of [items] on [terminal] at [x], [y].
///
/// This is used both on the [ItemScreen] and in game for things like using and
/// dropping items.
///
/// Items can be drawn in one of three states:
///
/// * If [canSelect] is `null`, then item list is just being viewed and no
///   items in particular are highlighted.
/// * If [canSelect] returns `true`, the item is highlighted as being
///   selectable.
/// * If [canSelect] returns `false`, the item cannot be selected and is
///   grayed out.
///
/// An item row looks like this:
///               1         2         3         4
///     01234567890123456789012345678901234567890123456789
///     a) = a Glimmering War Hammer of Wo... »29 992,106
void drawItems(Terminal terminal, int x, int y, Iterable<Item> items,
    [bool canSelect(Item item)]) {
  _drawItems(terminal, x, y, items, null, canSelect);
}

void _drawItems(Terminal terminal, int x, int y, Iterable<Item> items,
    List<String> slotNames, bool canSelect(Item item)) {
  var i = 0;
  var letter = 0;
  for (var item in items) {
    var itemY = y + i;

    // If there's no item in this equipment slot, show the slot name.
    if (item == null) {
      // Null items should only appear in equipment.
      assert(slotNames != null);

      terminal.writeAt(x, itemY, "    (${slotNames[i]})", UIHue.helpText);
      letter++;
      i++;
      continue;
    }

    var borderColor = steelGray;
    var letterColor = UIHue.secondary;
    var textColor = UIHue.primary;
    var enabled = true;

    if (canSelect != null) {
      if (canSelect(item)) {
        borderColor = UIHue.secondary;
        letterColor = UIHue.selection;
        textColor = UIHue.primary;
      } else {
        borderColor = Color.black;
        letterColor = Color.black;
        textColor = UIHue.disabled;
        enabled = false;
      }
    }

    terminal.writeAt(x, itemY, " )", borderColor);
    terminal.writeAt(
        x, itemY, "abcdefghijklmnopqrstuvwxyz"[letter], letterColor);
    letter++;

    if (enabled) {
      terminal.drawGlyph(x + 2, itemY, item.appearance);
    }

    terminal.writeAt(x + 4, itemY, item.nounText, textColor);

    drawStat(String symbol, Object stat, Color light, Color dark) {
      var string = stat.toString();
      terminal.writeAt(x + 40 - string.length, itemY, symbol,
          enabled ? dark : UIHue.disabled);
      terminal.writeAt(x + 41 - string.length, itemY, string,
          enabled ? light : UIHue.disabled);
    }

    // TODO: Eventually need to handle equipment that gives both an armor and
    // attack bonus.
    if (item.attack != null) {
      var hit = item.attack.createHit();
      drawStat("»", hit.damageString, carrot, garnet);
    } else if (item.armor != 0) {
      drawStat("•", item.armor, peaGreen, sherwood);
    }

    // TODO: Show heft and weight.
    i++;
  }
}

/// The action the user wants to perform on the selected item.
abstract class _ItemCommand {
  /// Locations of items that can be used with this command. When a command
  /// allows multiple locations, players can switch between them.
  List<ItemLocation> get allowedLocations => const [
        ItemLocation.inventory,
        ItemLocation.equipment,
        ItemLocation.onGround
      ];

  /// If the player must select how many items in a stack, returns `true`.
  bool get needsCount;

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
        .setNextAction(new DropAction(location, item, count));
    dialog.ui.pop();
  }
}

class _UseItemCommand extends _ItemCommand {
  bool get needsCount => false;

  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory:
        return 'Use or equip which item?';
      case ItemLocation.equipment:
        return 'Unequip which item?';
      case ItemLocation.onGround:
        return 'Pick up and use which item?';
    }

    throw "unreachable";
  }

  bool canSelect(Item item) => item.canUse || item.canEquip;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    dialog._gameScreen.game.hero.setNextAction(new UseAction(location, item));
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
    dialog.ui.goTo(new TargetDialog(dialog._gameScreen, hit.range, (target) {
      dialog._gameScreen.game.hero
          .setNextAction(new TossAction(location, item, hit, target));
    }));
  }
}

class _PickUpItemCommand extends _ItemCommand {
  List<ItemLocation> get allowedLocations => const [ItemLocation.onGround];

  bool get needsCount => true;

  String query(ItemLocation location) => 'Pick up which item?';

  String queryCount(ItemLocation location) => 'Pick up how many?';

  bool canSelect(Item item) => true;

  void selectItem(
      ItemDialog dialog, Item item, int count, ItemLocation location) {
    // Pick up item and return to the game
    dialog._gameScreen.game.hero.setNextAction(new PickUpAction(item));
    dialog.ui.pop();
  }
}
