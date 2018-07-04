import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'hero_equipment_dialog.dart';
import 'hero_lore_dialog.dart';
import 'hero_resistances_dialog.dart';
import 'input.dart';

abstract class HeroInfoDialog extends Screen<Input> {
  Hero hero;
  HeroInfoDialog _nextScreen;

  factory HeroInfoDialog(Hero hero) {
    var screens = [
      HeroEquipmentDialog(hero),
      HeroResistancesDialog(hero),
      HeroLoreDialog(hero)
    ];

    for (var i = 0; i < screens.length; i++) {
      screens[i]._nextScreen = screens[(i + 1) % screens.length];
    }

    return screens.first;
  }

  HeroInfoDialog.base(this.hero);

  String get name;
  String get extraHelp => null;

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode == KeyCode.tab) {
      ui.goTo(_nextScreen);
      return true;
    }

    return false;
  }

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.clear();

    var helpText = '[Esc] Exit, [Tab] View ${_nextScreen.name}';
    if (extraHelp != null) {
      helpText += ", $extraHelp";
    }

    terminal.writeAt(0, terminal.height - 1, helpText, slate);
  }

  void drawEquipmentTable(
      Terminal terminal, void Function(Item item, int y) callback) {
    terminal.writeAt(2, 1, "Equipment", gold);

    var y = 3;
    for (var slot in hero.equipment.slotTypes) {
      var item = hero.equipment.find(slot);
      callback(item, y);

      if (item == null) {
        terminal.writeAt(2, y, "(${slot})", steelGray);
        y += 2;
        continue;
      }

      terminal.drawGlyph(0, y, item.appearance);
      terminal.writeAt(2, y, item.nounText, ash);

      y += 2;
    }
  }
}
