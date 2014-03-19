library ui.new_hero_screen;

import '../engine.dart';
import '../util.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'select_level_screen.dart';
import 'storage.dart';
import 'terminal.dart';

// From: http://medieval.stormthecastle.com/medieval-names.htm.
const _DEFAULT_NAMES = const [
  "Merek", "Carac", "Ulric", "Tybalt", "Borin", "Sadon", "Terrowin", "Rowan",
  "Forthwind", "Althalos", "Fendrel", "Brom", "Hadrian", "Crewe", "Bolbec",
  "Fenwick", "Mowbray", "Drake", "Bryce", "Leofrick", "Letholdus", "Lief",
  "Barda", "Rulf", "Robin", "Gavin", "Terrin", "Jarin", "Cedric", "Gavin",
  "Josef", "Janshai", "Doran", "Asher", "Quinn", "Xalvador", "Favian",
  "Destrian", "Dain", "Millicent", "Alys", "Ayleth", "Anastas", "Alianor",
  "Cedany", "Ellyn", "Helewys", "Malkyn", "Peronell", "Thea", "Gloriana",
  "Arabella", "Hildegard", "Brunhild", "Adelaide", "Beatrix", "Emeline",
  "Mirabelle", "Helena", "Guinevere", "Isolde", "Maerwynn", "Catrain",
  "Gussalen", "Enndolynn", "Krea", "Dimia", "Aleida"
];

class NewHeroScreen extends Screen {
  final Content content;
  final Storage storage;

  String defaultName = rng.item(_DEFAULT_NAMES);
  String name = "";

  NewHeroScreen(this.content, this.storage) {}

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ENTER:
        var hero = content.createHero(name.isEmpty ? defaultName : name);
        storage.heroes.add(hero);
        storage.save();
        ui.goTo(new SelectLevelScreen(content, hero, storage));
        break;

      case KeyCode.ESCAPE:
        ui.pop();
        break;

      case KeyCode.DELETE:
        if (name.length > 0) {
          name = name.substring(0, name.length - 1);

          // Pick a new random name.
          if (name.length == 0) {
            defaultName = rng.item(_DEFAULT_NAMES);
          }

          dirty();
        }
        break;

      case KeyCode.SPACE:
        // TODO(bob): Handle modifiers.
        name = '$name ';
        dirty();
        break;

      default:
        var key = keyboard.lastPressed;
        if (key == null) break;

        if (key >= KeyCode.A && key <= KeyCode.Z) {
          // TODO(bob): Use +=.
          var charCode = key;
          // TODO(bob): Handle other modifiers.
          if (!keyboard.shift) {
            charCode = 'a'.codeUnits[0] - 'A'.codeUnits[0] + charCode;
          }
          name = '$name${new String.fromCharCodes([charCode])}';
          dirty();
        } else if (key >= KeyCode.ZERO && key <= KeyCode.NINE) {
          name = '$name${new String.fromCharCodes([key])}';
          dirty();
        }

        break;
    }

    return true;
  }

  void render(Terminal terminal) {
    terminal.clear();

    terminal.writeAt(0, 0,
        "What name shall the bards use to sing of your hero's adventures?");

    if (name.isEmpty) {
      terminal.writeAt(0, 2, defaultName, Color.BLACK, Color.YELLOW);
    } else {
      terminal.writeAt(0, 2, name);
      terminal.writeAt(name.length, 2, " ", Color.BLACK, Color.YELLOW);
    }

    terminal.writeAt(0, terminal.height - 1,
        '[A-Z] Enter name, [Del] Delete letter, [Enter] Create hero, [Esc] Cancel', Color.GRAY);
  }
}
