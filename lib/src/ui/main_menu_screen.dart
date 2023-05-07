import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'confirm_popup.dart';
import 'game_screen.dart';
import 'input.dart';
import 'new_hero_screen.dart';
import 'storage.dart';

const _chars = [
  r"______ ______                     _____                          _____",
  r"\ .  / \  . /                     \ . |                          \  .|",
  r" | .|   |. |                       | .|                           |. |",
  r" |. |___| .|   _____  _____ _____  |. | ___     ______  ____  ___ | .|  ____",
  r" |:::___:::|   \::::\ \:::| \:::|  |::|/:::\   /::::::\ \:::|/:::\|::| /::/",
  r" |xx|   |xx|  ___ \xx| |xx|  |xx|  |xx|  \xx\ |xx|__)xx| |xx|  \x||xx|/x/",
  r" |xx|   |xx| /xxx\|xx| |xx|  |xx|  |xx|   |xx||xx|\xxxx| |xx|     |xxxxxx\",
  r" |XX|   |XX||XX(__|XX| |XX\__|XX|  |XX|__/XXX||XX|_____  |XX|     |XX| \XX\_",
  r" |XX|   |XX| \XXXX/\XX\ \XXX/|XXX\/XXX/\XXXX/  \XXXXXX/ /XXXX\   /XXXX\ \XXX\",
  r" |XX|   |XX|_________________________________________________________________",
  r" |XX|   |XX||XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\",
  r"_|XX|   |XX|_",
  r"\XXX|   |XXX/",
  r" \XX|   |XX/",
  r"  \X|   |X/",
  r"   \|   |/",
];

const _charColors = [
  "LLLLLL LLLLLL                     LLLLL                          LLLLL",
  "ERRRRE ERRRRE                     ERRRE                          ERRRE",
  " ERRE   ERRE                       ERRE                           ERRE",
  " ERRELLLERRE   LLLLL  LLLLL LLLLL  ERRE LLL     LLLLLL  LLLL  LLL ERRE  LLLL",
  " ERRREEERRRE   ERRRRL ERRRE ERRRE  ERREERRRL   LRRRRRRL ERRRLLRRRLERRE LRRE",
  " ERRE   ERRE  LLL ERRE ERRE  ERRE  ERRE  ERRL ERRELLERRE ERRE  EREERRELRE",
  " EOOE   EOOE LOOOEEOOE EOOE  EOOE  EOOE   EOOEEOOEEOOOOE EOOE     EOOOOOOL",
  " EGGE   EGGEEGGELLEGGE EGGLLLEGGE  EGGELLLGGGEEGGELLLLL  EGGE     EGGE EGGLL",
  " EYYE   EYYE EYYYYEEYYE EYYYEEYYYLLYYYEEYYYYE  EYYYYYYE LYYYYL   LYYYYL EYYYL",
  " EYYE   EYYELLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL",
  " EYYE   EYYEEYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYL",
  "LEYYE   EYYEL",
  "EYYYE   EYYYE",
  " EYYE   EYYE",
  "  EYE   EYE",
  "   EE   EE",
];

const _colors = {
  "L": lightWarmGray,
  "E": warmGray,
  "R": red,
  "O": carrot,
  "G": gold,
  "Y": yellow
};

class MainMenuScreen extends Screen<Input> {
  final Content content;
  final Storage storage;
  int selectedHero = 0;

  MainMenuScreen(this.content) : storage = Storage(content);

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _changeSelection(-1);
        return true;
      case Input.s:
        _changeSelection(1);
        return true;

      case Input.ok:
        if (selectedHero < storage.heroes.length) {
          var save = storage.heroes[selectedHero];
          ui.push(GameScreen.town(storage, content, save));
        }
        return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.d:
        if (selectedHero < storage.heroes.length) {
          var name = storage.heroes[selectedHero].name;
          ui.push(
              ConfirmPopup("Are you sure you want to delete $name?", 'delete'));
        }
        return true;

      case KeyCode.n:
        ui.push(NewHeroScreen(content, storage));
        return true;
    }

    return false;
  }

  @override
  void activate(Screen popped, Object? result) {
    if (popped is ConfirmPopup && result == 'delete') {
      storage.heroes.removeAt(selectedHero);
      if (selectedHero > 0 && selectedHero >= storage.heroes.length) {
        selectedHero--;
      }
      storage.save();
      dirty();
    }
  }

  @override
  void render(Terminal terminal) {
    // Center everything horizontally.
    terminal =
        terminal.rect((terminal.width - 78) ~/ 2, 0, 80, terminal.height);

    terminal.writeAt(
        0,
        terminal.height - 1,
        '[L] Select a hero, [↕] Change selection, [N] Create a new hero, [D] Delete hero',
        UIHue.helpText);

    // Center the content vertically.
    terminal =
        terminal.rect(0, (terminal.height - 40) ~/ 2, terminal.width, 40);
    for (var y = 0; y < _chars.length; y++) {
      for (var x = 0; x < _chars[y].length; x++) {
        var color = _colors[_charColors[y][x]];
        terminal.writeAt(x + 1, y + 1, _chars[y][x], color);
      }
    }

    terminal.writeAt(10, 18, 'Which hero shall you play?', UIHue.text);

    if (storage.heroes.isEmpty) {
      terminal.writeAt(
          10, 20, '(No heroes. Please create a new one.)', UIHue.helpText);
    }

    for (var i = 0; i < storage.heroes.length; i++) {
      var hero = storage.heroes[i];

      var primary = UIHue.primary;
      var secondary = UIHue.secondary;
      if (i == selectedHero) {
        primary = UIHue.selection;
        secondary = UIHue.selection;

        terminal.drawChar(
            9, 20 + i, CharCode.blackRightPointingPointer, UIHue.selection);
      }

      terminal.writeAt(10, 20 + i, hero.name, primary);
      terminal.writeAt(30, 20 + i, "Level ${hero.level}", secondary);
      terminal.writeAt(40, 20 + i, hero.race.name, secondary);
      terminal.writeAt(50, 20 + i, hero.heroClass.name, secondary);
    }
  }

  void _changeSelection(int offset) {
    selectedHero = (selectedHero + offset) % storage.heroes.length;
    dirty();
  }
}
