library hauberk.ui.main_menu_screen;

import 'package:malison/malison.dart';

import '../engine.dart';
import 'confirm_dialog.dart';
import 'new_hero_screen.dart';
import 'select_level_screen.dart';
import 'storage.dart';


const _CHARS = const [
  r"______   ______                          _____                               _____",
  r"\ .  /   \  . /                          \ . |                               \  .|",
  r" | .|     |. |                            | .|                                |. |",
  r" |. |_____| .|    _______   _____  _____  |. | _____      _______  ____  ____ | .|   ____",
  r" |:::_____:::|    \::::::\  \:::|  \:::|  |::|/:::::\    /:::::::\ \:::|/::::\|::|  /::/",
  r" |xx|     |xx|   _____ \xx|  |xx|   |xx|  |xx|    \xx\  |xx|___)xx| |xx|   \x||xx|_/x/",
  r" |xx|     |xx|  /xxxxx\|xx|  |xx|   |xx|  |xx|     |xx| |xx|\xxxxx| |xx|      |xxxxxxx\",
  r" |XX|     |XX| |XX(____|XX|  |XX\___|XX|  |XX|____/XXX| |XX|______  |XX|      |XX|  \XX\_",
  r" |XX|     |XX|  \XXXXXX/\XX\  \XXXX/|XXX\/XXX/\XXXXXX/   \XXXXXXX/ /XXXX\    /XXXX\  \XXX\",
  r" |XX|     |XX| ____________________________________________________________________________",
  r" |XX|     |XX| |XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\",
  r"_|XX|     |XX|_",
  r"\XXX|     |XXX/",
  r" \XX|     |XX/",
  r"  \X|     |X/",
  r"   \|     |/",
];

const _CHAR_COLORS = const [
  "LLLLLL   LLLLLL                          LLLLL                               LLLLL",
  "ERRRRE   ERRRRE                          ERRRE                               ERRRE",
  " ERRE     ERRE                            ERRE                                ERRE",
  " ERRELLLLLERRE    LLLLLLL   LLLLL  LLLLL  ERRE LLLLL      LLLLLLL  LLLL  LLLL ERRE   LLLL",
  " ERRREEEEERRRE    ERRRRRRL  ERRRE  ERRRE  ERREERRRRRL    LRRRRRRRL ERRRLLRRRRLERRE  LRRE",
  " ERRE     ERRE   LLLLL ERRE  ERRE   ERRE  ERRE    ERRL  ERRELLLERRE ERRE   EREERRELLRE",
  " EOOE     EOOE  LOOOOOEEOOE  EOOE   EOOE  EOOE     EOOE EOOEEOOOOOE EOOE      EOOOOOOOL",
  " EGGE     EGGE EGGELLLLEGGE  EGGLLLLEGGE  EGGELLLLLGGGE EGGELLLLLL  EGGE      EGGE  EGGLL",
  " EYYE     EYYE  EYYYYYYEEYYE  EYYYY/EYYYLLYYYEEYYYYYYE   EYYYYYYYE LYYYYL    LYYYYL  EYYYL",
  " EYYE     EYYE LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL",
  " EYYE     EYYE EYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYL",
  "LEYYE     EYYEL",
  "EYYYE     EYYYE",
  " EYYE     EYYE",
  "  EYE     EYE",
  "   EE     EE",
];

const _COLORS = const {
  "L": Color.LIGHT_GRAY,
  "E": Color.GRAY,
  "R": Color.RED,
  "O": Color.ORANGE,
  "G": Color.GOLD,
  "Y": Color.YELLOW
};

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

    for (var y = 0; y < _CHARS.length; y++) {
      for (var x = 0; x < _CHARS[y].length; x++) {
        var color = _COLORS[_CHAR_COLORS[y][x]];
        terminal.writeAt(x + 4, y + 1, _CHARS[y][x], color);
      }
    }

    terminal.writeAt(25, 18,
        'Which hero shall you play?');
    terminal.writeAt(0, terminal.height - 1,
        '[L] Select a hero, [↕] Change selection, [N] Create a new hero, [D] Delete hero',
        Color.GRAY);

    if (storage.heroes.length == 0) {
      terminal.writeAt(25, 20, '(No heroes. Please create a new one.)',
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

      terminal.writeAt(26, 20 + i, hero.name, fore, back);
      terminal.writeAt(45, 20 + i, "Level ${hero.level}", secondaryFore);
      terminal.writeAt(55, 20 + i, hero.heroClass.name, secondaryFore);
    }
  }

  void _changeSelection(int offset) {
    selectedHero = (selectedHero + offset) % storage.heroes.length;
    dirty();
  }
}
