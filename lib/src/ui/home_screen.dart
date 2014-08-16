library hauberk.ui.home_screen;

import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';
import 'item_dialog.dart';

class HomeScreen extends Screen {
  final Content  content;
  final HeroSave save;
  HomeView leftView = HomeView.INVENTORY;
  HomeView rightView = HomeView.HOME;
  HomeMode mode = HomeMode.VIEW;

  /// If the crucible contains a complete recipe, this will be it. Otherwise,
  /// this will be `null`.
  Recipe completeRecipe;

  HomeScreen(this.content, this.save);

  bool handleInput(Input input) {
    if (mode.handleInput(input, this)) return true;

    if (input == Input.CANCEL) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (mode.keyDown(keyCode, this)) return true;

    if (keyCode == KeyCode.SPACE &&
        completeRecipe != null &&
        rightView == HomeView.CRUCIBLE) {
      save.crucible.clear();
      completeRecipe.result.spawnDrop(save.crucible.tryAdd);
      refreshRecipe();

      // The player probably wants to get the item out of the crucible.
      mode = HomeMode.GET;
      dirty();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, 'Welcome home, hero. ${mode.message}');

    terminal.writeAt(0, terminal.height - 1,
        '${mode.helpText}, [Esc] Exit',
        Color.GRAY);

    terminal.writeAt(0, 2, leftView.label);
    drawItems(terminal, 0, 3, leftView.getItems(save),
        (item) => mode.canSelectLeftItem(this, item));

    terminal.writeAt(50, 2, rightView.label);
    drawItems(terminal, 50, 3, rightView.getItems(save),
        (item) => mode.canSelectRightItem(this, item));

    if (rightView == HomeView.CRUCIBLE && completeRecipe != null) {
      terminal.writeAt(59, 2, "Press [Space] to forge item!", Color.YELLOW);
      
      if (completeRecipe.produces != null) {
        terminal.writeAt(50, rightView.getItems(save).length + 4,
            "Expected result: ${completeRecipe.produces}", Color.YELLOW);
      } else {
      terminal.writeAt(50, rightView.getItems(save).length + 4,
          "May create a random piece of equipment similar to", Color.YELLOW);
      terminal.writeAt(50, rightView.getItems(save).length + 5,
          "the placed item. Add coins to improve the quality", Color.YELLOW);
      terminal.writeAt(50, rightView.getItems(save).length + 6,
          "and chance of a successful forging.", Color.YELLOW);
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
}

/// Which items are currently being shown in the inventory.
class HomeView {
  static const INVENTORY = const HomeView(0);
  static const EQUIPMENT = const HomeView(1);
  static const HOME = const HomeView(2);
  static const CRUCIBLE = const HomeView(3);

  final int _value;

  const HomeView(this._value);

  /// Gets the display label for the view.
  String get label {
    switch (this) {
      case HomeView.INVENTORY: return 'Inventory';
      case HomeView.EQUIPMENT: return 'Equipment';
      case HomeView.HOME: return 'Home';
      case HomeView.CRUCIBLE: return 'Crucible';
    }

    throw "unreachable";
  }

  /// Gets the list of items for this view.
  ItemCollection getItems(HeroSave save) {
    switch (this) {
      case HomeView.INVENTORY: return save.inventory;
      case HomeView.EQUIPMENT: return save.equipment;
      case HomeView.HOME: return save.home;
      case HomeView.CRUCIBLE: return save.crucible;
    }

    throw "unreachable";
  }
}

/// What the user is currently doing on the home screen.
abstract class HomeMode {
  static final VIEW = const ViewHomeMode();
  static final PUT = const PutHomeMode();
  static final GET = const GetHomeMode();

  const HomeMode();

  String get message;
  String get helpText;
  bool canSelectLeftItem(HomeScreen home, Item item) => false;
  bool canSelectRightItem(HomeScreen home, Item item) => false;

  bool handleInput(Input input, HomeScreen home) => false;
  bool keyDown(int keyCode, HomeScreen home);
}

/// The default mode. Lets users switch which item lists are being shown on the
/// left and right sides, and choose an action to perform.
class ViewHomeMode extends HomeMode {
  const ViewHomeMode();

  String get message => 'What would you like to do?';
  String get helpText => '[Tab] Switch left, [H] Home, [C] Crucible, [E] Equipment, [G] Get, [P] Put';

  bool keyDown(int keyCode, HomeScreen home) {
    switch (keyCode) {
      case KeyCode.TAB:
        switch (home.leftView) {
          case HomeView.INVENTORY:
            home.leftView = HomeView.EQUIPMENT;
            if (home.rightView == HomeView.EQUIPMENT) {
              // Don't show equipment on both sides.
              home.rightView = HomeView.HOME;
            }
            break;

          case HomeView.EQUIPMENT:
            home.leftView = HomeView.HOME;
            if (home.rightView == HomeView.HOME) {
              // Don't show home on both sides.
              home.rightView = HomeView.CRUCIBLE;
            }
            break;

          case HomeView.HOME:
            home.leftView = HomeView.INVENTORY;
            break;
        }

        home.dirty();
        break;

      case KeyCode.H:
        home.rightView = HomeView.HOME;
        if (home.leftView == HomeView.HOME) {
          // Don't show home on both sides.
          home.leftView = HomeView.INVENTORY;
        }
        home.dirty();
        break;

      case KeyCode.C:
        home.rightView = HomeView.CRUCIBLE;
        home.dirty();
        break;

      case KeyCode.E:
        home.rightView = HomeView.EQUIPMENT;
        if (home.leftView == HomeView.EQUIPMENT) {
          // Don't show equipment on both sides.
          home.leftView = HomeView.INVENTORY;
        }
        home.dirty();
        break;

      case KeyCode.G:
        home.mode = HomeMode.GET;
        home.dirty();
        break;

      case KeyCode.P:
        home.mode = HomeMode.PUT;
        home.dirty();
        break;

      default:
        return false;
    }

    return true;
  }
}

/// Base class for a mode that lets a user select an item.
abstract class SelectHomeMode extends HomeMode {
  const SelectHomeMode();

  String get helpText => '[A-Z] Choose an item, [Esc] Cancel';

  bool handleInput(Input input, HomeScreen home) {
    if (input == Input.CANCEL) {
      home.mode = HomeMode.VIEW;
      home.dirty();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, HomeScreen home) {
    if (keyCode >= KeyCode.A && keyCode <= KeyCode.Z) {
      selectItem(home, keyCode - KeyCode.A);
      return true;
    }

    return false;
  }

  void selectItem(HomeScreen home, int index);
}

/// Mode for putting an item into the home, equipment, or crucible.
class PutHomeMode extends SelectHomeMode {
  const PutHomeMode();

  String get message => 'Put which item?';

  bool canSelectLeftItem(HomeScreen home, Item item) {
    // Can put anything in the home.
    if (home.rightView == HomeView.HOME) return true;

    // Can only put equippable items.
    if (home.rightView == HomeView.EQUIPMENT) {
      // TODO: This is a bit wonky. canEquip() assumes you can swap items,
      // which the home screen doesn't support.
      return home.save.equipment.canEquip(item);
    }

    // Can only put items in the crucible if they fit a recipe.
    final items = new List.from(home.rightView.getItems(home.save));
    items.add(item);
    return home.content.recipes.any((recipe) => recipe.allows(items));
  }

  bool canSelectRightItem(HomeScreen home, Item item) => false;

  void selectItem(HomeScreen home, int index) {
    var from = home.leftView.getItems(home.save);

    if (index >= from.length) return;
    var item = from[index];
    if (!canSelectLeftItem(home, item)) return;

    var to = home.rightView.getItems(home.save);

    if (to.tryAdd(item)) {
      from.removeAt(index);
    } else {
      // TODO: Show an error message?
    }

    if (home.rightView == HomeView.CRUCIBLE) home.refreshRecipe();
    home.dirty();
  }
}

/// Mode for "getting" an item from the home or crucible.
class GetHomeMode extends SelectHomeMode {
  const GetHomeMode();

  String get message => 'Pick up which item?';

  bool canSelectLeftItem(HomeScreen home, Item item) => false;
  bool canSelectRightItem(HomeScreen home, Item item) => true;

  void selectItem(HomeScreen home, int index) {
    var from = home.rightView.getItems(home.save);

    if (index >= from.length) return;
    var item = from[index];
    if (!canSelectRightItem(home, item)) return;

    var to = home.leftView.getItems(home.save);

    if (to.tryAdd(item)) {
      from.removeAt(index);

      // If we get the last item, automatically switch out of get mode.
      if (from.isEmpty) home.mode = HomeMode.VIEW;
    } else {
      // TODO: Show an error message?
    }

    if (home.rightView == HomeView.CRUCIBLE) home.refreshRecipe();
    home.dirty();
  }
}