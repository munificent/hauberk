import 'package:malison/malison.dart';

import '../content/elements.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';

/// Shows a detailed info box for an item.
class Inspector {
  static const width = 34;

  final Item _item;

  final List<_Section> _sections = [];

  Inspector(HeroSave hero, this._item) {
    // TODO: Handle armor that gives attack bonuses even though the item
    // itself has no attack.
    if (_item.attack != null) _sections.add(_AttackSection(hero, _item));

    if (_item.armor != 0 || _item.defense != null) {
      _sections.add(_DefenseSection(_item));
    }

    // TODO: Show spells for spellbooks.

    if (_item.canEquip) _sections.add(_ResistancesSection(_item));

    if (_item.canUse) _use();
    _description();

    // TODO: Max stack size?
  }

  void draw(int x, int itemY, Terminal terminal) {
    // Frame.
    var height = 2;

    // Two more for the item box.
    height += 2;
    for (var section in _sections) {
      // +1 for the header.
      height += section.height + 1;
    }

    // A line of space between each section.
    height += _sections.length - 1;

    // Try to align the box next to the item, but shift it as needed to keep it
    // in bounds and not overlapping the help box on the bottom.
    var top = (itemY - 1).clamp(0, terminal.height - 4 - height);
    terminal = terminal.rect(x, top, 34, height);

    // Draw the frame.
    Draw.frame(
        terminal, 0, 1, terminal.width, terminal.height - 1, UIHue.helpText);

    Draw.box(terminal, 1, 0, 3, 3, UIHue.helpText);
    terminal.writeAt(1, 1, "╡", UIHue.helpText);
    terminal.writeAt(3, 1, "╞", UIHue.helpText);

    terminal.drawGlyph(2, 1, _item.appearance as Glyph);
    terminal.writeAt(4, 1, _item.nounText, UIHue.primary);

    // Draw the sections.
    var y = 3;
    for (var section in _sections) {
      terminal.writeAt(1, y, "${section.header}:", UIHue.selection);
      y++;

      section.draw(terminal, y);
      y += section.height + 1;
    }
  }

  void _use() {
    _sections.add(_TextSection("Use", _wordWrap(_item.type.use.description)));
  }

  void _description() {
    // TODO: Support color codes in strings to make important information stand
    // out more.

    var sentences = <String>[];

    // TODO: General description.
    // TODO: Equip slot.

    for (var stat in Stat.all) {
      var bonus = 0;
      if (_item.prefix != null) bonus += _item.prefix.statBonus(stat);
      if (_item.suffix != null) bonus += _item.suffix.statBonus(stat);

      if (bonus < 0) {
        sentences.add("It lowers your ${stat.name} by ${-bonus}.");
      } else if (bonus > 0) {
        sentences.add("It raises your ${stat.name} by $bonus.");
      }
    }

    if (_item.toss != null) {
      var toss = _item.toss;

      var element = "";
      if (toss.attack.element != Element.none) {
        element = " ${toss.attack.element.name}";
      }

      sentences.add("It can be thrown for ${toss.attack.damage}$element"
          " damage up to range ${toss.attack.range}.");

      if (toss.breakage != 0) {
        sentences
            .add("It has a ${toss.breakage}% chance of breaking when thrown.");
      }

      // TODO: Describe toss use.
    }

    if (_item.emanationLevel > 0) {
      sentences.add("It emanates ${_item.emanationLevel} light.");
    }

    for (var element in _item.type.destroyChance.keys) {
      sentences.add("It can be destroyed by ${element.name.toLowerCase()}.");
    }

    _sections.add(_TextSection("Description", _wordWrap(sentences.join(" "))));
  }

  List<String> _wordWrap(String text) => Log.wordWrap(width - 2, text);
}

abstract class _Section {
  String get header;
  int get height;
  void draw(Terminal terminal, int y);

  // TODO: Mostly copied from hero_equipment_dialog. Unify.
  void _writeBonus(Terminal terminal, int x, int y, int bonus) {
    var string = bonus.abs().toString();

    if (bonus > 0) {
      terminal.writeAt(x + 2 - string.length, y, "+", sherwood);
      terminal.writeAt(x + 3 - string.length, y, string, peaGreen);
    } else if (bonus < 0) {
      terminal.writeAt(x + 2 - string.length, y, "-", maroon);
      terminal.writeAt(x + 3 - string.length, y, string, red);
    } else {
      terminal.writeAt(x + 2 - string.length, y, "+", UIHue.disabled);
      terminal.writeAt(x + 3 - string.length, y, string, UIHue.disabled);
    }
  }

