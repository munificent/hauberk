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

  // TODO: Move this and _transfer() to an intermediate class instead of making
  // this nullable?
  /// The place items are being transferred to or `null` if this is just a
  /// view.
  ItemCollection? get _destination => null;

  /// Whether the shift key is currently pressed.
  bool _shiftDown = false;

  /// Whether this screen is on top.
  // TODO: Maintaining this manually is hacky. Maybe have malison expose it?
  bool _isActive = true;

  /// The item currently being inspected or `null` if none.
  Item? _inspected;

//  /// If the crucible contains a complete recipe, this will be it. Otherwise,
//  /// this will be `null`.
//  Recipe completeRecipe;

  String? _error;

  ItemCollection get _items;

  HeroSave get _save => _gameScreen.game.hero.save;

  String get _headerText;

  Map<String, String> get _helpKeys;

  ItemScreen._(this._gameScreen);

  @override
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

  @override
  bool handleInput(Input input) {
    _error = null;

    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
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

    if (_shiftDown && keyCode == KeyCode.escape) {
      _inspected = null;
      dirty();
      return true;
    }

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
          ui.push(_CountScreen(_gameScreen, this as _ItemVerbScreen, item));
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
  void activate(Screen<Input> popped, Object? result) {
    _isActive = true;
    _inspected = null;

    if (popped is _CountScreen && result != null) {
      if (_transfer(popped._item, result as int)) {
        ui.pop();
      }
    }
  }

  @override
  void render(Terminal terminal) {
    // Don't show the help if another dialog (like buy or sell) is on top with
    // its own help.
    if (_isActive) {
      if (_shiftDown) {
        Draw.helpKeys(
            terminal,
            {
              "A-Z": "Inspect item",
              if (_inspected != null) "Esc": "Hide inspector"
            },
            "Inspect which item?");
      } else {
        Draw.helpKeys(terminal, _helpKeys, _headerText);
      }
    }

    var view = _TownItemView(this);
    var width =
        math.min(ItemView.preferredWidth, _gameScreen.stagePanel.bounds.width);
    view.render(terminal, _gameScreen.stagePanel.bounds.x,
        _gameScreen.stagePanel.bounds.y, width, _items.length);

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
      terminal.writeAt(0, 32, _error!, red);
    }
  }

  /// The default count to move when transferring a stack from [_items].
  int _initialCount(Item item) => item.count;

  /// The maximum number of items in the stack of [item] that can be
  /// transferred from [_items].
  int _maxCount(Item item) => item.count;

  /// By default, don't show the price.
  int? _itemPrice(Item item) => null;

  bool _transfer(Item item, int count) {
    var destination = _destination!;
    if (!destination.canAdd(item)) {
      _error = "Not enough room for ${item.clone(count)}.";
      dirty();
      return false;
    }

    if (count == item.count) {
      // Moving the entire stack.
      destination.tryAdd(item);
      _items.remove(item);
    } else {
      // Splitting the stack.
      destination.tryAdd(item.splitStack(count));
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

/// Base class for item views where the player is performing an action.
abstract class _ItemVerbScreen extends ItemScreen {
  String get _verb;

  _ItemVerbScreen(GameScreen gameScreen) : super._(gameScreen);
}

class _TownItemView extends ItemView {
  final ItemScreen _screen;

  _TownItemView(this._screen);

  @override
  HeroSave get save => _screen._gameScreen.game.hero.save;

  @override
  ItemCollection get items => _screen._items;

  @override
  bool get capitalize => _screen._shiftDown;

  @override
  bool get showPrices => _screen._showPrices;

  @override
  Item? get inspectedItem => _screen._isActive ? _screen._inspected : null;

  @override
  bool get inspectorOnRight => true;

  @override
  bool get canSelectAny => _screen._shiftDown || _screen._canSelectAny;

  @override
  bool canSelect(Item item) => _screen._canSelect(item);

  @override
  int? getPrice(Item item) => _screen._itemPrice(item);
}

class _HomeViewScreen extends ItemScreen {
  @override
  ItemCollection get _items => _save.home;

  @override
  String get _headerText => "Welcome home!";

  @override
  Map<String, String> get _helpKeys => {
        "G": "Get item",
        "P": "Put item",
        "Shift": "Inspect item",
        "Esc": "Leave"
      };

  _HomeViewScreen(GameScreen gameScreen) : super._(gameScreen);

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
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
class _HomeGetScreen extends _ItemVerbScreen {
  @override
  String get _headerText => "Get which item?";

  @override
  String get _verb => "Get";

  @override
  Map<String, String> get _helpKeys =>
      {"A-Z": "Select item", "Shift": "Inspect item", "Esc": "Cancel"};

  @override
  ItemCollection get _items => _gameScreen.game.hero.save.home;

  @override
  ItemCollection get _destination => _gameScreen.game.hero.inventory;

  _HomeGetScreen(GameScreen gameScreen) : super(gameScreen);

  @override
  bool get _canSelectAny => true;

  @override
  bool canSelect(Item item) => true;

  @override
  void _afterTransfer(Item item, int count) {
    _gameScreen.game.log.message("You get ${item.clone(count)}.");
    _gameScreen.game.hero.pickUp(item);
  }
}

/// Views the contents of a shop and lets the player choose to buy or sell.
class _ShopViewScreen extends ItemScreen {
  final Inventory _shop;

  @override
  ItemCollection get _items => _shop;

  @override
  String get _headerText => "What can I interest you in?";
  @override
  bool get _showPrices => true;

  @override
  Map<String, String> get _helpKeys => {
        "B": "Buy item",
        "S": "Sell item",
        "Shift": "Inspect item",
        "Esc": "Cancel"
      };

  _ShopViewScreen(GameScreen gameScreen, this._shop) : super._(gameScreen);

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (super.keyDown(keyCode, shift: shift, alt: alt)) return true;

    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.b:
        var screen = _ShopBuyScreen(_gameScreen, _shop);
        screen._inspected = _inspected;
        _isActive = false;
        ui.push(screen);

      case KeyCode.s:
        _isActive = false;
        ui.push(ItemDialog.sell(_gameScreen, _shop));
        return true;
    }

    return false;
  }

  @override
  int? _itemPrice(Item item) => item.price;
}

/// Screen to buy items from a shop.
class _ShopBuyScreen extends _ItemVerbScreen {
  final Inventory _shop;

  @override
  String get _headerText => "Buy which item?";

  @override
  String get _verb => "Buy";

  @override
  Map<String, String> get _helpKeys =>
      {"A-Z": "Select item", "Shift": "Inspect item", "Esc": "Cancel"};

  @override
  ItemCollection get _items => _shop;

  @override
  ItemCollection get _destination => _gameScreen.game.hero.save.inventory;

  _ShopBuyScreen(GameScreen gameScreen, this._shop) : super(gameScreen);

  @override
  bool get _canSelectAny => true;
  @override
  bool get _showPrices => true;

  @override
  bool canSelect(Item item) => item.price <= _save.gold;

  @override
  int _initialCount(Item item) => 1;

  /// Don't allow buying more than the hero can afford.
  @override
  int _maxCount(Item item) => math.min(item.count, _save.gold ~/ item.price);

  @override
  int? _itemPrice(Item item) => item.price;

  /// Pay for purchased item.
  @override
  void _afterTransfer(Item item, int count) {
    var price = item.price * count;
    _gameScreen.game.log
        .message("You buy ${item.clone(count)} for $price gold.");
    _save.gold -= price;

    // Acquiring an item may unlock skills.
    // TODO: Would be nice if hero handled this more automatically. Maybe make
    // Inventory and Equipment manage this?
    _gameScreen.game.hero.pickUp(item);
  }
}

/// Screen to let the player choose a count for a selected item.
class _CountScreen extends ItemScreen {
  /// The [_ItemVerbScreen] that pushed this.
  final _ItemVerbScreen _parent;
  final Item _item;
  int _count;

  @override
  ItemCollection get _items => _parent._items;

  @override
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

  @override
  Map<String, String> get _helpKeys =>
      {"OK": _parent._verb, "↕": "Change quantity", "Esc": "Cancel"};

  _CountScreen(GameScreen gameScreen, this._parent, this._item)
      : _count = _parent._initialCount(_item),
        super._(gameScreen) {
    _inspected = _item;
  }

  @override
  bool get _canSelectAny => true;

  /// Highlight the item the user already selected.
  @override
  bool canSelect(Item item) => item == _item;

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    // Don't allow the shift key to inspect items.
    if (keyCode == KeyCode.shift) return false;

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

  @override
  bool keyUp(int keyCode, {required bool shift, required bool alt}) {
    // Don't allow the shift key to inspect items.
    return false;
  }

  @override
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

  @override
  int? _itemPrice(Item item) => _parent._itemPrice(item);
}
