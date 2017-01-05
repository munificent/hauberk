import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';
import 'item_dialog.dart';

// TODO: Can simplify this a lot now that there are separate entrypoints for
// each store and the inventory/equipment is always on the left.

/// A screen where the hero can manage their items outside of the levels.
///
/// Let's them transfer between their inventory, equipment, crucible, and home.
class ItemScreen extends Screen<Input> {
  final Content _content;
  final HeroSave _save;

  /// Whether the left hand side is showing the inventory or equipment.
  bool _showingInventory = true;

  /// The collection of items on the hero's person being shown.
  ItemCollection get _heroItems =>
      _showingInventory ? _save.inventory : _save.equipment;

  /// The place whose items are being interacted with.
  final _Place _place;

  Mode _mode = Mode.view;

  /// If the crucible contains a complete recipe, this will be it. Otherwise,
  /// this will be `null`.
  Recipe completeRecipe;

  ItemScreen.crucible(this._content, this._save)
      : _place = _Place.crucible;

  ItemScreen.home(this._content, this._save)
      : _place = _Place.home;

  ItemScreen.shop(this._content, this._save, Shop shop)
      : _place = new _ShopPlace(shop);

  bool handleInput(Input input) {
    if (_mode.handleInput(input, this)) return true;

    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode == KeyCode.tab) {
      _showingInventory = !_showingInventory;
      dirty();
      return true;
    }

    if (_mode.keyDown(keyCode, this)) return true;

    if (keyCode == KeyCode.space &&
        completeRecipe != null &&
        _place == _Place.crucible) {
      _save.crucible.clear();
      completeRecipe.result.spawnDrop(_save.crucible.tryAdd);
      refreshRecipe();

      // The player probably wants to get the item out of the crucible.
      _mode = Mode.get;
      dirty();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, _mode.message(this));

    var gold = priceString(_save.gold);
    terminal.writeAt(82, 0, "Gold:");
    terminal.writeAt(99 - gold.length, 0, gold, Color.gold);

    terminal.writeAt(0, terminal.height - 1, "${_mode.helpText(this)}",
        Color.gray);

    var bar = new Glyph.fromCharCode(
        CharCode.boxDrawingsLightVertical, Color.darkGray);
    for (var y = 2; y < 30; y++) {
      terminal.drawGlyph(49, y, bar);
    }

    _drawHero(terminal, 0);
    _drawPlace(terminal, 50);

    if (_place == _Place.crucible && completeRecipe != null) {
      terminal.writeAt(59, 2, "Press [Space] to forge item!", Color.yellow);

      var itemCount = _place.items(this).length;
      for (var i = 0; i < completeRecipe.produces.length; i++) {
        terminal.writeAt(50, itemCount + i + 4,
            completeRecipe.produces.elementAt(i));
      }
    }
  }

  void _drawHero(Terminal terminal, int x) {
    terminal.writeAt(x, 2, _showingInventory ? "Inventory" : "Equipment");

    bool isSelectable(Item item) {
      if (!_mode.selectingFromHero) return false;
      return _mode.canSelectItem(this, item);
    }

    var canSelect = _mode.selectingFromHero || _mode.selectingFromPlace
        ? isSelectable : null;

    if (_showingInventory) {
      drawItems(terminal, x, 4, _save.inventory, canSelect);
    } else {
      drawEquipment(terminal, x, 4, _save.equipment, canSelect);
    }
  }

  void _drawPlace(Terminal terminal, int x) {
    terminal.writeAt(x, 2, _place.label);

    var items = _place.items(this);
    if (_mode.selectingFromHero || _mode.selectingFromPlace) {
      drawItems(terminal, x, 4, items, (item) {
        if (!_mode.selectingFromPlace) return false;
        return _mode.canSelectItem(this, item);
      });
    } else {
      drawItems(terminal, x, 4, items);
    }
  }

  /// Sees if the crucible currently contains a complete recipe.
  void refreshRecipe() {
    for (final recipe in _content.recipes) {
      if (recipe.isComplete(_save.crucible)) {
        completeRecipe = recipe;
        return;
      }
    }

    completeRecipe = null;
  }
}

/// A source of items not on the hero's person.
class _Place {
  static const home = const _Place('Home');
  static const crucible = const _Place('Crucible');

  /// The display label for the place.
  final String label;

  String get getVerb => "Get";
  String get putVerb => "Put";

  int get getKeyCode => KeyCode.g;
  int get putKeyCode => KeyCode.p;

  const _Place(this.label);

  /// Gets the list of items from this place.
  ItemCollection items(ItemScreen screen) {
    switch (this) {
      case _Place.home: return screen._save.home;
      case _Place.crucible: return screen._save.crucible;
    }

    throw "unreachable";
  }
}

class _ShopPlace implements _Place {
  final Shop _shop;

  String get label => _shop.name;

  String get getVerb => "Buy";
  String get putVerb => "Sell";

  int get getKeyCode => KeyCode.b;
  int get putKeyCode => KeyCode.s;

