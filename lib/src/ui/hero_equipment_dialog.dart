import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'hero_info_dialog.dart';

class HeroEquipmentDialog extends HeroInfoDialog {
  HeroEquipmentDialog(Content content, HeroSave hero)
      : super.base(content, hero);

  String get name => "Equipment";

  void render(Terminal terminal) {
    super.render(terminal);

    writeLine(int y, Color color) {
      terminal.writeAt(
          2,
          y,
          "───────────────────────────────────────────── "
          "── ─────────── ──── ───── ──────",
          color);
    }

    writeScale(int x, int y, double scale) {
      var string = scale.toStringAsFixed(1);

      if (scale > 1.0) {
        terminal.writeAt(x, y, "x", sherwood);
        terminal.writeAt(x + 1, y, string, peaGreen);
      } else if (scale < 1.0) {
        terminal.writeAt(x, y, "x", maroon);
        terminal.writeAt(x + 1, y, string, brickRed);
      }
    }

    writeBonus(int x, int y, int bonus) {
      var string = bonus.abs().toString();

      if (bonus > 0) {
        terminal.writeAt(x + 2 - string.length, y, "+", sherwood);
        terminal.writeAt(x + 3 - string.length, y, string, peaGreen);
      } else if (bonus < 0) {
        terminal.writeAt(x + 2 - string.length, y, "-", maroon);
        terminal.writeAt(x + 3 - string.length, y, string, brickRed);
      }
    }

    terminal.writeAt(48, 0, "══════ Attack ═════ ══ Defend ══", steelGray);
    terminal.writeAt(48, 1, "El Damage      Hit  Dodge Armor", slate);

    drawEquipmentTable(terminal, (item, y) {
      writeLine(y - 1, midnight);

      if (item == null) return;

      if (item.attack != null) {
        var attack = item.attack;
        terminal.writeAt(
            48, y, attack.element.abbreviation, elementColor(attack.element));

        terminal.writeAt(51, y, attack.damage.toString().padLeft(2), ash);
      }

      writeScale(54, y, item.damageScale);
      writeBonus(59, y, item.damageBonus);
      writeBonus(64, y, item.strikeBonus);

      // TODO: Dodge bonuses.

      if (item.baseArmor != 0) {
        terminal.writeAt(74, y, item.baseArmor.toString().padLeft(2), ash);
      }

      writeBonus(77, y, item.armorModifier);
    });

    var element = Element.none;
    var baseDamage = Option.heroPunchDamage;
    var totalDamageScale = 1.0;
    var totalDamageBonus = 0;
    var totalStrikeBonus = 0;
    var totalArmor = 0;
    var totalArmorBonus = 0;
    for (var slot in hero.equipment.slotTypes) {
      var item = hero.equipment.find(slot);
      if (item == null) continue;

      if (item.attack != null) {
        element = item.attack.element;
        baseDamage = item.attack.damage;
      }

      totalDamageScale *= item.damageScale;
      totalDamageBonus += item.damageBonus;
      totalStrikeBonus += item.strikeBonus;
      totalArmor += item.baseArmor;
      totalArmorBonus += item.armorModifier;
    }

    var totalY = 21;
    terminal.writeAt(41, totalY, "Totals", slate);

    writeLine(2, steelGray);
    writeLine(totalY - 1, steelGray);

    terminal.writeAt(48, totalY, element.abbreviation, elementColor(element));
    terminal.writeAt(51, totalY, baseDamage.toString().padLeft(2));
    writeScale(54, totalY, totalDamageScale);
    writeBonus(59, totalY, totalDamageBonus);
    writeBonus(64, totalY, totalStrikeBonus);

    // TODO: Might need three digits for armor.
    terminal.writeAt(74, totalY, totalArmor.toString().padLeft(2), ash);
    writeBonus(77, totalY, totalArmorBonus);

    // TODO: Show resulting average damage. Include stat bonuses and stuff too.
    // TODO: Show heft, weight, encumbrance, etc.
  }
}
