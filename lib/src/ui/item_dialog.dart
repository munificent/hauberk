library hauberk.ui.item_dialog;

import 'package:malison/malison.dart';

import '../engine.dart';
import 'game_screen.dart';
import 'input.dart';
import 'target_dialog.dart';

/// Modal dialog for letting the user perform an [Action] on an [Item]
/// accessible to the [Hero].
class ItemDialog extends Screen {
  final GameScreen _gameScreen;

  /// The command the player is trying to perform on an item.
  final _ItemCommand _command;

  /// The current location being shown to the player.
  ItemLocation _location = ItemLocation.inventory;

  bool get isTransparent => true;

  /// True if the item dialog supports tabbing between item lists.
  bool get canSwitchLocations => _command.allowedLocations.length > 1;

  ItemDialog.drop(this._gameScreen) : _command = new _DropItemCommand();
  ItemDialog.use(this._gameScreen) : _command = new _UseItemCommand();
  ItemDialog.toss(this._gameScreen) : _command = new _TossItemCommand();
  ItemDialog.pickUp(this._gameScreen) :
    _command = new _PickUpItemCommand(), _location = ItemLocation.onGround;

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

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
    terminal.writeAt(0, 0, _command.query(_location));

    terminal.rect(0, terminal.height - 2, terminal.width, 2).clear();

    String selectItem = '[A-Z] Select item';
    String helpText = canSwitchLocations ? ', [Tab] Switch view' : '';

    terminal.writeAt(0, terminal.height - 1,
        '$selectItem$helpText',
        Color.gray);

    drawItems(terminal, 0, 1, _getItems(), (item) => _command.canSelect(item));
  }

  void _selectItem(int index) {
    var items = _getItems().toList();
    if (index >= items.length) return;
    if (!_command.canSelect(items[index])) return;

    _command.selectItem(this, items[index], _location, index);
  }

  Iterable<Item> _getItems() {
    switch (_location) {
      case ItemLocation.inventory: return _gameScreen.game.hero.inventory;
      case ItemLocation.equipment: return _gameScreen.game.hero.equipment;
      case ItemLocation.onGround:
        return _gameScreen.game.stage.itemsAt(_gameScreen.game.hero.pos);
    }

    throw "unreachable";
  }

  /// Rotates through the viewable locations the player can select an item from.
  void _advanceLocation() {
    var index = _command.allowedLocations.indexOf(_location);
    _location = _command.allowedLocations[(index + 1) % _command.allowedLocations.length];
  }
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
  var i = 0;
  for (var item in items) {
    var itemY = i + y;

    var borderColor = Color.darkGray;
    var letterColor = Color.gray;
    var textColor = Color.white;
    var priceColor = Color.gray;
    var enabled = true;

    if (canSelect != null) {
      if (canSelect(item)) {
        borderColor = Color.gray;
        letterColor = Color.yellow;
        textColor = Color.white;
        priceColor = Color.gold;
      } else {
        borderColor = Color.black;
        letterColor = Color.black;
        textColor = Color.darkGray;
        priceColor = Color.darkGray;
        enabled = false;
      }
    }

    terminal.writeAt(x, itemY,
        " )                                               ", borderColor);
    terminal.writeAt(x, itemY, "abcdefghijklmnopqrstuvwxyz"[i], letterColor);

    if (enabled) {
      terminal.drawGlyph(x + 3, itemY, item.appearance);
    }

    var text = item.nounText;
    if (text.length > 32) {
      text = text.substring(0, 29) + "...";
    }
    terminal.writeAt(x + 5, itemY, text, textColor);

    drawStat(String symbol, Object stat, Color light, Color dark) {
      var string = stat.toString();
      terminal.writeAt(x + 40 - string.length, itemY, symbol,
          enabled ? dark : Color.darkGray);
      terminal.writeAt(x + 41 - string.length, itemY, string,
          enabled ? light : Color.darkGray);
    }

    // TODO: Eventually need to handle equipment that gives both an armor and
    // attack bonus.
    if (item.attack != null) {
      drawStat("»", item.attack.averageDamage.toInt(), Color.orange,
          Color.darkOrange);
    } else if (item.armor != 0) {
      drawStat("•", item.armor, Color.green, Color.darkGreen);
    }

    if (item.price != 0) {
      var price = priceString(item.price);
      terminal.writeAt(x + 49 - price.length, itemY, price, priceColor);
    }

    i++;
  }
}

/// Converts an integer to a comma-grouped string like "123,456".
String priceString(int price) {
  var result = price.toString();
  if (price > 999999999) {
    result = result.substring(0, result.length - 9) + "," +
        result.substring(result.length - 9);
  }

  if (price > 999999) {
    result = result.substring(0, result.length - 6) + "," +
        result.substring(result.length - 6);
  }

  if (price > 999) {
    result = result.substring(0, result.length - 3) + "," +
        result.substring(result.length - 3);
  }

  return result;
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

  /// The query shown to the user when selecting an item in this mode from
  /// [view].
  String query(ItemLocation location);

  /// Returns `true` if [item] is a valid selection for this command.
  bool canSelect(Item item);

  /// Called when a valid item has been selected.
  void selectItem(ItemDialog dialog, Item item,
      ItemLocation location, int index);
}

class _DropItemCommand extends _ItemCommand {
  List<ItemLocation> get allowedLocations => const [
    ItemLocation.inventory,
    ItemLocation.equipment
  ];

  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory: return 'Drop which item?';
      case ItemLocation.equipment: return 'Unequip and drop which item?';
    }

    throw "unreachable";
  }

  bool canSelect(Item item) => true;

  void selectItem(ItemDialog dialog, Item item,
      ItemLocation location, int index) {
    dialog._gameScreen.game.hero.setNextAction(new DropAction(location, index));
    dialog.ui.pop();
  }
}

class _UseItemCommand extends _ItemCommand {
  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory: return 'Use or equip which item?';
      case ItemLocation.equipment: return 'Unequip which item?';
      case ItemLocation.onGround: return 'Pick up and use which item?';
    }

    throw "unreachable";
  }

  bool canSelect(Item item) => item.canUse || item.canEquip;

  void selectItem(ItemDialog dialog, Item item,
      ItemLocation location, int index) {
    dialog._gameScreen.game.hero.setNextAction(new UseAction(location, index));
    dialog.ui.pop();
  }
}

class _TossItemCommand extends _ItemCommand {
  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.inventory: return 'Throw which item?';
      case ItemLocation.equipment: return 'Unequip and throw which item?';
      case ItemLocation.onGround: return 'Pick up and throw which item?';
    }

    throw "unreachable";
  }

  bool canSelect(Item item) => item.canToss;

  void selectItem(ItemDialog dialog, Item item,
      ItemLocation location, int index) {
    // Now we need a target.
    dialog.ui.goTo(new TargetDialog(dialog._gameScreen,
        item.type.tossAttack.range, (target) {
      dialog._gameScreen.game.hero.setNextAction(
          new TossAction(location, index, target));
    }));
  }
}

class _PickUpItemCommand extends _ItemCommand {
  List<ItemLocation> get allowedLocations => const [
    ItemLocation.onGround
  ];

  String query(ItemLocation location) => 'Pick up which item?';

  bool canSelect(Item item) => true;

  void selectItem(ItemDialog dialog, Item item,
      ItemLocation location, int index) {
    // Pick up item and return to the game
    dialog._gameScreen.game.hero.setNextAction(
      new PickUpAction(index)
    );
    dialog.ui.pop();
  }
}
