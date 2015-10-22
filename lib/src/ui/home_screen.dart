library hauberk.ui.home_screen;

import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';
import 'item_dialog.dart';

class HomeScreen extends Screen {
  final Content  content;
  final HeroSave save;

  /// Which views are shown on each side.
  final Map<Side, HomeView> views = {
    Side.LEFT: HomeView.INVENTORY,
    Side.RIGHT: HomeView.HOME
  };

  HomeView get leftView => views[Side.LEFT];
  set leftView(HomeView value) {
    views[Side.LEFT] = value;
  }

  HomeView get rightView => views[Side.RIGHT];
  set rightView(HomeView value) {
    views[Side.RIGHT] = value;
  }

  HomeMode mode = HomeMode.VIEW;

  /// Which side has keyboard focus.
  Side active = Side.LEFT;

  /// If the crucible contains a complete recipe, this will be it. Otherwise,
  /// this will be `null`.
  Recipe completeRecipe;

  HomeScreen(this.content, this.save);

  bool handleInput(Input input) {
    if (mode.handleInput(input, this)) return true;

    switch (input) {
      case Input.CANCEL:
        ui.pop();
        break;

      // Switch columns.
      case Input.E:
        active = Side.RIGHT;
        break;

      case Input.W:
        active = Side.LEFT;
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
      if (active == Side.LEFT) {
        rightView = HomeView.CRUCIBLE;
      } else {
        leftView = HomeView.INVENTORY;
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
        Color.gray);

    drawSide(Side side, int x) {
      var view = views[side];

      if (active == side && mode == HomeMode.VIEW) {
        terminal.writeAt(x, 2, view.label, Color.black, Color.yellow);
      } else {
        terminal.writeAt(x, 2, view.label);
      }

      canSelect(Item item) => mode.canSelectItem(this, side, item);

      drawItems(terminal, x, 3, view.getItems(this), canSelect);
    }

    drawSide(Side.LEFT, 0);
    drawSide(Side.RIGHT, 50);

    if (rightView == HomeView.CRUCIBLE && completeRecipe != null) {
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
}

/// Identifies the two columns on the screen.
enum Side {
  LEFT,
  RIGHT
}

/// Which items are currently being shown in the inventory.
class HomeView {
  static const INVENTORY = const HomeView('Inventory', allowOnRight: false);
  static const EQUIPMENT = const HomeView('Equipment');
  static const HOME = const HomeView('Home');
  static const CRUCIBLE = const HomeView('Crucible', allowOnLeft: false);

  static const List<HomeView> _all = const [
    INVENTORY,
    EQUIPMENT,
    HOME,
    CRUCIBLE
  ];

  /// The display label for the view.
  final String label;

  /// Which columns this view may be seen on.
  final bool allowOnLeft;
  final bool allowOnRight;

  const HomeView(this.label, {this.allowOnLeft: true, this.allowOnRight: true});

  HomeView get next => _all[(_all.indexOf(this) + 1) % _all.length];

  HomeView get previous => _all[(_all.indexOf(this) - 1) % _all.length];

  /// Gets the list of items for this view.
  ItemCollection getItems(HomeScreen home) {
    switch (this) {
      case HomeView.INVENTORY: return home.save.inventory;
      case HomeView.EQUIPMENT: return home.save.equipment;
      case HomeView.HOME: return home.save.home;
      case HomeView.CRUCIBLE: return home.save.crucible;
    }

    throw "unreachable";
  }

  /// Returns `true` if the view is allowed on [side].
  bool allowedOnSide(Side side) =>
      side == Side.LEFT ? allowOnLeft : allowOnRight;
}

/// What the user is currently doing on the home screen.
abstract class HomeMode {
  static final VIEW = const ViewHomeMode();
  static final PUT = const PutHomeMode();
  static final GET = const GetHomeMode();

  const HomeMode();

  String get message;
  String get helpText;

  bool canSelectItem(HomeScreen home, Side side, Item item) => false;

  bool handleInput(Input input, HomeScreen home) => false;
  bool keyDown(int keyCode, HomeScreen home);
}

/// The default mode. Lets users switch which item lists are being shown on the
/// left and right sides, and choose an action to perform.
class ViewHomeMode extends HomeMode {
  const ViewHomeMode();

  String get message => 'What would you like to do?';
  String get helpText => '[↔] Select column, [↕] Select source, [G] Get, [P] Put';

  bool keyDown(int keyCode, HomeScreen home) {
    switch (keyCode) {
      case KeyCode.g: home.mode = HomeMode.GET; break;
      case KeyCode.p: home.mode = HomeMode.PUT; break;

      default:
        return false;
    }

    home.dirty();
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
    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      selectItem(home, keyCode - KeyCode.a);
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

  bool canSelectItem(HomeScreen home, Side side, Item item) {
    if (side == Side.RIGHT) return false;

    // Can put anything in the home.
    if (home.rightView == HomeView.HOME) return true;

    // Can only put equippable items.
    if (home.rightView == HomeView.EQUIPMENT) {
      // TODO: This is a bit wonky. canEquip() assumes you can swap items,
      // which the home screen doesn't support.
      return home.save.equipment.canEquip(item);
    }

    // Can only put items in the crucible if they fit a recipe.
    var items = new List.from(home.rightView.getItems(home));
    items.add(item);
    return home.content.recipes.any((recipe) => recipe.allows(items));
  }

  void selectItem(HomeScreen home, int index) {
    var from = home.leftView.getItems(home);

    if (index >= from.length) return;
    var item = from[index];
    if (!canSelectItem(home, Side.LEFT, item)) return;

    var to = home.rightView.getItems(home);

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

  bool canSelectItem(HomeScreen home, Side side, Item item) {
    return side == Side.RIGHT;
  }

  void selectItem(HomeScreen home, int index) {
    var from = home.rightView.getItems(home);

    if (index >= from.length) return;
    var item = from[index];

    var to = home.leftView.getItems(home);

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