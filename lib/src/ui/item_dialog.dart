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
  ItemLocation _location = ItemLocation.INVENTORY;

  bool get isTransparent => true;

  /// True if the item dialog supports tabbing between item lists.
  bool get canSwitchLocations => _command.allowedLocations.length > 1;

  ItemDialog.drop(this._gameScreen) : _command = new _DropItemCommand();
  ItemDialog.use(this._gameScreen) : _command = new _UseItemCommand();
  ItemDialog.toss(this._gameScreen) : _command = new _TossItemCommand();
  ItemDialog.pickUp(this._gameScreen) :
    _command = new _PickUpItemCommand(), _location = ItemLocation.ON_GROUND;

  bool handleInput(Input input) {
    if (input == Input.CANCEL) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode >= KeyCode.A && keyCode <= KeyCode.Z) {
      _selectItem(keyCode - KeyCode.A);
      return true;
    }

    if (keyCode == KeyCode.TAB && canSwitchLocations) {
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
        Color.GRAY);

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
      case ItemLocation.INVENTORY: return _gameScreen.game.hero.inventory;
      case ItemLocation.EQUIPMENT: return _gameScreen.game.hero.equipment;
      case ItemLocation.ON_GROUND:
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

// TODO: Move to separate file?
void drawItems(Terminal terminal, int x, int y, Iterable<Item> items,
    bool canSelect(Item item)) {
  var i = 0;
  for (var item in items) {
    var itemY = i + y;

    var borderColor = Color.GRAY;
    var letterColor = Color.YELLOW;
    var textColor = Color.WHITE;
    if (!canSelect(item)) {
      borderColor = Color.DARK_GRAY;
      letterColor = Color.GRAY;
      textColor = Color.GRAY;
    }

    terminal.writeAt(x, itemY, '( )   ', borderColor);
    terminal.writeAt(x + 1, itemY, 'abcdefghijklmnopqrstuvwxyz'[i], letterColor);
    terminal.drawGlyph(x + 4, itemY, item.appearance);
    terminal.writeAt(x + 6, itemY, item.nounText, textColor);
    i++;
  }
}

/// The action the user wants to perform on the selected item.
abstract class _ItemCommand {
  /// Locations of items that can be used with this command. When a command
  /// allows multiple locations, players can switch between them.
  List<ItemLocation> get allowedLocations => const [
    ItemLocation.INVENTORY,
    ItemLocation.EQUIPMENT,
    ItemLocation.ON_GROUND
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
    ItemLocation.INVENTORY,
    ItemLocation.EQUIPMENT
  ];

  String query(ItemLocation location) {
    switch (location) {
      case ItemLocation.INVENTORY: return 'Drop which item?';
      case ItemLocation.EQUIPMENT: return 'Unequip and drop which item?';
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
      case ItemLocation.INVENTORY: return 'Use or equip which item?';
      case ItemLocation.EQUIPMENT: return 'Unequip which item?';
      case ItemLocation.ON_GROUND: return 'Pick up and use which item?';
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
      case ItemLocation.INVENTORY: return 'Throw which item?';
      case ItemLocation.EQUIPMENT: return 'Unequip and throw which item?';
      case ItemLocation.ON_GROUND: return 'Pick up and throw which item?';
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
    ItemLocation.ON_GROUND
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
