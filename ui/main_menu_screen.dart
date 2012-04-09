
class MainMenuScreen extends Screen {
  final Content  content;
  final HeroHome home;
  int selectedArea = 0;
  int selectedLevel = 0;

  MainMenuScreen(this.content)
  : home = new HeroHome();

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
    case KeyCode.K:
      _changeSelection(selectedArea, selectedLevel - 1);
      break;

    case KeyCode.SEMICOLON:
      _changeSelection(selectedArea, selectedLevel + 1);
      break;

    case KeyCode.O:
      _changeSelection(selectedArea - 1, selectedLevel);
      break;

    case KeyCode.PERIOD:
      _changeSelection(selectedArea + 1, selectedLevel);
      break;

    case KeyCode.N:
      final game = new Game(content.areas[selectedArea], selectedLevel, home);
      ui.push(new GameScreen(home, game));
      break;
    }

    return true;
  }

  bool update() => false;

  void render(Terminal terminal) {
    if (!isTopScreen) return;

    terminal.clear();
    terminal.writeAt(1, 1, 'Welcome. Type "N" to enter the dungeon.');

    for (var i = 0; i < content.areas.length; i++) {
      write(int x, String text, int level) {
        var fore = Color.WHITE;
        var back = Color.BLACK;
        if ((i == selectedArea) &&
           ((level == selectedLevel) || (level == -1))) {
          fore = Color.BLACK;
          back = Color.YELLOW;
        }

        terminal.writeAt(x, 3 + i, text, fore, back);
      }

      final area = content.areas[i];
      write(1, area.name, -1);

      for (var level = 0; level < area.levels.length; level++) {
        write(50 + level * 3, (level + 1).toString(), level);
      }
    }
  }

  void _changeSelection(int area, int level) {
    if (area < 0) area = 0;
    if (area >= content.areas.length) {
      area = content.areas.length - 1;
    }

    selectedArea = area;

    if (level < 0) level = 0;
    if (level >= content.areas[selectedArea].levels.length) {
      level = content.areas[selectedArea].levels.length - 1;
    }

    selectedLevel = level;
    dirty();
  }
}
