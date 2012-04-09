class Screen {
  UserInterface _ui;
  bool _dirty;

  UserInterface get ui() => _ui;

  void _bind(UserInterface ui) {
    assert(ui == null);
    _ui = ui;
  }

  void _unbind() {
    assert(_ui != null);
    _ui = null;
  }

  bool get isTopScreen() => _ui.isTopScreen(this);

  void dirty() { _dirty = true; }

  abstract bool handleInput(Keyboard keyboard);
  abstract bool update();
  abstract void render(Terminal terminal);
}

class UserInterface {
  final Keyboard     _keyboard;
  final Terminal     _terminal;
  final List<Screen> _screens;

  UserInterface(this._keyboard, this._terminal)
  : _screens = <Screen>[];

  void push(Screen screen) {
    screen._bind(this);
    _screens.add(screen);
    _render();
  }

  void pop() {
    final screen = _screens.removeLast();
    screen._unbind();
    _render();
  }

  void goTo(Screen screen) {
    final old = _screens.removeLast();
    old._unbind();

    screen._bind(this);
    _screens.add(screen);
    _render();
  }

  bool isTopScreen(Screen screen) => _screens.last() == screen;

  void tick() {
    // Input is given to the screens from top to bottom, and stops when a
    // screen consumes it.
    for (var i = _screens.length - 1; i >= 0; i--) {
      if (_screens[i].handleInput(_keyboard)) break;
    }

    var needsRender = false;
    for (final screen in _screens) {
      needsRender = needsRender || screen.update() || screen._dirty;
    }

    _keyboard.afterUpdate();

    if (needsRender) _render();
  }

  void _render() {
    for (final screen in _screens) {
      screen.render(_terminal);
      screen._dirty = false;
    }

    _terminal.render();
  }
}