import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';
import 'item_dialog.dart';

/// A screen where the hero can manage their items outside of the levels.
///
/// Let's them transfer between their inventory, equipment, crucible, and home.
class ItemScreen extends Screen<Input> {
  final Content  content;
  final HeroSave save;

  /// Which views are shown on each side.
  final Map<Side, View> views = {
    Side.left: View.inventory,
    Side.right: View.home
  };

  View get leftView => views[Side.left];
  set leftView(View value) {
    views[Side.left] = value;
  }

  View get rightView => views[Side.right];
  set rightView(View value) {
    views[Side.right] = value;
  }

  Mode mode = Mode.view;

  /// Which side has keyboard focus.
  Side active = Side.left;

  /// All of the views that can be shown.
  final List<View> _allViews = [];

  /// If the crucible contains a complete recipe, this will be it. Otherwise,
  /// this will be `null`.
  Recipe completeRecipe;

  ItemScreen(this.content, this.save) {
    _allViews.addAll([
      View.inventory,
      View.equipment,
      View.home,
      View.crucible
    ]);

    for (var shop in content.shops) {
      _allViews.add(new ShopView(shop));
    }
  }

  bool handleInput(Input input) {
    if (mode.handleInput(input, this)) return true;

    switch (input) {
      case Input.cancel:
        ui.pop();
        break;

      // Switch columns.
      case Input.e:
        active = Side.right;
        break;

      case Input.w:
        active = Side.left;
        break;

      // Switch views on the current column.
      // TODO: This is totally wrong. It means you can't do anything with items
      // in slots "o" or "l".
      case Input.n:
        do {
          views[active] = _changeView(views[active], -1);
        }
        while (!views[active].allowedOnSide(active));
        break;

      case Input.s:
        do {
          views[active] = _changeView(views[active], 1);
        }
        while (!views[active].allowedOnSide(active));
        break;

      default:
        return false;
    }

    // Don't show the same on both sides.
    if (leftView == rightView) {
      if (active == Side.left) {
        rightView = View.crucible;
      } else {
        leftView = View.inventory;
      }
    }

    dirty();
    return true;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (mode.keyDown(keyCode, this)) return true;

    if (keyCode == KeyCode.space &&
        completeRecipe != null &&
        rightView == View.crucible) {
      save.crucible.clear();
      completeRecipe.result.spawnDrop(save.crucible.tryAdd);
      refreshRecipe();

      // The player probably wants to get the item out of the crucible.
      mode = Mode.get;
      dirty();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, mode.message(this));

    var gold = priceString(save.gold);
    terminal.writeAt(82, 0, "Gold:");
    terminal.writeAt(99 - gold.length, 0, gold, Color.gold);

    terminal.writeAt(0, terminal.height - 1, "${mode.helpText(this)}",
        Color.gray);

    var bar = new Glyph.fromCharCode(
        CharCode.boxDrawingsLightVertical, Color.darkGray);
    for (var y = 2; y < 30; y++) {
      terminal.drawGlyph(49, y, bar);
    }

    drawSide(Side side, int x) {
      var view = views[side];

      if (active == side && mode == Mode.view) {
        terminal.writeAt(x, 2, view.label, Color.black, Color.yellow);
      } else {
        terminal.writeAt(x, 2, view.label);
      }

      if (mode.allowsSelection) {
        drawItems(terminal, x, 4, view.getItems(this),
            (item) => mode.canSelectItem(this, side, item));
      } else {
        drawItems(terminal, x, 4, view.getItems(this));
      }
    }

    drawSide(Side.left, 0);
    drawSide(Side.right, 50);

    if (rightView == View.crucible && completeRecipe != null) {
      terminal.writeAt(59, 2, "Press [Space] to forge item!", Color.yellow);

      for (var i = 0; i < completeRecipe.produces.length; i++) {
        terminal.writeAt(50, rightView.getItems(this).length + (i + 4),
            completeRecipe.produces.elementAt(i));
      }
    }
  }

  /// Sees if the crucible currently contains a complete recipe.
  void refreshRecipe() {
    for (final recipe in content.recipes) {
      if (recipe.isComplete(save.crucible)) {
        completeRecipe = recipe;
        return;
      }
    }

    completeRecipe = null;
  }

  // Rotates [view] to a later or earlier one based on [offset].
  View _changeView(View view, int offset) =>
      _allViews[(_allViews.indexOf(view) + offset) % _allViews.length];
}

/// Identifies the two columns on the screen.
enum Side {
  left,
  right
}

/// Which items are currently being shown in a column.
class View {
  static const inventory = const View('Inventory', allowOnRight: false);
  static const equipment = const View('Equipment');
  static const home = const View('Home');
  static const crucible = const View('Crucible', allowOnLeft: false);

  /// The display label for the view.
  final String label;

  /// Which columns this view may be seen on.
  final bool allowOnLeft;
  final bool allowOnRight;

  String get getVerb => "Get";
  String get putVerb => "Put";

  int get getKeyCode => KeyCode.g;
  int get putKeyCode => KeyCode.p;

  const View(this.label, {this.allowOnLeft: true, this.allowOnRight: true});

  /// Gets the list of items for this view.
  ItemCollection getItems(ItemScreen screen) {
    switch (this) {
      case View.inventory: return screen.save.inventory;
      case View.equipment: return screen.save.equipment;
      case View.home: return screen.save.home;
      case View.crucible: return screen.save.crucible;
    }

    throw "unreachable";
  }