  void _writeLabel(Terminal terminal, int y, String label) {
    terminal.writeAt(1, y, "$label:", UIHue.text);
  }

  void _writeStat(Terminal terminal, int y, String label, Object value) {
    if (value == null) return;

    _writeLabel(terminal, y, label);
    terminal.writeAt(12, y, value.toString(), UIHue.primary);
  }

  // TODO: Mostly copied from hero_equipment_dialog. Unify.
  void _writeScale(Terminal terminal, int x, int y, double scale) {
    var string = scale.toStringAsFixed(1);

    var xColor = UIHue.disabled;
    var numberColor = UIHue.disabled;
    if (scale > 1.0) {
      xColor = sherwood;
      numberColor = peaGreen;
    } else if (scale < 1.0) {
      xColor = maroon;
      numberColor = red;
    }

    terminal.writeAt(x, y, "x", xColor);
    terminal.writeAt(x + 1, y, string, numberColor);
  }
}

class _AttackSection extends _Section {
  final HeroSave _hero;
  final Item _item;

  @override
  String get header => "Attack";

  @override
  int get height {
    // Damage and heft.
    var height = 2;

    if (_item.strikeBonus != 0) height++;
    if (_item.attack.isRanged) height++;

    return height;
  }

  _AttackSection(this._hero, this._item);

  @override
  void draw(Terminal terminal, int y) {
    _writeLabel(terminal, y, "Damage");
    if (_item.element != Element.none) {
      terminal.writeAt(
          9, y, _item.element.abbreviation, elementColor(_item.element));
    }

    terminal.writeAt(12, y, _item.attack.damage.toString(), UIHue.text);
    _writeScale(terminal, 16, y, _item.damageScale);
    _writeBonus(terminal, 20, y, _item.damageBonus);
    terminal.writeAt(25, y, "=", UIHue.secondary);

    var damage = _item.attack.damage * _item.damageScale + _item.damageBonus;
    terminal.writeAt(27, y, damage.toStringAsFixed(2).padLeft(6), carrot);
    y++;

    if (_item.strikeBonus != 0) {
      _writeLabel(terminal, y, "Strike");
      _writeBonus(terminal, 12, y, _item.strikeBonus);
      y++;
    }

    if (_item.attack.isRanged) {
      _writeStat(terminal, y, "Range", _item.attack.range);
    }

    _writeLabel(terminal, y, "Heft");
    var strongEnough = _hero.strength.value >= _item.heft;
    var color = strongEnough ? UIHue.primary : red;
    terminal.writeAt(12, y, _item.heft.toString(), color);
    _writeScale(terminal, 16, y, _hero.strength.heftScale(_item.heft));
    // TODO: Show heft when dual-wielding somehow?
    y++;
  }
}

class _DefenseSection extends _Section {
  final Item _item;

  @override
  String get header => "Defense";

  @override
  int get height => _item.defense != null ? 3 : 2;

  _DefenseSection(this._item);

  @override
  void draw(Terminal terminal, int y) {
    if (_item.defense != null) {
      _writeStat(terminal, y, "Dodge", _item.defense.amount);
    }

    if (_item.armor != 0) {
      _writeLabel(terminal, y, "Armor");
      terminal.writeAt(12, y, _item.baseArmor.toString(), UIHue.text);
      _writeBonus(terminal, 16, y, _item.armorModifier);
      terminal.writeAt(25, y, "=", UIHue.secondary);

      var armor = _item.armor.toString().padLeft(6);
      terminal.writeAt(27, y, armor, peaGreen);
      y++;
    }

    _writeStat(terminal, y, "Weight", _item.weight);
    // TODO: Encumbrance.
  }
}

class _ResistancesSection extends _Section {
  final Item _item;

  @override
  String get header => "Resistances";

  @override
  int get height => 2;

  _ResistancesSection(this._item);

  @override
  void draw(Terminal terminal, int y) {
    var x = 1;
    for (var element in Elements.all) {
      if (element == Element.none) continue;
      var resistance = _item.resistance(element);
      _writeBonus(terminal, x - 1, y, resistance);
      terminal.writeAt(x, y + 1, element.abbreviation,
          resistance == 0 ? UIHue.disabled : elementColor(element));
      x += 3;
    }
  }
}

class _TextSection extends _Section {
  final List<String> _lines;

  @override
  final String header;

  @override
  int get height => _lines.length;

  _TextSection(this.header, this._lines);

  @override
  void draw(Terminal terminal, int y) {
    for (var line in _lines) {
      terminal.writeAt(1, y, line, UIHue.text);
      y++;
    }
  }
}
