library dngn.ui.select_level_screen;

import 'dart:math' as math;

import '../engine.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'skills_screen.dart';
import 'storage.dart';
import 'terminal.dart';

class SelectLevelScreen extends Screen {
  final Content  content;
  final HeroSave save;
  final Storage storage;
  int selectedArea = 0;
  int selectedLevel = 0;

  SelectLevelScreen(this.content, this.save, this.storage);

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
      final game = new Game(content.areas[selectedArea], selectedLevel,
          content, save);
      ui.push(new GameScreen(save, game));
      break;

    case KeyCode.H:
      ui.push(new HomeScreen(content, save));
      break;

    case KeyCode.S:
      ui.push(new SkillsScreen(content, save));
      break;

    case KeyCode.ESCAPE:
      ui.pop();
      break;
    }

    return true;
  }

  void render(Terminal terminal) {
    if (!isTopScreen) return;

    terminal.clear();
    terminal.writeAt(0, 0, 'Greetings, ${save.name}, where shall you quest?');
    terminal.writeAt(0, terminal.height - 1,
        '[L] Select area, [↕] Select area, [↔] Select level, [H] Enter home, [S] Skills',
        Color.GRAY);

    for (var i = 0; i < content.areas.length; i++) {
      final area = content.areas[i];

      write(int x, String text, int level) {
        var fore = Color.WHITE;
        var back = Color.BLACK;
        if ((i == selectedArea) &&
           ((level == selectedLevel) || (level == -1))) {
          fore = Color.BLACK;
          back = Color.YELLOW;
        }

        // Can only select one past the completed level.
        if (level > getCompletedLevel(area)) {
          fore = Color.DARK_GRAY;
        }

        terminal.writeAt(x, 2 + i, text, fore, back);
      }

      write(0, area.name, -1);

      var completed = save.completedLevels[area.name];
      if (completed == null) completed = 0;

      for (var level = 0; level < area.levels.length; level++) {
        write(50 + level * 3, (level + 1).toString(), level);
      }
    }
  }

  void activate(Screen screen, result) {
    if (screen is GameScreen && result) {
      // Left successfully, so save.
      storage.save();
    } else if (screen is HomeScreen || screen is SkillsScreen) {
      // Always save when leaving the home.
      storage.save();
    }
  }

  void _changeSelection(int area, int level) {
    if (area < 0) area = 0;
    if (area >= content.areas.length) {
      area = content.areas.length - 1;
    }

    selectedArea = area;

    var maxLevel = math.min(content.areas[selectedArea].levels.length,
                       getCompletedLevel(content.areas[selectedArea]) + 1);

    if (level < 0) level = 0;
    if (level >= maxLevel) level = maxLevel - 1;

    selectedLevel = level;
    dirty();
  }

  /// Gets the one-based index of the highest completed level in [area].
  /// Returns `0` if no levels have been completed.
  int getCompletedLevel(Area area) {
    var level = save.completedLevels[area.name];
    if (level == null) return 0;
    return level;
  }
}
