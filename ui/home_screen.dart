class HomeScreen extends Screen {
  final Content  content;
  final HeroSave save;
  HomeView leftView = HomeView.INVENTORY;
  HomeView rightView = HomeView.HOME;
  HomeMode mode = HomeMode.VIEW;

  HomeScreen(this.content, this.save);

  bool handleInput(Keyboard keyboard) {
    if (mode.handleInput(keyboard, this)) return true;

    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        ui.pop();
        break;
    }

    return true;
  }

  void render(Terminal terminal) {
    if (!isTopScreen) return;

    terminal.clear();
    terminal.writeAt(0, 0, 'Welcome home, hero. ${mode.message}');

    terminal.writeAt(0, terminal.height - 1,
        '${mode.helpText}, [Esc] Exit',
        Color.GRAY);

    terminal.writeAt(0, 2, leftView.label);
    drawItems(terminal, 0, 3, leftView.getItems(save),
        (item) => mode.canSelectLeftItem(item));

    terminal.writeAt(50, 2, rightView.label);
    drawItems(terminal, 50, 3, rightView.getItems(save),
        (item) => mode.canSelectRightItem(item));
  }
}


/// Which items are currently being shown in the inventory.
class HomeView {
  static final INVENTORY = const HomeView(0);
  static final EQUIPMENT = const HomeView(1);
  static final HOME = const HomeView(2);
  static final CRUCIBLE = const HomeView(3);

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
  }

  /// Gets the list of items for this view.
  ItemCollection getItems(HeroSave save) {
    switch (this) {
      case HomeView.INVENTORY: return save.inventory;
      case HomeView.EQUIPMENT: return save.equipment;
      case HomeView.HOME: return save.home;
      case HomeView.CRUCIBLE: return save.crucible;
    }

    assert(false); // Unreachable.
  }
}

/// What the user is currently doing on the home screen.
class HomeMode {
  static final VIEW = const ViewHomeMode();
  static final DROP = const DropHomeMode();
  static final GET = const GetHomeMode();

  const HomeMode();

  abstract String get message;
  abstract String get helpText;
  bool canSelectLeftItem(Item item) => false;
  bool canSelectRightItem(Item item) => false;
  abstract bool handleInput(Keyboard keyboard, HomeScreen home);
}

/// The default mode. Lets users switch which item lists are being shown on the
/// left and right sides, and choose an action to perform.
class ViewHomeMode extends HomeMode {
  const ViewHomeMode();

  String get message => 'What would you like to do?';
  String get helpText => '[Tab] Switch left, [H] Show home, [C] Show crucible, [E] Show equipment, [D] Drop item, [G] Get item';

  bool handleInput(Keyboard keyboard, HomeScreen home) {
    switch (keyboard.lastPressed) {
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

      case KeyCode.D:
        home.mode = HomeMode.DROP;
        home.dirty();
        break;

      case KeyCode.G:
        home.mode = HomeMode.GET;
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

  bool handleInput(Keyboard keyboard, HomeScreen home) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        home.mode = HomeMode.VIEW;
        home.dirty();
        break;

      case KeyCode.A: selectItem(home, 0); break;
      case KeyCode.B: selectItem(home, 1); break;
      case KeyCode.C: selectItem(home, 2); break;
      case KeyCode.D: selectItem(home, 3); break;
      case KeyCode.E: selectItem(home, 4); break;
      case KeyCode.F: selectItem(home, 5); break;
      case KeyCode.G: selectItem(home, 6); break;
      case KeyCode.H: selectItem(home, 7); break;
      case KeyCode.I: selectItem(home, 8); break;
      case KeyCode.J: selectItem(home, 9); break;
      case KeyCode.K: selectItem(home, 10); break;
      case KeyCode.L: selectItem(home, 11); break;
      case KeyCode.M: selectItem(home, 12); break;
      case KeyCode.N: selectItem(home, 13); break;
      case KeyCode.O: selectItem(home, 14); break;
      case KeyCode.P: selectItem(home, 15); break;
      case KeyCode.Q: selectItem(home, 16); break;
      case KeyCode.R: selectItem(home, 17); break;
      case KeyCode.S: selectItem(home, 18); break;
      case KeyCode.T: selectItem(home, 19); break;
      case KeyCode.U: selectItem(home, 20); break;
      case KeyCode.V: selectItem(home, 21); break;
      case KeyCode.W: selectItem(home, 22); break;
      case KeyCode.X: selectItem(home, 23); break;
      case KeyCode.Y: selectItem(home, 24); break;
      case KeyCode.Z: selectItem(home, 25); break;

      default:
        return false;
    }

    return true;
  }

  abstract void selectItem(HomeScreen home, int index);
}

/// Mode for "dropping" an item into the home or crucible.
class DropHomeMode extends SelectHomeMode {
  const DropHomeMode();

  String get message => 'Drop which item?';

  bool canSelectLeftItem(Item item) => true;
  bool canSelectRightItem(Item item) => false;

  void selectItem(HomeScreen home, int index) {
    var from = home.leftView.getItems(home.save);

    if (index >= from.length) return;
    var item = from[index];
    if (!canSelectLeftItem(item)) return;

    var to = home.rightView.getItems(home.save);

    if (to.tryAdd(item)) {
      from.removeAt(index);
    } else {
      // TODO(bob): Show an error message?
    }

    home.dirty();
  }
}

/// Mode for "getting" an item from the home or crucible.
class GetHomeMode extends SelectHomeMode {
  const GetHomeMode();

  String get message => 'Pick up which item?';

  bool canSelectLeftItem(Item item) => false;
  bool canSelectRightItem(Item item) => true;

  void selectItem(HomeScreen home, int index) {
    var from = home.rightView.getItems(home.save);

    if (index >= from.length) return;
    var item = from[index];
    if (!canSelectRightItem(item)) return;

    var to = home.leftView.getItems(home.save);

    if (to.tryAdd(item)) {
      from.removeAt(index);
    } else {
      // TODO(bob): Show an error message?
    }

    home.dirty();
  }
}