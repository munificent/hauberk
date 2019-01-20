import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'hero_info_dialog.dart';

class HeroResistancesDialog extends HeroInfoDialog {
  HeroResistancesDialog(Content content, HeroSave hero)
      : super.base(content, hero);

  String get name => "Resistances";

  void render(Terminal terminal) {
    super.render(terminal);

    writeLine(int y, Color color) {
      terminal.writeAt(
          2,
          y,
          "───────────────────────────────────────────── "
          "── ── ── ── ── ── ── ── ── ── ──",
          color);
    }

    terminal.writeAt(48, 0, "══════════ Resistances ═════════", darkCoolGray);
    drawEquipmentTable(terminal, (item, y) {
      writeLine(y - 1, darkerCoolGray);

      if (item == null) return;

      var i = 0;
      for (var element in content.elements) {
        if (element == Element.none) continue;

        var x = 48 + i * 3;
        var resistance = item.resistance(element);
        var string = resistance.toString().padLeft(2);
        if (resistance > 0) {
          terminal.writeAt(x, y, string, peaGreen);
        } else if (resistance < 0) {
          terminal.writeAt(x, y, string, red);
        }

        i++;
      }
    });

    var totalY = 21;
    terminal.writeAt(41, totalY, "Totals", coolGray);

    writeLine(2, darkCoolGray);
    writeLine(totalY - 1, darkCoolGray);

    var i = 0;
    for (var element in content.elements) {
      if (element == Element.none) continue;

      var x = 48 + i * 3;
      terminal.writeAt(x, 1, element.abbreviation, elementColor(element));

      // Show the total resistance.
      var resistance = hero.equipmentResistance(element);
      var color = darkCoolGray;
      if (resistance > 0) {
        color = peaGreen;
      } else if (resistance < 0) {
        color = red;
      }

      terminal.writeAt(x, totalY, resistance.toString().padLeft(2), color);
      i++;
    }
  }
}
