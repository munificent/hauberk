import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import 'info_dialog.dart';

abstract class EquipmentInfoDialog extends InfoDialog {
  EquipmentInfoDialog(super.content, super.hero) : super.base();

  @override
  void renderInfo(Terminal terminal) {
    var cellsX = terminal.width - 32;
    var y = 3;

    _writeHeader(terminal, cellsX);

    for (var i = 0; i < hero.equipment.slots.length; i++) {
      _writeLine(
        terminal,
        cellsX,
        y - 1,
        i == 0 ? darkCoolGray : darkerCoolGray,
      );

      var item = hero.equipment.slots[i];

      if (item != null) {
        terminal.drawGlyph(0, y, item.appearance as Glyph);
        var name = item.nounText;

        var columnWidth = cellsX - 2;
        if (name.length > columnWidth) name = name.substring(0, columnWidth);
        terminal.writeAt(2, y, name, ash);

        _renderItem(terminal, item, cellsX, y);
      } else {
        var description = "(${hero.equipment.slotTypes[i]})";
        terminal.writeAt(2, y, description, darkCoolGray);
      }

      y += 2;
    }

    var totalY = 21;
    terminal.writeAt(cellsX - 7, totalY, "Totals", coolGray);
    _writeLine(terminal, cellsX, totalY - 1, darkCoolGray);
    _writeTotals(terminal, cellsX, totalY);
  }

  void _writeHeader(Terminal terminal, int cellsX);

  void _renderItem(Terminal terminal, Item item, int x, int y);

  void _writeLine(Terminal terminal, int cellsX, int y, Color color) {
    terminal.writeAt(2, y, "─" * (cellsX - 3), color);
    terminal.writeAt(cellsX, y, _cellLines, color);
  }

  void _writeTotals(Terminal terminal, int x, int y);

  String get _cellLines;
}

// TODO: Unify with HeroItemLoreDialog so that we can select and show inspector
// for equipment.
class EquipmentStatsInfoDialog extends EquipmentInfoDialog {
  EquipmentStatsInfoDialog(super.content, super.hero);

  @override
  String get name => "Equipment";

  @override
  String get _cellLines => "── ─────────── ──── ───── ──────";

  @override
  void _writeHeader(Terminal terminal, int x) {
    terminal.writeAt(x, 0, "══════ Attack ═════ ══ Defend ══", darkCoolGray);
    terminal.writeAt(x, 1, "El Damage      Hit  Dodge Armor", coolGray);
  }

  @override
  void _renderItem(Terminal terminal, Item item, int x, int y) {
    var attack = item.attack;
    if (attack != null) {
      // Use [element] directly from the item because [attack] is just the
      // base attack before modifiers.
      terminal.writeAt(
        x,
        y,
        item.element.abbreviation,
        elementColor(item.element),
      );

      terminal.writeAt(x + 3, y, attack.damage.fmt(w: 2), ash);
    }

    _writeScale(terminal, x + 6, y, item.damageScale);
    _writeBonus(terminal, x + 11, y, item.damageBonus);
    _writeBonus(terminal, x + 16, y, item.strikeBonus);

    // TODO: Dodge bonuses.

    if (item.baseArmor != 0) {
      terminal.writeAt(x + 26, y, item.baseArmor.fmt(w: 2), ash);
    }

    _writeBonus(terminal, x + 29, y, item.armorModifier);
  }

  @override
  void _writeTotals(Terminal terminal, int x, int y) {
    var element = Element.none;
    var baseDamage = Option.heroPunchDamage;
    var totalDamageScale = 1.0;
    var totalDamageBonus = 0;
    var totalStrikeBonus = 0;
    var totalArmor = 0;
    var totalArmorBonus = 0;
    for (var item in hero.equipment.slots) {
      if (item == null) continue;

      if (item.attack case var attack?) {
        element = item.element;
        baseDamage = attack.damage;
      }

      totalDamageScale *= item.damageScale;
      totalDamageBonus += item.damageBonus;
      totalStrikeBonus += item.strikeBonus;
      totalArmor += item.baseArmor;
      totalArmorBonus += item.armorModifier;
    }

    terminal.writeAt(x, y, element.abbreviation, elementColor(element));
    terminal.writeAt(x + 3, y, baseDamage.fmt(w: 2));
    _writeScale(terminal, x + 6, y, totalDamageScale);
    _writeBonus(terminal, x + 11, y, totalDamageBonus);
    _writeBonus(terminal, x + 16, y, totalStrikeBonus);

    // TODO: Might need three digits for armor.
    terminal.writeAt(x + 26, y, totalArmor.fmt(w: 2), ash);
    _writeBonus(terminal, x + 29, y, totalArmorBonus);

    // TODO: Show resulting average damage. Include stat bonuses and stuff too.
    // TODO: Show heft, weight, encumbrance, etc.
  }

  void _writeScale(Terminal terminal, int x, int y, double scale) {
    var string = scale.fmt(d: 1);

    if (scale > 1.0) {
      terminal.writeAt(x, y, "x", sherwood);
      terminal.writeAt(x + 1, y, string, peaGreen);
    } else if (scale < 1.0) {
      terminal.writeAt(x, y, "x", maroon);
      terminal.writeAt(x + 1, y, string, red);
    }
  }

  void _writeBonus(Terminal terminal, int x, int y, int bonus) {
    var string = bonus.abs().toString();

    if (bonus > 0) {
      terminal.writeAt(x + 2 - string.length, y, "+", sherwood);
      terminal.writeAt(x + 3 - string.length, y, string, peaGreen);
    } else if (bonus < 0) {
      terminal.writeAt(x + 2 - string.length, y, "-", maroon);
      terminal.writeAt(x + 3 - string.length, y, string, red);
    }
  }
}

class EquipmentResistancesInfoDialog extends EquipmentInfoDialog {
  EquipmentResistancesInfoDialog(super.content, super.hero);

  @override
  String get name => "Resistances";

  @override
  String get _cellLines => "── ── ── ── ── ── ── ── ── ── ──";

  @override
  void _writeHeader(Terminal terminal, int x) {
    terminal.writeAt(x, 0, "══════════ Resistances ═════════", darkCoolGray);

    var i = 0;
    for (var element in content.elements) {
      if (element == Element.none) continue;

      var elementX = x + i * 3;
      terminal.writeAt(
        elementX,
        1,
        element.abbreviation,
        elementColor(element),
      );

      i++;
    }
  }

  @override
  void _renderItem(Terminal terminal, Item item, int x, int y) {
    var i = 0;
    for (var element in content.elements) {
      if (element == Element.none) continue;

      var elementX = x + i * 3;
      var resistance = item.resistance(element);
      var string = resistance.fmt(w: 2);
      if (resistance > 0) {
        terminal.writeAt(elementX, y, string, peaGreen);
      } else if (resistance < 0) {
        terminal.writeAt(elementX, y, string, red);
      }

      i++;
    }
  }

  @override
  void _writeTotals(Terminal terminal, int x, int y) {
    var i = 0;
    for (var element in content.elements) {
      if (element == Element.none) continue;

      var resistance = hero.equipmentResistance(element);
      var color = darkCoolGray;
      if (resistance > 0) {
        color = peaGreen;
      } else if (resistance < 0) {
        color = red;
      }

      terminal.writeAt(x + i * 3, y, resistance.fmt(w: 2), color);
      i++;
    }
  }
}
