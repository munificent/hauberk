import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';
import 'item_dialog.dart';
import 'item_view.dart';

// TODO: Home screen is confusing when empty.
// TODO: The home (get) and shop (buy) screens handle selecting a count
// completely differently from the ItemDialogs (put, sell, etc.). Different
// code and different user interface. Unify those.

abstract class ItemScreen extends Screen<Input> {
  final GameScreen _gameScreen;

  /// The place items are being transferred to or `null` if this is just a
  /// view.
  ItemCollection get _destination => null;

  /// Whether the shift key is currently pressed.
  bool _shiftDown = false;

  /// Whether this screen is on top.
  // TODO: Maintaining this manually is hacky. Maybe have malison expose it?
  bool _isActive = true;

  /// The item currently being inspected or `null` if none.
  Item _inspected;

//  /// If the crucible contains a complete recipe, this will be it. Otherwise,
//  /// this will be `null`.
//  Recipe completeRecipe;

  String _error;

  ItemCollection get _items;

  HeroSave get _save => _gameScreen.game.hero.save;

  String get _headerText;

  String get _verb => throw "Subclass should implement";

  Map<String, String> get _helpKeys;

  ItemScreen._(this._gameScreen);

  bool get isTransparent => true;

  factory ItemScreen.home(GameScreen gameScreen) => _HomeViewScreen(gameScreen);

  factory ItemScreen.shop(GameScreen gameScreen, Inventory shop) =>
      _ShopViewScreen(gameScreen, shop);

  bool get _canSelectAny => false;
  bool get _showPrices => false;

  bool _canSelect(Item item) {
    if (_shiftDown) return true;

    return canSelect(item);
  }

  bool canSelect(Item item) => true;

  bool handleInput(Input input) {
    _error = null;

    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    _error = null;

    if (keyCode == KeyCode.shift) {
      _shiftDown = true;
      dirty();
      return true;
    }

    if (alt) return false;

//    if (keyCode == KeyCode.space && completeRecipe != null) {
//      _save.crucible.clear();
//      completeRecipe.result.spawnDrop(_save.crucible.tryAdd);
//      refreshRecipe();
//
//      // The player probably wants to get the item out of the crucible.
//      _mode = Mode.get;
//      dirty();
//      return true;
//    }

    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      var index = keyCode - KeyCode.a;
      if (index >= _items.slots.length) return false;
      var item = _items.slots.elementAt(index);
      if (item == null) return false;

      if (_shiftDown) {
        _inspected = item;
        dirty();
      } else {
        if (!_canSelectAny || !canSelect(item)) return false;

        // Prompt the user for a count if the item is a stack.
        if (item.count > 1) {
          _isActive = false;
          ui.push(_CountScreen(_gameScreen, this, item));
          return true;
        }

        if (_transfer(item, 1)) {
          ui.pop();
          return true;
        }
      }
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

  void activate(Screen<Input> popped, Object result) {
    _isActive = true;
    _inspected = null;

    if (popped is _CountScreen && result != null) {
      if (_transfer(popped._item, result)) {
        ui.pop();
      }
    }
  }

  void render(Terminal terminal) {
    // Don't show the help if another dialog (like buy or sell) is on top with
    // its own help.
    if (_isActive) {
      Draw.helpKeys(terminal, _shiftDown ? {"A-Z": "Inspect item"} : _helpKeys,
          _shiftDown ? "Inspect which item?" : _headerText);
    }

    terminal = terminal.rect(
        _gameScreen.stagePanel.bounds.x,
        _gameScreen.stagePanel.bounds.y,
        _gameScreen.stagePanel.bounds.width,
        _gameScreen.stagePanel.bounds.height);

    Draw.frame(terminal, 0, 0, terminal.width - 34, _items.length + 2,
        _canSelectAny ? UIHue.selection : UIHue.disabled);
    terminal.writeAt(
        2, 0, " ${_items.name} ", _canSelectAny ? UIHue.selection : UIHue.text);

    var view = _TownItemView(this);
    view.render(terminal.rect(1, 1, terminal.width - 36, terminal.height - 5));

    if (_inspected != null) {
      var y = view.itemY(_inspected) + 1;
      y = y.clamp(0, terminal.height - 20);

      drawInspector(
          terminal.rect(terminal.width - 34, y, 34, 20), _save, _inspected);
    }

//    if (completeRecipe != null) {
//      terminal.writeAt(59, 2, "Press [Space] to forge item!", UIHue.selection);
//
//      var itemCount = _place.items(this).length;
//      for (var i = 0; i < completeRecipe.produces.length; i++) {
//        terminal.writeAt(50, itemCount + i + 4,
//            completeRecipe.produces.elementAt(i), UIHue.text);
//      }
//    }

    if (_error != null) {
      terminal.writeAt(0, 32, _error, brickRed);
    }
  }

  /// The default count to move when transferring a stack from [_items].
  int _initialCount(Item item) => item.count;

  /// The maximum number of items in the stack of [item] that can be
  /// transferred from [_items].
  int _maxCount(Item item) => item.count;

  /// By default, don't show the price.
  int _itemPrice(Item item) => null;

  bool _transfer(Item item, int count) {
    if (!_destination.canAdd(item)) {
      _error = "Not enough room for ${item.clone(count)}.";
      dirty();
      return false;
    }

    if (count == item.count) {
      // Moving the entire stack.
      _destination.tryAdd(item);
      _items.remove(item);
    } else {
      // Splitting the stack.
      _destination.tryAdd(item.splitStack(count));
      _items.countChanged();
    }

    _afterTransfer(item, count);
    // TODO
//    } else if (_place == _Place.crucible) {
//      refreshRecipe();
//    }

    return true;
  }

  /// Called after [count] of [item] has been transferred out of [_items].
  void _afterTransfer(Item item, int count) {}
}

class _TownItemView extends ItemView {
  final ItemScreen _screen;