  _ShopPlace(this._shop);

  ItemCollection items(ItemScreen screen) => _shop;
}

/// What the user is currently doing on the item screen.
abstract class Mode {
  static final view = const ViewMode();
  static final put = const PutMode();
  static final get = const GetMode();

  const Mode();

  /// Whether the hero's items should be shown as selectable.
  bool get selectingFromHero => false;

  /// Whether the place's items should be shown as selectable.
  bool get selectingFromPlace => false;

  String message(ItemScreen screen);

  String helpText(ItemScreen screen);

  /// If [item] can be selected.
  bool canSelectItem(ItemScreen screen, Item item) => false;

  bool handleInput(Input input, ItemScreen screen) => false;
  bool keyDown(int keyCode, ItemScreen screen);
}

/// The default mode. Lets users switch which item lists are being shown on the
/// left and right sides, and choose an action to perform.
class ViewMode extends Mode {
  const ViewMode();

  String message(ItemScreen screen) => 'Which items do you want to look at?';

  String helpText(ItemScreen screen) {
    var tab = screen._showingInventory ?
        "Switch to equipment" : "Switch to inventory";

    return "[Tab] $tab, "
        "[${screen._place.getVerb[0]}] ${screen._place.getVerb}, "
        "[${screen._place.putVerb[0]}] ${screen._place.putVerb}, "
        "[Esc] Exit";
  }

  bool keyDown(int keyCode, ItemScreen screen) {
    if (keyCode == screen._place.getKeyCode) {
      screen._mode = Mode.get;
    } else if (keyCode == screen._place.putKeyCode) {
      screen._mode = Mode.put;
    } else {
      return false;
    }

    screen.dirty();
    return true;
  }
}

/// Base class for a mode that lets a user select an item.
abstract class SelectMode extends Mode {
  const SelectMode();

  String helpText(ItemScreen screen) => '[A-Z] Choose item, [Esc] Cancel';

  bool handleInput(Input input, ItemScreen screen) {
    if (input == Input.cancel) {
      screen._mode = Mode.view;
      screen.dirty();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, ItemScreen screen) {
    if (keyCode < KeyCode.a || keyCode > KeyCode.z) return false;

    if (selectItem(screen, keyCode - KeyCode.a)) {
      // Switch back to viewing after a successful action.
      screen._mode = Mode.view;
      screen.dirty();
    }

    return true;
  }

  bool selectItem(ItemScreen screen, int index);
}

// TODO: Add a mode to equip/unequip an item.

/// Mode for putting an item into the home, equipment, or crucible.
class PutMode extends SelectMode {
  const PutMode();

  bool get selectingFromHero => true;

  String message(ItemScreen screen) =>
      "${screen._place.putVerb} which item?";

  bool canSelectItem(ItemScreen screen, Item item) {
    // TODO: Move these checks into the Place.

    // Can put anything in the home.
    if (screen._place == _Place.home) return true;

    // Can only put items in the crucible if they fit a recipe.
    if (screen._place == _Place.crucible) {
      var items = screen._place.items(screen).toList();
      items.add(item);
      return screen._content.recipes.any((recipe) => recipe.allows(items));
    }

    // Can only sell things that have a price.
    return item.price > 0;
  }

  bool selectItem(ItemScreen screen, int index) {
    var from = screen._heroItems;

    if (index >= from.length) return false;
    var item = from[index];
    if (!canSelectItem(screen, item)) return false;

    // TODO: Prompt the user for a count if the item is a stack.

    var to = screen._place.items(screen);

    if (to.tryAdd(item)) {
      from.removeAt(index);
    } else {
      // TODO: Show an error message?
    }

    if (screen._place is _ShopPlace) {
      screen._save.gold += item.price;
    }

    if (screen._place == _Place.crucible) screen.refreshRecipe();
    return true;
  }
}

/// Mode for "getting" an item from the home or crucible.
class GetMode extends SelectMode {
  const GetMode();

  bool get selectingFromPlace => true;

  String message(ItemScreen screen) =>
      "${screen._place.getVerb} which item?";

  bool canSelectItem(ItemScreen screen, Item item) {
    // TODO: Prompt for count when appropriate.

    var place = screen._place;
    if (place is _ShopPlace) {
      // Have to have enough gold to buy it.
      if (screen._save.gold < item.price) return false;
    }

    return true;
  }

  bool selectItem(ItemScreen screen, int index) {
    var from = screen._place.items(screen);

    if (index >= from.length) return false;
    var item = from[index];

    var to = screen._heroItems;

    // TODO: Handle item stacks.
    if (to.tryAdd(item)) {
      from.removeAt(index);

      // If it's taken from a shop, pay for it.
      if (screen._place is _ShopPlace) {
        screen._save.gold -= item.price;
      }
    } else {
      // TODO: Show an error message?
    }

    if (screen._place == _Place.crucible) screen.refreshRecipe();
    return true;
  }
}
