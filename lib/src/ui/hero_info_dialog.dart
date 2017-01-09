import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import 'input.dart';

class HeroInfoDialog extends Screen<Input> {
  final Hero _hero;

  HeroInfoDialog(this._hero);

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.clear();

    terminal.writeAt(45, 2, "┌─────Attack──────┐ ┌─Defense─┐ ┌─────Resistance─────┐", Color.darkGray);
    terminal.writeAt(51, 2, "Attack", Color.gray);
    terminal.writeAt(67, 2, "Defense", Color.gray);
    terminal.writeAt(83, 2, "Resistance", Color.gray);
    terminal.writeAt(3, 3, "Equipment", Color.gray);
    terminal.writeAt(45, 3, "El Dam Mult Add Hit Dge Arm Add", Color.gray);

    var totalY = 5 + _hero.equipment.slots.length;
    terminal.writeAt(38, totalY, "Total:", Color.gray);

    var i = 0;
    for (var element in Element.allButNone) {
      var x = 77 + i * 2;
      terminal.writeAt(x, 3, elementAbbreviation(element),
          elementColor(element));

      // Show the total resistance.
      var resistance = _hero.equipmentResistance(element);
      var color = Color.gray;
      if (resistance > 0) {
        color = Color.lightGreen;
      } else if (resistance < 0) {
        color = Color.red;
      }

      terminal.writeAt(x, totalY, resistance.toString().padLeft(2), color);
      i++;
    }

    var y = 5;
    for (var slot in _hero.equipment.slotTypes) {
      var item = _hero.equipment.find(slot);
      if (item == null) {
        terminal.writeAt(3, y, "(${slot})", Color.darkGray);
        y++;
        continue;
      }

      terminal.drawGlyph(1, y, item.appearance);
      terminal.writeAt(3, y, item.nounText);

      if (item.attack != null) {
        var attack = item.attack;
        terminal.writeAt(45, y, elementAbbreviation(attack.element),
            elementColor(attack.element));

        terminal.writeAt(48, y, attack.damage.toString().padLeft(3));
      } else {
        terminal.writeAt(45, y, "-- ---", Color.darkGray);
      }

      if (item.damageScale > 1.0) {
        terminal.writeAt(52, y, "x", Color.green);
        terminal.writeAt(53, y, item.damageScale.toStringAsFixed(1).padLeft(3), Color.lightGreen);
      } else if (item.damageScale < 1.0) {
        terminal.writeAt(52, y, "x", Color.darkRed);
        terminal.writeAt(53, y, (-item.damageScale).toStringAsFixed(1).padLeft(3),
            Color.red);
      } else if (item.attack != null) {
        terminal.writeAt(52, y, " ---", Color.darkGray);
      } else {
        terminal.writeAt(52, y, "x1.0", Color.darkGray);
      }

      if (item.damageBonus > 0) {
        terminal.writeAt(57, y, "+", Color.green);
        terminal.writeAt(58, y, item.damageBonus.toString().padLeft(2), Color.lightGreen);
      } else if (item.damageBonus < 0) {
        terminal.writeAt(57, y, "-", Color.darkRed);
        terminal.writeAt(58, y, (-item.damageBonus).toString().padLeft(2),
            Color.red);
      } else if (item.attack != null) {
        terminal.writeAt(58, y, " 0", Color.darkGray);
      } else {
        terminal.writeAt(58, y, "--", Color.darkGray);
      }

      if (item.strikeBonus > 0) {
        terminal.writeAt(61, y, "+", Color.green);
        terminal.writeAt(62, y, item.strikeBonus.toString().padLeft(2), Color.lightGreen);
      } else if (item.strikeBonus < 0) {
        terminal.writeAt(61, y, "-", Color.darkRed);
        terminal.writeAt(62, y, (-item.strikeBonus).toString().padLeft(2),
            Color.red);
      } else if (item.attack != null) {
        terminal.writeAt(62, y, " 0", Color.darkGray);
      } else {
        terminal.writeAt(62, y, "--", Color.darkGray);
      }

      if (item.baseArmor != 0) {
        terminal.writeAt(69, y, item.baseArmor.toString().padLeft(3));
      } else {
        terminal.writeAt(70, y, "--", Color.darkGray);
      }

      if (item.armorModifier > 0) {
        terminal.writeAt(73, y, "+", Color.green);
        terminal.writeAt(74, y, item.armorModifier.toString().padLeft(2), Color.lightGreen);
      } else if (item.armorModifier < 0) {
        terminal.writeAt(73, y, "-", Color.darkRed);
        terminal.writeAt(74, y, (-item.armorModifier).toString().padLeft(2),
            Color.red);
      } else if (item.baseArmor != 0) {
        terminal.writeAt(74, y, " 0", Color.darkGray);
      } else {
        terminal.writeAt(74, y, "--", Color.darkGray);
      }

      var i = 0;
      for (var element in Element.allButNone) {
        var x = 77 + i * 2;
        var resistance = item.resistance(element);
        var color = Color.darkGray;
        if (resistance > 0) {
          color = Color.lightGreen;
        } else if (resistance < 0) {
          color = Color.red;
        }

        terminal.writeAt(x, y, resistance.toString().padLeft(2), color);
        i++;
      }

      y++;
    }

    terminal.writeAt(69, totalY, _hero.armor.toString().padLeft(3));
    var armorPercent = 100 - getArmorMultiplier(_hero.armor) * 100;
    terminal.writeAt(73, totalY, armorPercent.toInt().toString().padLeft(2) + "%");

    terminal.writeAt(0, terminal.height - 1, '[Esc] Exit', Color.gray);
  }

  // TODO: Unify these colors and abbreviations with how the game
  // screen shows resists, the colors used for ball attacks, etc.
  String elementAbbreviation(Element element) {
    return const {
      Element.none: "No",
      Element.air: "Ai",
      Element.earth: "Ea",
      Element.fire: "Fi",
      Element.water: "Wa",
      Element.acid: "Ac",
      Element.cold: "Co",
      Element.lightning: "Ln",
      Element.poison: "Po",
      Element.dark: "Da",
      Element.light: "Li",
      Element.spirit: "Sp"
    }[element];
  }

  Color elementColor(Element element) {
    return const {
      Element.none: Color.gray,
      Element.air: Color.lightAqua,
      Element.earth: Color.brown,
      Element.fire: Color.red,
      Element.water: Color.blue,
      Element.acid: Color.lightGreen,
      Element.cold: Color.lightBlue,
      Element.lightning: Color.lightPurple,
      Element.poison: Color.green,
      Element.dark: Color.gray,
      Element.light: Color.lightYellow,
      Element.spirit: Color.purple
    }[element];
  }
}