  /// Returns `true` if the view is allowed on [side].
  bool allowedOnSide(Side side) =>
      side == Side.left ? allowOnLeft : allowOnRight;
}

class ShopView implements View {
  final Shop _shop;

  String get label => _shop.name;

  bool get allowOnLeft => false;
  bool get allowOnRight => true;

  String get getVerb => "Buy";
  String get putVerb => "Sell";

  int get getKeyCode => KeyCode.b;
  int get putKeyCode => KeyCode.s;

  ShopView(this._shop);

  /// Returns `true` if the view is allowed on [side].
  bool allowedOnSide(Side side) =>
      side == Side.left ? allowOnLeft : allowOnRight;

  ItemCollection getItems(ItemScreen screen) => _shop;
}

/// What the user is currently doing on the item screen.
abstract class Mode {
  static final view = const ViewMode();
  static final put = const PutMode();
  static final get = const GetMode();

  const Mode();

  /// Whether items should be shown as selectable or not.
  bool get allowsSelection => false;

  String message(ItemScreen screen);

  String helpText(ItemScreen screen);

  /// If [allowsSelection] is true, which items can be selected.
  bool canSelectItem(ItemScreen screen, Side side, Item item) => false;

  bool handleInput(Input input, ItemScreen screen) => false;
  bool keyDown(int keyCode, ItemScreen screen);
}

/// The default mode. Lets users switch which item lists are being shown on the
/// left and right sides, and choose an action to perform.
class ViewMode extends Mode {
  const ViewMode();

  String message(ItemScreen screen) => 'Which items do you want to look at?';

  String helpText(ItemScreen screen) {
    return "[↔] Select column, [↕] Select source, "
        "[${screen.rightView.getVerb[0]}] ${screen.rightView.getVerb}, "
        "[${screen.rightView.putVerb[0]}] ${screen.rightView.putVerb}, "
        "[Esc] Exit";
  }

  bool keyDown(int keyCode, ItemScreen screen) {
    if (keyCode == screen.rightView.getKeyCode) {
      screen.mode = Mode.get;
    } else if (keyCode == screen.rightView.putKeyCode) {
      screen.mode = Mode.put;
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

  bool get allowsSelection => true;

  String helpText(ItemScreen screen) => '[A-Z] Choose item, [Esc] Cancel';

  bool handleInput(Input input, ItemScreen screen) {
    if (input == Input.cancel) {
      screen.mode = Mode.view;
      screen.dirty();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, ItemScreen screen) {
    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      selectItem(screen, keyCode - KeyCode.a);

      // TODO: There is a bug here that this prevents Ctrl-R from refreshing
      // the page. Should only get here if Ctrl is not pressed.
      return true;
    }

    return false;
  }

  void selectItem(ItemScreen screen, int index);
}

/// Mode for putting an item into the home, equipment, or crucible.
class PutMode extends SelectMode {
  const PutMode();

  String message(ItemScreen screen) =>
      "${screen.rightView.putVerb} which item?";

  bool canSelectItem(ItemScreen screen, Side side, Item item) {
    if (side == Side.right) return false;

    // TODO: Move these checks into the View.

    // Can put anything in the home.
    if (screen.rightView == View.home) return true;

    // Can only put equippable items.
    if (screen.rightView == View.equipment) {
      // TODO: This is a bit wonky. canEquip() assumes you can swap items,
      // which the item screen doesn't support.
      return screen.save.equipment.canEquip(item);
    }

    // Can only put items in the crucible if they fit a recipe.
    if (screen.rightView == View.crucible) {
      var items = screen.rightView.getItems(screen).toList();
      items.add(item);
      return screen.content.recipes.any((recipe) => recipe.allows(items));
    }

    // Can only sell things that have a price.
    if (screen.rightView is ShopView) {
      return item.price > 0;
    }

    throw "unreachable";
  }

  void selectItem(ItemScreen screen, int index) {
    var from = screen.leftView.getItems(screen);

    if (index >= from.length) return;
    var item = from[index];
    if (!canSelectItem(screen, Side.left, item)) return;

    var to = screen.rightView.getItems(screen);

    if (to.tryAdd(item)) {
      from.removeAt(index);
    } else {
      // TODO: Show an error message?
    }

    if (screen.rightView is ShopView) {
      screen.save.gold += item.price;
    }

    if (screen.rightView == View.crucible) screen.refreshRecipe();
    screen.dirty();
  }
}

/// Mode for "getting" an item from the home or crucible.
class GetMode extends SelectMode {
  const GetMode();

  String message(ItemScreen screen) =>
      "${screen.rightView.getVerb} which item?";

  bool canSelectItem(ItemScreen screen, Side side, Item item) {
    if (side == Side.left) return false;

    var view = screen.views[side];
    if (view is ShopView) {
      // Have to have enough gold to buy it.
      if (screen.save.gold < item.price) return false;
    }

    return true;
  }

  void selectItem(ItemScreen screen, int index) {
    var from = screen.rightView.getItems(screen);

    if (index >= from.length) return;
    var item = from[index];

    var to = screen.leftView.getItems(screen);

    if (to.tryAdd(item)) {
      from.removeAt(index);

      // If it's taken from a shop, pay for it.
      if (screen.rightView is ShopView) {
        screen.save.gold -= item.price;
      }

      // If we get the last item, automatically switch out of get mode.
      if (from.isEmpty) screen.mode = Mode.view;
    } else {
      // TODO: Show an error message?
    }

    if (screen.rightView == View.crucible) screen.refreshRecipe();
    screen.dirty();
  }
}
