class SelectLevelScreen extends Screen {
  final Content  content;
  final HeroHome home;
  final Function saveGame;
  int selectedArea = 0;
  int selectedLevel = 0;

  SelectLevelScreen(this.content, this.home, this.saveGame);

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

    case KeyCode.L:
      final game = new Game(content.areas[selectedArea], selectedLevel, home);
      ui.push(new GameScreen(home, game));
      break;
    }

    return true;
  }

  void render(Terminal terminal) {
    if (!isTopScreen) return;

    terminal.clear();
    terminal.writeAt(0, 0, 'Where shall you quest?');
    terminal.writeAt(0, terminal.height - 1,
        '[L] Select area, [O]/[.] Change area, [K]/[;] Change level',
        Color.GRAY);

    for (var i = 0; i < content.areas.length; i++) {
      write(int x, String text, int level) {
        var fore = Color.WHITE;
        var back = Color.BLACK;
        if ((i == selectedArea) &&
           ((level == selectedLevel) || (level == -1))) {
          fore = Color.BLACK;
          back = Color.YELLOW;
        }

        terminal.writeAt(x, 2 + i, text, fore, back);
      }

      final area = content.areas[i];
      write(0, area.name, -1);

      for (var level = 0; level < area.levels.length; level++) {
        write(50 + level * 3, (level + 1).toString(), level);
      }
    }
  }

  void activate(Screen screen, result) {
    if (screen is GameScreen && result) {
      // Left successfully, so save.
      saveGame();
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