  _TownItemView(this._screen);

  ItemCollection get items => _screen._items;

  bool get capitalize => _screen._shiftDown;

  bool get showPrices => _screen._showPrices;

  Item get inspectedItem => _screen._inspected;

  bool get canSelectAny => _screen._shiftDown || _screen._canSelectAny;

  bool canSelect(Item item) => _screen._canSelect(item);

  int getPrice(Item item) => _screen._itemPrice(item);
}

class _HomeViewScreen extends ItemScreen {
  ItemCollection get _items => _save.home;

  String get _headerText => "Welcome home!";

  Map<String, String> get _helpKeys => {
        "G": "Get item",
        "P": "Put item",
        "Shift": "Inspect item",
        "Esc": "Leave"
      };

  _HomeViewScreen(GameScreen gameScreen) : super._(gameScreen);

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (super.keyDown(keyCode, shift: shift, alt: alt)) return true;

    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.g:
        var screen = _HomeGetScreen(_gameScreen);
        screen._inspected = _inspected;
        _isActive = false;
        ui.push(screen);
        return true;

      case KeyCode.p:
        _isActive = false;
        ui.push(ItemDialog.put(_gameScreen));
        return true;
    }

    return false;
  }
}

/// Screen to get items from the hero's home.
class _HomeGetScreen extends ItemScreen {
  String get _headerText => "Get which item?";

  String get _verb => "Get";

  Map<String, String> get _helpKeys =>
      {"A-Z": "Select item", "Shift": "Inspect item", "Esc": "Cancel"};

  ItemCollection get _items => _gameScreen.game.hero.save.home;

  ItemCollection get _destination => _gameScreen.game.hero.inventory;

  _HomeGetScreen(GameScreen gameScreen) : super._(gameScreen);

  bool get _canSelectAny => true;

  bool canSelect(Item item) => true;

  void _afterTransfer(Item item, int count) {
    _gameScreen.game.log.message("You get ${item.clone(count)}.");
  }
}

/// Views the contents of a shop and lets the player choose to buy or sell.
class _ShopViewScreen extends ItemScreen {
  final Inventory _shop;

