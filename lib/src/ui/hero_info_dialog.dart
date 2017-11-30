import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../content/elements.dart';
import '../engine.dart';
import '../hues.dart';
import 'input.dart';

class HeroInfoDialog extends Screen<Input> {
  final Hero _hero;

  HeroInfoDialog(this._hero);

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

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

    // TODO: This is too wide now that the terminal is narrower. Make more
    // compact.
    terminal.writeAt(27, 2,
        "┌─────Attack─────┐ ┌─Defense─┐ ┌─────Resistance─────┐", steelGray);
    terminal.writeAt(33, 2, "Attack", slate);
    terminal.writeAt(48, 2, "Defense", slate);
    terminal.writeAt(64, 2, "Resistance", slate);
    terminal.writeAt(3, 3, "Equipment", slate);
    terminal.writeAt(27, 3, "El Dam Mul Add Hit Dge Arm Add", slate);

    var totalY = 5 + _hero.equipment.slots.length;
    terminal.writeAt(20, totalY, "Total:", slate);

    var i = 0;
    for (var element in _hero.game.content.elements) {
      if (element == Element.none) continue;

      var x = 58 + i * 2;
      terminal.writeAt(x, 3, element.abbreviation, elementColor(element));

      // Show the total resistance.
      var resistance = _hero.equipmentResistance(element);
      var color = gunsmoke;
      if (resistance > 0) {
        color = peaGreen;
      } else if (resistance < 0) {
        color = brickRed;
      }

      terminal.writeAt(x, totalY, resistance.toString().padLeft(2), color);
      i++;
    }

    var y = 5;
    for (var slot in _hero.equipment.slotTypes) {
      var item = _hero.equipment.find(slot);
      if (item == null) {
        terminal.writeAt(3, y, "(${slot})", slate);
        y++;
        continue;
      }

      terminal.drawGlyph(1, y, item.appearance);
      terminal.writeAt(3, y, item.nounText);

      if (item.attack != null) {
        var attack = item.attack;
        terminal.writeAt(
            27, y, attack.element.abbreviation, elementColor(attack.element));

        terminal.writeAt(30, y, attack.damage.toString().padLeft(3));
      } else {
        terminal.writeAt(27, y, "-- ---", slate);
      }

      if (item.damageScale > 1.0) {
        terminal.writeAt(
            34, y, item.damageScale.toStringAsFixed(1).padLeft(3), peaGreen);
      } else if (item.damageScale < 1.0) {
        terminal.writeAt(
            34, y, (-item.damageScale).toStringAsFixed(1).padLeft(3), brickRed);
      } else if (item.attack != null) {
        terminal.writeAt(34, y, "---", slate);
      } else {
        terminal.writeAt(34, y, "1.0", slate);
      }

      if (item.damageBonus > 0) {
        terminal.writeAt(38, y, "+", sherwood);
        terminal.writeAt(
            39, y, item.damageBonus.toString().padLeft(2), peaGreen);
      } else if (item.damageBonus < 0) {
        terminal.writeAt(38, y, "-", maroon);
        terminal.writeAt(
            39, y, (-item.damageBonus).toString().padLeft(2), brickRed);
      } else if (item.attack != null) {
        terminal.writeAt(39, y, " 0", slate);
      } else {
        terminal.writeAt(39, y, "--", slate);
      }

      if (item.strikeBonus > 0) {
        terminal.writeAt(42, y, "+", sherwood);
        terminal.writeAt(
            43, y, item.strikeBonus.toString().padLeft(2), peaGreen);
      } else if (item.strikeBonus < 0) {
        terminal.writeAt(42, y, "-", maroon);
        terminal.writeAt(
            43, y, (-item.strikeBonus).toString().padLeft(2), brickRed);
      } else if (item.attack != null) {
        terminal.writeAt(43, y, " 0", slate);
      } else {
        terminal.writeAt(43, y, "--", slate);
      }

      if (item.baseArmor != 0) {
        terminal.writeAt(50, y, item.baseArmor.toString().padLeft(3));
      } else {
        terminal.writeAt(51, y, "--", slate);
      }

      if (item.armorModifier > 0) {
        terminal.writeAt(54, y, "+", sherwood);
        terminal.writeAt(
            55, y, item.armorModifier.toString().padLeft(2), peaGreen);
      } else if (item.armorModifier < 0) {
        terminal.writeAt(54, y, "-", maroon);
        terminal.writeAt(
            55, y, (-item.armorModifier).toString().padLeft(2), brickRed);
      } else if (item.baseArmor != 0) {
        terminal.writeAt(55, y, " 0", slate);
      } else {
        terminal.writeAt(55, y, "--", slate);
      }

      var i = 0;
      for (var element in _hero.game.content.elements) {
        if (element == Element.none) continue;

        var x = 58 + i * 2;
        var resistance = item.resistance(element);
        var color = slate;
        if (resistance > 0) {
          color = peaGreen;
        } else if (resistance < 0) {
          color = brickRed;
        }

        terminal.writeAt(x, y, resistance.toString().padLeft(2), color);
        i++;
      }

      y++;
    }

    terminal.writeAt(50, totalY, _hero.armor.toString().padLeft(3));
    var armorPercent = 100 - getArmorMultiplier(_hero.armor) * 100;
    terminal.writeAt(
        54, totalY, armorPercent.toInt().toString().padLeft(2) + "%");

    terminal.writeAt(0, terminal.height - 1, '[Esc] Exit', slate);
  }

  Color elementColor(Element element) {
    return {
      Element.none: Color.gray,
      Elements.air: Color.lightAqua,
      Elements.earth: persimmon,
      Elements.fire: Color.red,
      Elements.water: Color.blue,
      Elements.acid: Color.lightGreen,
      Elements.cold: Color.lightBlue,
      Elements.lightning: Color.lightPurple,
      Elements.poison: Color.green,
      Elements.dark: Color.gray,
      Elements.light: Color.lightYellow,
      Elements.spirit: Color.purple
    }[element];
  }
}
