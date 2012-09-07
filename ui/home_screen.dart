class HomeScreen extends Screen {
  final Content  content;
  final HeroSave save;
  HomeView view = HomeView.INVENTORY;
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
    terminal.writeAt(0, 0, 'Welcome home, hero.');

    terminal.writeAt(0, terminal.height - 1,
        '${mode.helpText}, [Esc] Exit',
        Color.GRAY);

    terminal.writeAt(0, 2, view.label);
    drawItems(terminal, 0, 3, view.getItems(save),
        (item) => mode.canSelectItem(item));
  }
}


/// Which items are currently being shown in the inventory.
class HomeView {
  static final INVENTORY = const HomeView(0);
  static final EQUIPMENT = const HomeView(1);
  static final HOME = const HomeView(2);

  final int _value;

  const HomeView(this._value);

  /// Gets the display label for the view.
  String get label {
    switch (this) {
      case HomeView.INVENTORY: return 'Inventory';
      case HomeView.EQUIPMENT: return 'Equipment';
      case HomeView.HOME: return 'Home';
    }
  }

  /// Gets the next view, rotating through all of them.
  HomeView get next {
    switch (this) {
      case HomeView.INVENTORY: return HomeView.EQUIPMENT;
      case HomeView.EQUIPMENT: return HomeView.HOME;
      case HomeView.HOME: return HomeView.INVENTORY;
    }

    assert(false); // Unreachable.
  }

  /// Gets the list of items for this view.
  Iterable<Item> getItems(HeroSave save) {
    switch (this) {
      case HomeView.INVENTORY: return save.inventory;
      case HomeView.EQUIPMENT: return save.equipment;
      case HomeView.HOME: return save.home;
    }

    assert(false); // Unreachable.
  }
}

/// What the user is currently doing on the home screen.
class HomeMode {
  static final VIEW = const ViewHomeMode();

  const HomeMode();

  abstract String get helpText;
  abstract bool canSelectItem(Item item);
  abstract bool handleInput(Keyboard keyboard, HomeScreen home);
}

class ViewHomeMode extends HomeMode {
  const ViewHomeMode();

  String get helpText => '[Tab] Switch view';

  bool canSelectItem(Item item) => false;

  bool handleInput(Keyboard keyboard, HomeScreen home) {
    switch (keyboard.lastPressed) {
      case KeyCode.TAB:
        home.view = home.view.next;
        home.dirty();
        break;

      default:
        return false;
    }

    return true;
  }
}