  ItemCollection get _items => _shop;

  String get _headerText => "What can I interest you in?";
  bool get _showPrices => true;

  Map<String, String> get _helpKeys => {
        "B": "Buy item",
        "S": "Sell item",
        "Shift": "Inspect item",
        "Esc": "Cancel"
      };

  _ShopViewScreen(GameScreen gameScreen, this._shop) : super._(gameScreen);

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (super.keyDown(keyCode, shift: shift, alt: alt)) return true;

    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.b:
        var screen = _ShopBuyScreen(_gameScreen, _shop);
        screen._inspected = _inspected;
        _isActive = false;
        ui.push(screen);
        break;

      case KeyCode.s:
        _isActive = false;
        ui.push(ItemDialog.sell(_gameScreen, _shop));
        return true;
    }

    return false;
  }

  int _itemPrice(Item item) => item.price;
}

/// Screen to buy items from a shop.
class _ShopBuyScreen extends ItemScreen {
  final Inventory _shop;

  String get _headerText => "Buy which item?";

  String get _verb => "Buy";

  Map<String, String> get _helpKeys =>
      {"A-Z": "Select item", "Shift": "Inspect item", "Esc": "Cancel"};

  ItemCollection get _items => _shop;

  ItemCollection get _destination => _gameScreen.game.hero.save.inventory;

  _ShopBuyScreen(GameScreen gameScreen, this._shop) : super._(gameScreen);

  bool get _canSelectAny => true;
  bool get _showPrices => true;

  bool canSelect(Item item) => item.price <= _save.gold;

  int _initialCount(Item item) => 1;

  /// Don't allow buying more than the hero can afford.
  int _maxCount(Item item) => math.min(item.count, _save.gold ~/ item.price);

  int _itemPrice(Item item) => item.price;

  /// Pay for purchased item.
  void _afterTransfer(Item item, int count) {
    var price = item.price * count;
    _gameScreen.game.log
        .message("You buy ${item.clone(count)} for $price gold.");
    _save.gold -= price;
  }
}

/// Screen to let the player choose a count for a selected item.
class _CountScreen extends ItemScreen {
  /// The [ItemScreen] that pushed this.
  final ItemScreen _parent;
  final Item _item;
  int _count;

  ItemCollection get _items => _parent._items;

  String get _headerText {
    var itemText = _item.clone(_count).toString();
    var price = _parent._itemPrice(_item);
    if (price != null) {
      var priceString = formatMoney(price * _count);
      return "${_parent._verb} $itemText for $priceString gold?";
    } else {
      return "${_parent._verb} $itemText?";
    }
  }

  Map<String, String> get _helpKeys =>
      {"OK": _parent._verb, "↕": "Change quantity", "Esc": "Cancel"};

  _CountScreen(GameScreen gameScreen, this._parent, this._item)
      : super._(gameScreen) {
    _count = _parent._initialCount(_item);
    _inspected = _item;
  }

  bool get _canSelectAny => true;

  /// Highlight the item the user already selected.
  bool canSelect(Item item) => item == _item;

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    // Don't allow the shift key to inspect items.
    if (keyCode == KeyCode.shift) return false;

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

  bool keyUp(int keyCode, {bool shift, bool alt}) {
    // Don't allow the shift key to inspect items.
    return false;
  }

  bool handleInput(Input input) {
    switch (input) {
      case Input.ok:
        ui.pop(_count);
        return true;

      case Input.cancel:
        ui.pop();
        return true;

      case Input.n:
        if (_count < _parent._maxCount(_item)) {
          _count++;
          dirty();
        }
        return true;

      case Input.s:
        if (_count > 1) {
          _count--;
          dirty();
        }
        return true;

      case Input.runN:
        _count = _parent._maxCount(_item);
        dirty();
        return true;

      case Input.runS:
        _count = 1;
        dirty();
        return true;

      // TODO: Allow typing number.
    }

    return false;
  }

  int _itemPrice(Item item) => _parent._itemPrice(item);
}
