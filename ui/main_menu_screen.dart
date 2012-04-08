
class MainMenuScreen extends Screen {
  final Content  content;
  final HeroHome home;

  MainMenuScreen(this.content)
  : home = new HeroHome();

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
    case KeyCode.N:
      final game = new Game(content.areas[0], 0, home);
      ui.push(new GameScreen(home, game));
      break;
    }

    return true;
  }

  bool update() {
    return false;
  }

  void render(Terminal terminal) {
    if (!isTopScreen) return;

    terminal.clear();
    terminal.writeAt(1, 1, 'Welcome. Type "N" to enter the dungeon.');

    for (var i = 0; i < content.areas.length; i++) {
      final area = content.areas[i];
      terminal.writeAt(1, 3 + i, area.name);
      terminal.writeAt(50, 3 + i, area.levels.length.toString());
    }
  }
}
