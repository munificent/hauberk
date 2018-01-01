import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../content/elements.dart';
import '../engine.dart';
import '../hues.dart';
import 'input.dart';

class _DialogView {
  static const equipment = const _DialogView("equipment");
  static const resistances = const _DialogView("resistances");

  // TODO: Move views to show stats and other hero info.
  static const all = const [
    equipment,
    resistances,
  ];

  final String name;

  const _DialogView(this.name);

  _DialogView get next => all[(all.indexOf(this) + 1) % all.length];
}

class HeroInfoDialog extends Screen<Input> {
  final Hero _hero;
  _DialogView _view = _DialogView.equipment;

  HeroInfoDialog(this._hero);

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode == KeyCode.tab) {
      _view = _view.next;
      dirty();
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

    switch (_view) {
      case _DialogView.equipment:
        _renderEquipmentStats(terminal);
        break;

      case _DialogView.resistances:
        _renderResistances(terminal);
        break;
    }

    terminal.writeAt(
        0, terminal.height - 1, '[Esc] Exit, [Tab] Next View', slate);
  }

  void _renderEquipmentStats(Terminal terminal) {
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

    terminal.writeAt(48, 2, "══════ Attack ═════ ══ Defend ══", steelGray);
    terminal.writeAt(48, 3, "El Damage      Hit  Dodge Armor", slate);

    _drawEquipmentTable(terminal, (item, y) {
      writeLine(y - 1, midnight);

      if (item == null) return;

      if (item.attack != null) {
        var attack = item.attack;
        terminal.writeAt(
            48, y, attack.element.abbreviation, _elementColor(attack.element));

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
    for (var slot in _hero.equipment.slotTypes) {
      var item = _hero.equipment.find(slot);
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

    var totalY = 23;
    terminal.writeAt(41, totalY, "Totals", slate);

    writeLine(4, steelGray);
    writeLine(totalY - 1, steelGray);

    terminal.writeAt(48, totalY, element.abbreviation, _elementColor(element));
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

  void _renderResistances(Terminal terminal) {
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
    terminal.writeAt(48, 2, "══════════ Resistances ═════════", steelGray);

    _drawEquipmentTable(terminal, (item, y) {
      writeLine(y - 1, midnight);

      if (item == null) return;

      var i = 0;
      for (var element in _hero.game.content.elements) {
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

    var totalY = 23;
    terminal.writeAt(41, totalY, "Totals", slate);

    writeLine(4, steelGray);
    writeLine(totalY - 1, steelGray);

    var i = 0;
    for (var element in _hero.game.content.elements) {
      if (element == Element.none) continue;

      var x = 48 + i * 3;
      terminal.writeAt(x, 3, element.abbreviation, _elementColor(element));

      // Show the total resistance.
      var resistance = _hero.equipmentResistance(element);
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

  void _drawEquipmentTable(
      Terminal terminal, void Function(Item item, int y) callback) {
    terminal.writeAt(2, 3, "Equipment", gold);

    var y = 5;
    for (var slot in _hero.equipment.slotTypes) {
      var item = _hero.equipment.find(slot);
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

  Color _elementColor(Element element) {
    return {
      Element.none: gunsmoke,
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
