
class MainMenuScreen extends Screen {
  final Content  content;
  final HeroHome home;

  MainMenuScreen(this.content)
  : home = new HeroHome();

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
    case KeyCode.N:
      final game = new Game(content, home);
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
  }
}
