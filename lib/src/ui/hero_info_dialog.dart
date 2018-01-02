import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../content/elements.dart';
import '../engine.dart';
import '../hues.dart';
import 'input.dart';

abstract class HeroInfoDialog extends Screen<Input> {
  Hero _hero;
  HeroInfoDialog _nextScreen;

  factory HeroInfoDialog(Hero hero) {
    var screens = [
      new _HeroEquipmentScreen(hero),
      new _HeroResistancesScreen(hero),
      new _HeroLoreScreen(hero)
    ];

    for (var i = 0; i < screens.length; i++) {
      screens[i]._nextScreen = screens[(i + 1) % screens.length];
    }

    return screens.first;
  }

  HeroInfoDialog._(this._hero);

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

  void _drawEquipmentTable(
      Terminal terminal, void Function(Item item, int y) callback) {
    terminal.writeAt(2, 1, "Equipment", gold);

    var y = 3;
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

class _HeroEquipmentScreen extends HeroInfoDialog {
  _HeroEquipmentScreen(Hero hero) : super._(hero);

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

    var totalY = 21;
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
}

class _HeroResistancesScreen extends HeroInfoDialog {
  _HeroResistancesScreen(Hero hero) : super._(hero);

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

    var totalY = 21;
    terminal.writeAt(41, totalY, "Totals", slate);

    writeLine(4, steelGray);
    writeLine(totalY - 1, steelGray);

    var i = 0;
    for (var element in _hero.game.content.elements) {
      if (element == Element.none) continue;

      var x = 48 + i * 3;
      terminal.writeAt(x, 1, element.abbreviation, _elementColor(element));

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
}

class _HeroLoreScreen extends HeroInfoDialog {
  static const _rowCount = 16;

  final List<Breed> _breeds;
  int _scroll = 0;

  _HeroLoreScreen(Hero hero)
      : _breeds = hero.game.content.breeds.toList(),
        super._(hero);

  String get name => "Monster Lore";
  String get extraHelp => "[↕] Scroll";

  bool handleInput(Input input) {
    if (input == Input.n) {
      if (_scroll > 0) {
        _scroll--;
        dirty();
      }
      return true;
    } else if (input == Input.s) {
      if (_scroll < _breeds.length - _rowCount) {
        _scroll++;
        dirty();
      }
      return true;
    }

    return super.handleInput(input);
  }

  void render(Terminal terminal) {
    super.render(terminal);

    writeLine(int y, Color color) {
      terminal.writeAt(
          2,
          y,
          "────────────────────────────────────────────────────────────────── "
          "───── ─────",
          color);
    }

    terminal.writeAt(2, 1, "Monsters", gold);
    terminal.writeAt(69, 1, "Seen", slate);
    terminal.writeAt(75, 1, "Slain", slate);

    for (var i = 0; i < _rowCount; i++) {
      var breed = _breeds[_scroll + i];
      var y = i * 2 + 3;

      var seen = _hero.lore.seen(breed);
      var slain = _hero.lore.slain(breed);
      if (seen > 0 || slain > 0) {
        terminal.drawGlyph(0, y, breed.appearance);
        terminal.writeAt(2, y, breed.name);

        terminal.writeAt(69, y, seen.toString().padLeft(5));
        terminal.writeAt(75, y, slain.toString().padLeft(5));
      } else {
        terminal.writeAt(2, y, "(undiscovered ${_scroll + i + 1})", steelGray);
      }

      writeLine(y + 1, midnight);
    }

    writeLine(2, steelGray);
  }
}
