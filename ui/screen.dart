class Screen {
  UserInterface _ui;

  void _bind(UserInterface ui) {
    assert(ui == null);
    _ui = ui;
  }

  void _unbind() {
    assert(_ui != null);
    _ui = null;
  }

  abstract bool update(UserInput input);
  abstract void render(Terminal terminal);
}

class UserInterface {
  final UserInput    _input;
  final Terminal     _terminal;
  final List<Screen> _screens;

  UserInterface(this._input, this._terminal)
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

  void update() {
    var needsRender = false;
    for (final screen in _screens) {
      needsRender = needsRender || screen.update(_input);
    }

    if (needsRender) _render();
  }

  void _render() {
    for (final screen in _screens) {
      screen.render(_terminal);
    }
  }
}