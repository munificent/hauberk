part of ui;

class Screen {
  UserInterface _ui;

  UserInterface get ui => _ui;

  void _bind(UserInterface ui) {
    assert(ui == null);
    _ui = ui;
  }

  void _unbind() {
    assert(_ui != null);
    _ui = null;
  }

  bool get isTopScreen => _ui.isTopScreen(this);

  void dirty() {
    // If we aren't bound (yet), just do nothing. The screen will be dirtied
    // when it gets bound.
    if (_ui == null) return;

    _ui.dirty();
  }

  bool handleInput(Keyboard keyboard) => false;

  /// Called when the screen above this one ([popped]) has been popped and this
  /// screen is now the top-most screen. If a value was passed to [pop()], it
  /// will be passed to this as [result].
  void activate(Screen popped, result) {}

  void update() {}
  void render(Terminal terminal) {}
}

class UserInterface {
  final Keyboard      _keyboard;
  final List<Screen>  _screens;
  RenderableTerminal _terminal;
  bool _dirty;

  UserInterface(this._keyboard, this._terminal)
  : _screens = <Screen>[];

  void setTerminal(RenderableTerminal terminal) {
    _terminal = terminal;
    dirty();
  }

  void push(Screen screen) {
    screen._bind(this);
    _screens.add(screen);
    _render();
  }

  void pop([result]) {
    final screen = _screens.removeLast();
    screen._unbind();
    _screens[_screens.length - 1].activate(screen, result);
    _render();
  }

  void goTo(Screen screen) {
    final old = _screens.removeLast();
    old._unbind();

    screen._bind(this);
    _screens.add(screen);
    _render();
  }

  void dirty() { _dirty = true; }

  bool isTopScreen(Screen screen) => _screens.last == screen;

  void tick() {
    // Input is given to the screens from top to bottom, and stops when a
    // screen consumes it.
    for (var i = _screens.length - 1; i >= 0; i--) {
      if (_screens[i].handleInput(_keyboard)) break;
    }

    for (final screen in _screens) screen.update();

    _keyboard.afterUpdate();

    if (_dirty) _render();
  }

  void _render() {
    for (final screen in _screens) screen.render(_terminal);

    _dirty = false;
    _terminal.render();
  }
}