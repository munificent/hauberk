import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';

class HeroInfoDialog extends Screen<Input> {
  final Map<Attribute, int> _attributes;
  final Hero _hero;

  HeroInfoDialog(this._hero) : _attributes = new Map.from(_hero.attributes);

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.s:
        return _tryRaiseAttribute(Attribute.strength);
      case KeyCode.a:
        return _tryRaiseAttribute(Attribute.agility);
      case KeyCode.f:
        return _tryRaiseAttribute(Attribute.fortitude);
      case KeyCode.i:
        return _tryRaiseAttribute(Attribute.intellect);
      case KeyCode.w:
        return _tryRaiseAttribute(Attribute.will);
    }

    return false;
  }

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop(_attributes);
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.clear();

    // TODO: This is too wide now that the terminal is narrower. Make more
    // compact.
    terminal.writeAt(27, 2, "┌─────Attack─────┐ ┌─Defense─┐ ┌─────Resistance─────┐", steelGray);
    terminal.writeAt(33, 2, "Attack", slate);
    terminal.writeAt(48, 2, "Defense", slate);
    terminal.writeAt(64, 2, "Resistance", slate);
    terminal.writeAt(3, 3, "Equipment", slate);
    terminal.writeAt(27, 3, "El Dam Mul Add Hit Dge Arm Add", slate);

    var totalY = 5 + _hero.equipment.slots.length;
    terminal.writeAt(20, totalY, "Total:", slate);

    var i = 0;
    for (var element in Element.allButNone) {
      var x = 58 + i * 2;
      terminal.writeAt(x, 3, elementAbbreviation(element),
          elementColor(element));

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
        terminal.writeAt(27, y, elementAbbreviation(attack.element),
            elementColor(attack.element));

        terminal.writeAt(30, y, attack.damage.toString().padLeft(3));
      } else {
        terminal.writeAt(27, y, "-- ---", slate);
      }

      if (item.damageScale > 1.0) {
        terminal.writeAt(34, y, item.damageScale.toStringAsFixed(1).padLeft(3), peaGreen);
      } else if (item.damageScale < 1.0) {
        terminal.writeAt(34, y, (-item.damageScale).toStringAsFixed(1).padLeft(3),
            brickRed);
      } else if (item.attack != null) {
        terminal.writeAt(34, y, "---", slate);
      } else {
        terminal.writeAt(34, y, "1.0", slate);
      }

      if (item.damageBonus > 0) {
        terminal.writeAt(38, y, "+", sherwood);
        terminal.writeAt(39, y, item.damageBonus.toString().padLeft(2), peaGreen);
      } else if (item.damageBonus < 0) {
        terminal.writeAt(38, y, "-", maroon);
        terminal.writeAt(39, y, (-item.damageBonus).toString().padLeft(2),
            brickRed);
      } else if (item.attack != null) {
        terminal.writeAt(39, y, " 0", slate);
      } else {
        terminal.writeAt(39, y, "--", slate);
      }

      if (item.strikeBonus > 0) {
        terminal.writeAt(42, y, "+", sherwood);
        terminal.writeAt(43, y, item.strikeBonus.toString().padLeft(2), peaGreen);
      } else if (item.strikeBonus < 0) {
        terminal.writeAt(42, y, "-", maroon);
        terminal.writeAt(43, y, (-item.strikeBonus).toString().padLeft(2),
            brickRed);
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
        terminal.writeAt(55, y, item.armorModifier.toString().padLeft(2), peaGreen);
      } else if (item.armorModifier < 0) {
        terminal.writeAt(54, y, "-", maroon);
        terminal.writeAt(55, y, (-item.armorModifier).toString().padLeft(2),
            brickRed);
      } else if (item.baseArmor != 0) {
        terminal.writeAt(55, y, " 0", slate);
      } else {
        terminal.writeAt(55, y, "--", slate);
      }

      var i = 0;
      for (var element in Element.allButNone) {
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
    terminal.writeAt(54, totalY, armorPercent.toInt().toString().padLeft(2) + "%");

    y = 20;
    for (var attribute in Attribute.all) {
      terminal.writeAt(3, y, attribute.name, gunsmoke);
      terminal.writeAt(13, y, _attributes[attribute].toString(), ash);
      y++;
    }

    terminal.writeAt(3, 26, "Available", gunsmoke);
    terminal.writeAt(13, 26, _hero.attributePoints.toString(), ash);

    var helpText = ['[Esc] Exit'];
    // TODO: This isn't the greatest UX, but it's good enough for now.
    if (_hero.attributePoints > 0) {
      if (_attributeTotal < Attribute.totalMax) {
        for (var attribute in Attribute.all) {
          if (_attributes[attribute] < Attribute.naturalMax) {
            helpText.add("[${attribute.name[0]}] Raise ${attribute.name}");
          }
        }

        // TODO: Don't all fit in help text bar. Fix.
      }
    }
    terminal.writeAt(0, terminal.height - 1, helpText.join(', '), slate);
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
      Element.earth: persimmon,
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

  // TODO: Make sure we don't take temporary state into account here.
  int get _attributeTotal => Attribute.all.map((attribute) => _attributes[attribute]).reduce((a, b) => a + b);

  bool _tryRaiseAttribute(Attribute attribute) {
    if (_hero.attributePoints <= 0) return false;
    if (_attributeTotal >= Attribute.totalMax) return false;

    var value = _attributes[attribute];
    if (value >= Attribute.naturalMax) return false;

    dirty();
    _attributes[attribute]++;
    _hero.attributePoints--;
    return true;
  }
}
