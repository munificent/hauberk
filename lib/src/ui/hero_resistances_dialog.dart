import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'hero_info_dialog.dart';

class HeroResistancesDialog extends HeroInfoDialog {
  HeroResistancesDialog(Hero hero) : super.base(hero);

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

    // TODO: This is too wide now that the terminal is narrower. Make more
    // compact.
    terminal.writeAt(48, 0, "══════════ Resistances ═════════", steelGray);

    drawEquipmentTable(terminal, (item, y) {
      writeLine(y - 1, midnight);

      if (item == null) return;

      var i = 0;
      for (var element in hero.game.content.elements) {
        if (element == Element.none) continue;

        var x = 48 + i * 3;
        var resistance = item.resistance(element);
        var string = resistance.toString().padLeft(2);
        if (resistance > 0) {
          terminal.writeAt(x, y, string, peaGreen);
        } else if (resistance < 0) {
          terminal.writeAt(x, y, string, brickRed);
        }

        i++;
      }
    });

    var totalY = 21;
    terminal.writeAt(41, totalY, "Totals", slate);

    writeLine(4, steelGray);
    writeLine(totalY - 1, steelGray);

    var i = 0;
    for (var element in hero.game.content.elements) {
      if (element == Element.none) continue;

      var x = 48 + i * 3;
      terminal.writeAt(x, 1, element.abbreviation, elementColor(element));

      // Show the total resistance.
      var resistance = hero.equipmentResistance(element);
      var color = steelGray;
      if (resistance > 0) {
        color = peaGreen;
      } else if (resistance < 0) {
        color = brickRed;
      }

      terminal.writeAt(x, totalY, resistance.toString().padLeft(2), color);
      i++;
    }
  }
}
