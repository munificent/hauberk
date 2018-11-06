import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';
import 'item_view.dart';

abstract class ItemScreen extends Screen<Input> {
  final HeroSave _save;

  /// The place items are being transferred to or `null` if this is just a
  /// view.
  final _ItemSink _sink;

  /// Whether the shift key is currently pressed.
  bool _shiftDown = false;

  /// The item currently being inspected or `null` if none.
  Item _inspected;

//  /// If the crucible contains a complete recipe, this will be it. Otherwise,
//  /// this will be `null`.
//  Recipe completeRecipe;

  String _error;

  ItemCollection get _items;

  String get _headerText => _sink.headerText;

  String get _helpText;

  ItemScreen._(this._save, this._sink);

//  ItemScreen.crucible(this._content, this._save) : _place = _Place.crucible;

  factory ItemScreen.home(HeroSave save) => _HomeViewScreen(save);

  factory ItemScreen.shop(HeroSave save, Inventory shop) =>
      _ShopViewScreen(save, shop);

  bool _canSelect(Item item) {
    if (_shiftDown) return true;

    return canSelect(item);
  }

  bool canSelect(Item item) => null;

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
        if (canSelect(item) != true) return false;

        // Prompt the user for a count if the item is a stack.
        if (item.count > 1) {
          ui.push(_CountScreen(_save, this, item));
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
    _inspected = null;

    if (popped is _CountScreen && result != null) {
      if (_transfer(popped._item, result)) {
        ui.pop();
      }
    }
  }

  void render(Terminal terminal) {
    var header = _shiftDown ? "Inspect which item?" : _headerText;
    terminal.writeAt(0, 0, header, UIHue.selection);

    var heroGold = formatMoney(_save.gold);
    terminal.writeAt(31, 0, "Gold:", UIHue.text);
    terminal.writeAt(45 - heroGold.length - 1, 0, "\$", persimmon);
    terminal.writeAt(45 - heroGold.length, 0, heroGold, gold);

    drawItems(terminal, 0, _items,
        canSelect: _canSelect,
        getPrice: _itemPrice,
        capitals: _shiftDown,
        inspected: _inspected);

    if (_inspected != null) {
      drawInspector(terminal, _save, _inspected);
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

    var help = _shiftDown ? "[A-Z] Inspect item" : _helpText;
    terminal.writeAt(0, terminal.height - 1, help, UIHue.helpText);
  }

  /// The default count to move when transferring a stack from [_items].
  int _initialCount(Item item) => item.count;

  /// The maximum number of items in the stack of [item] that can be
  /// transferred from [_items].
  int _maxCount(Item item) => item.count;

  /// By default, don't show the price.
  int _itemPrice(Item item) => null;

  bool _transfer(Item item, int count) {
    var to = _sink.items;

    if (!to.canAdd(item)) {
      _error = "Not enough room for ${item.clone(count)}.";
      dirty();
      return false;
    }

    if (count == item.count) {
      // Moving the entire stack.
      to.tryAdd(item);
      _items.remove(item);
    } else {
      // Splitting the stack.
      to.tryAdd(item.splitStack(count));
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

class _HomeViewScreen extends ItemScreen {
  ItemCollection get _items => _save.home;

  String get _headerText => "Welcome home!";

  String get _helpText =>
      "[G] Get item, [P] Put item, [Shift] Inspect item, [Esc] Leave";

  _HomeViewScreen(HeroSave save) : super._(save, null);

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (super.keyDown(keyCode, shift: shift, alt: alt)) return true;

    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.g:
        var screen = _HomeGetScreen(_save);
        screen._inspected = _inspected;
        ui.push(screen);
        return true;

      case KeyCode.p:
        ui.push(_InventoryScreen(_save, _HomeSink(_save)));
        return true;
    }

    return false;
  }
}

/// Screen to get items from the hero's home.
class _HomeGetScreen extends ItemScreen {
  String get _headerText => "Get which item?";

  String get _helpText =>
      "[A-Z] Select item, [Shift] Inspect item, [Esc] Cancel";

  ItemCollection get _items => _save.home;

  _HomeGetScreen(HeroSave save) : super._(save, _InventorySink(save));

  bool canSelect(Item item) => true;
}

/// Base class for inventory and equipment screens.
// TODO: Show confirmation of put item.
abstract class _HeroScreen extends ItemScreen {
  String get _helpText => "[Tab] Switch to $nextScreenName, "
      "[A-Z] Select item, [Shift] Inspect item, [Esc] Cancel";

  String get nextScreenName;

  _HeroScreen(HeroSave save, _ItemSink sink) : super._(save, sink);

  ItemScreen nextScreen();

  bool canSelect(Item item) => true;

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (super.keyDown(keyCode, shift: shift, alt: alt)) return true;

    if (shift || alt) return false;

    if (keyCode == KeyCode.tab) {
      ui.goTo(nextScreen());
      return true;
    }

    return false;
  }
}

/// Takes an item from the inventory.
class _InventoryScreen extends _HeroScreen {
  ItemCollection get _items => _save.inventory;

  String get nextScreenName => "equipment";

  _InventoryScreen(HeroSave save, _ItemSink sink) : super(save, sink);

  ItemScreen nextScreen() => _EquipmentScreen(_save, _sink);
}

/// Takes an item from the equipment.
class _EquipmentScreen extends _HeroScreen {
  ItemCollection get _items => _save.equipment;

  String get nextScreenName => "inventory";

