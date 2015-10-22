library hauberk.ui.home_screen;

import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';
import 'item_dialog.dart';

/// A screen where the hero can manage their items outside of the levels.
///
/// Let's them transfer between their inventory, equipment, crucible, and home.
class ItemScreen extends Screen {
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

  /// If the crucible contains a complete recipe, this will be it. Otherwise,
  /// this will be `null`.
  Recipe completeRecipe;

  ItemScreen(this.content, this.save);

  bool handleInput(Input input) {
    if (mode.handleInput(input, this)) return true;

    switch (input) {
      case Input.CANCEL:
        ui.pop();
        break;

      // Switch columns.
      case Input.E:
        active = Side.right;
        break;

      case Input.W:
        active = Side.left;
        break;

      // Switch views on the current column.
      case Input.N:
        do {
          views[active] = views[active].previous;
        }
        while (!views[active].allowedOnSide(active));
        break;

      case Input.S:
        do {
          views[active] = views[active].next;
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
    terminal.writeAt(0, 0, mode.message);

    var gold = _priceString(save.gold);
    terminal.writeAt(83, 0, "Gold:");
    terminal.writeAt(100 - gold.length, 0, gold, Color.gold);

    terminal.writeAt(0, terminal.height - 1, "${mode.helpText}, [Esc] Exit",
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

      canSelect(Item item) => mode.canSelectItem(this, side, item);

      drawItems(terminal, x, 3, view.getItems(this), canSelect);

      var y = 3;
      for (var item in view.getItems(this)) {
        if (item.price == 0) continue;

        var price = _priceString(item.price);
        terminal.writeAt(x + 49 - price.length, y++, price, Color.darkGray);
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

  /// Converts an integer to a comma-grouped string like "123,456".
  String _priceString(int price) {
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

  static const List<View> _all = const [
    inventory,
    equipment,
    home,
    crucible
  ];

  /// The display label for the view.
  final String label;

  /// Which columns this view may be seen on.
  final bool allowOnLeft;
  final bool allowOnRight;

  const View(this.label, {this.allowOnLeft: true, this.allowOnRight: true});

  View get next => _all[(_all.indexOf(this) + 1) % _all.length];

  View get previous => _all[(_all.indexOf(this) - 1) % _all.length];

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

/// What the user is currently doing on the item screen.
abstract class Mode {
  static final view = const ViewMode();
  static final put = const PutMode();
  static final get = const GetMode();

  const Mode();

  String get message;
  String get helpText;

  bool canSelectItem(ItemScreen screen, Side side, Item item) => false;

  bool handleInput(Input input, ItemScreen screen) => false;
  bool keyDown(int keyCode, ItemScreen screen);
}

/// The default mode. Lets users switch which item lists are being shown on the
/// left and right sides, and choose an action to perform.
class ViewMode extends Mode {
  const ViewMode();

  String get message => 'Which items do you want to look at?';
  String get helpText => '[↔] Select column, [↕] Select source, [G] Get, [P] Put';

  bool keyDown(int keyCode, ItemScreen screen) {
    switch (keyCode) {
      case KeyCode.g: screen.mode = Mode.get; break;
      case KeyCode.p: screen.mode = Mode.put; break;

      default:
        return false;
    }

    screen.dirty();
    return true;
  }
}

/// Base class for a mode that lets a user select an item.
abstract class SelectMode extends Mode {
  const SelectMode();

  String get helpText => '[A-Z] Choose an item, [Esc] Cancel';

  bool handleInput(Input input, ItemScreen screen) {
    if (input == Input.CANCEL) {
      screen.mode = Mode.view;
      screen.dirty();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, ItemScreen screen) {
    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      selectItem(screen, keyCode - KeyCode.a);
      return true;
    }

    return false;
  }

  void selectItem(ItemScreen screen, int index);
}

/// Mode for putting an item into the home, equipment, or crucible.
class PutMode extends SelectMode {
  const PutMode();

  String get message => 'Put which item?';

  bool canSelectItem(ItemScreen screen, Side side, Item item) {
    if (side == Side.right) return false;

    // Can put anything in the home.
    if (screen.rightView == View.home) return true;

    // Can only put equippable items.
    if (screen.rightView == View.equipment) {
      // TODO: This is a bit wonky. canEquip() assumes you can swap items,
      // which the item screen doesn't support.
      return screen.save.equipment.canEquip(item);
    }

    // Can only put items in the crucible if they fit a recipe.
    var items = new List.from(screen.rightView.getItems(screen));
    items.add(item);
    return screen.content.recipes.any((recipe) => recipe.allows(items));
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

    if (screen.rightView == View.crucible) screen.refreshRecipe();
    screen.dirty();
  }
}

/// Mode for "getting" an item from the home or crucible.
class GetMode extends SelectMode {
  const GetMode();

  String get message => 'Pick up which item?';

  bool canSelectItem(ItemScreen screen, Side side, Item item) {
    return side == Side.right;
  }

  void selectItem(ItemScreen screen, int index) {
    var from = screen.rightView.getItems(screen);

    if (index >= from.length) return;
    var item = from[index];

    var to = screen.leftView.getItems(screen);

    if (to.tryAdd(item)) {
      from.removeAt(index);

      // If we get the last item, automatically switch out of get mode.
      if (from.isEmpty) screen.mode = Mode.view;
    } else {
      // TODO: Show an error message?
    }

    if (screen.rightView == View.crucible) screen.refreshRecipe();
    screen.dirty();
  }
}
