library hauberk.ui.main_menu_screen;

import '../engine.dart';
import '../util.dart';
import 'confirm_dialog.dart';
import 'keyboard.dart';
import 'new_hero_screen.dart';
import 'screen.dart';
import 'select_level_screen.dart';
import 'storage.dart';
import 'terminal.dart';

class MainMenuScreen extends Screen {
  final Content content;
  final Storage storage;
  int selectedHero = 0;

  MainMenuScreen(Content content)
      : content = content,
        storage = new Storage(content);

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
    case KeyCode.O:
      _changeSelection(-1);
      break;

    case KeyCode.PERIOD:
      _changeSelection(1);
      break;

    case KeyCode.L:
    case KeyCode.ENTER:
      if (selectedHero < storage.heroes.length) {
        ui.push(new SelectLevelScreen(content, storage.heroes[selectedHero],
            storage));
      }
      break;

    case KeyCode.D:
      if (selectedHero < storage.heroes.length) {
        ui.push(new ConfirmDialog(
            "Are you sure you want to delete this hero?", 'delete'));
      }
      break;

    case KeyCode.N:
      ui.push(new NewHeroScreen(content, storage));
      break;
    }

    return true;
  }

  void activate(Screen screen, result) {
    if (screen is ConfirmDialog && result == 'delete') {
      storage.heroes.removeAt(selectedHero);
      if (selectedHero >= storage.heroes.length) selectedHero--;
      storage.save();
      dirty();
    }
  }

  void render(Terminal terminal) {
    if (!isTopScreen) return;

    terminal.clear();

    terminal.writeAt(0, 0,
        'Which hero shall you play?');
    terminal.writeAt(0, terminal.height - 1,
        '[L] Select a hero, [↕] Change selection, [N] Create a new hero, [D] Delete hero',
        Color.GRAY);

    if (storage.heroes.length == 0) {
      terminal.writeAt(0, 2, '(No heroes. Please create a new one.)',
          Color.GRAY);
    }

    for (var i = 0; i < storage.heroes.length; i++) {
      var hero = storage.heroes[i];

      var fore = Color.WHITE;
      var secondaryFore = Color.GRAY;
      var back = Color.BLACK;
      if (i == selectedHero) {
        fore = Color.BLACK;
        secondaryFore = Color.WHITE;
        back = Color.YELLOW;
      }

      terminal.writeAt(1, 2 + i, hero.name, fore, back);
      terminal.writeAt(20, 2 + i, "Level ${hero.level}", secondaryFore);
      terminal.writeAt(30, 2 + i, hero.heroClass.name, secondaryFore);
    }
  }

  void _changeSelection(int offset) {
    selectedHero = (selectedHero + offset) % storage.heroes.length;
    dirty();
  }
}