  _EquipmentScreen(HeroSave save, _ItemSink sink) : super(save, sink);

  ItemScreen nextScreen() => _InventoryScreen(_save, _sink);
}

/// Views the contents of a shop and lets the player choose to buy or sell.
class _ShopViewScreen extends ItemScreen {
  final Inventory _shop;

  ItemCollection get _items => _shop;

  String get _headerText => "What can I interest you in?";

  String get _helpText =>
      "[B] Buy item, [S] Sell item, [Shift] Inspect item, [Esc] Leave";

  _ShopViewScreen(HeroSave save, this._shop) : super._(save, null);

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (super.keyDown(keyCode, shift: shift, alt: alt)) return true;

    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.b:
        var screen = _ShopBuyScreen(_save, _shop);
        screen._inspected = _inspected;
        ui.push(screen);
        break;

      case KeyCode.s:
        ui.push(_InventorySellScreen(_save, _ShopSink(_shop)));
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

  String get _helpText =>
      "[A-Z] Select item, [Shift] Inspect item, [Esc] Cancel";

  ItemCollection get _items => _shop;

  _ShopBuyScreen(HeroSave save, this._shop)
      : super._(save, _InventorySink(save));

  bool canSelect(Item item) => item.price <= _save.gold;

  int _initialCount(Item item) => 1;

  /// Don't allow buying more than the hero can afford.
  int _maxCount(Item item) => math.min(item.count, _save.gold ~/ item.price);

  int _itemPrice(Item item) => item.price;

  /// Pay for purchased item.
  void _afterTransfer(item, count) {
    _save.gold -= item.price * count;
  }
}

// TODO: Require confirmation when selling an item?
// TODO: Show confirmation of sold item.
/// Mixin for screens that sell a hero's item to a shop.
abstract class _SellMixin implements ItemScreen {
  bool canSelect(Item item) => _itemPrice(item) > 0;

  int _initialCount(Item item) => 1;

  int _itemPrice(Item item) => (item.price * 0.75).floor();

  void _afterTransfer(item, count) {
    _save.gold += _itemPrice(item) * count;
  }
}

/// Screen to sell an item from the inventory.
class _InventorySellScreen extends _InventoryScreen with _SellMixin {
  _InventorySellScreen(HeroSave save, _ItemSink sink) : super(save, sink);

  ItemScreen nextScreen() => _EquipmentSellScreen(_save, _sink);
}

/// Screen to sell an item from the equipment.
class _EquipmentSellScreen extends _EquipmentScreen with _SellMixin {
  _EquipmentSellScreen(HeroSave save, _ItemSink sink) : super(save, sink);

  ItemScreen nextScreen() => _InventorySellScreen(_save, _sink);
}

/// Screen to let the player choose a count for a selected item.
class _CountScreen extends ItemScreen {
  /// The [ItemScreen] that pushed this.
  final ItemScreen _parent;
  final Item _item;
  int _count;

  ItemCollection get _items => _parent._items;

  String get _headerText => "";

  String get _helpText =>
      "[OK] ${_sink.verb}, [↕] Change quantity, [Esc] Cancel";

  _CountScreen(HeroSave save, this._parent, this._item)
      : super._(save, _parent._sink) {
    _count = _parent._initialCount(_item);
    _inspected = _item;
  }

  /// Highlight the item the user already selected.
  bool canSelect(Item item) => item == _item;

  void render(Terminal terminal) {
    super.render(terminal);

    var x = 0;
    terminal.writeAt(x, 0, _sink.verb);
    x += _sink.verb.length + 1;

    var itemText = _item.clone(_count).toString();
    terminal.writeAt(x, 0, itemText, UIHue.selection);
    x += itemText.length;

    var price = _parent._itemPrice(_item);
    if (price != null) {
      terminal.writeAt(x, 0, " for ");
      x += 5;

      var priceString = formatMoney(price * _count);
      terminal.writeAt(x, 0, priceString, gold);
      x += priceString.length;

      terminal.writeAt(x, 0, " gold");
      x += 5;
    }

    terminal.writeAt(x, 0, "?");
  }

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

abstract class _ItemSink {
  String get headerText => throw "unreachable";

  String get verb;

  ItemCollection get items;
}

class _HomeSink extends _ItemSink {
  final HeroSave _save;

  String get headerText => "Put which item in your home?";

  String get verb => "Put";

  ItemCollection get items => _save.home;

  _HomeSink(this._save);
}

class _InventorySink extends _ItemSink {
  final HeroSave _save;

  String get verb => "Get";

  ItemCollection get items => _save.inventory;

  _InventorySink(this._save);
}

class _ShopSink extends _ItemSink {
  final Inventory _shop;

  String get headerText => "Sell which item?";

  String get verb => "Sell";

  ItemCollection get items => _shop;

  _ShopSink(this._shop);
}

// TODO: Add screens to equip/unequip an item.

/*
class _CruciblePlace extends _Place {
  const _CruciblePlace();

  ItemCollection items(ItemScreenOld screen) => screen._save.crucible;

  bool canPut(ItemScreenOld screen, Item item) {
    // TODO: Should not allow a greater count of items than the recipe permits,
    // since the extras will be lost when the item is forged.

    // Can only put items in the crucible if they fit a recipe.
    var ingredients = items(screen).toList();
    ingredients.add(item);
    return screen._content.recipes.any((recipe) => recipe.allows(ingredients));
  }
}
*/
