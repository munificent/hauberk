import 'dart:math' as math;

import 'package:malison/malison.dart';

import '../../content/elements.dart';
import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';

/// Shows a detailed info box for an item.
class ItemInspector {
  /// The width of the inspector when used
  static const width = 34;

  final Item _item;

  _Section? _attackSection;
  _Section? _defenseSection;
  _Section? _resistancesSection;
  _Section? _useSection;
  late final _Section _descriptionSection;

  ItemInspector(HeroSave hero, this._item, {bool wide = false})
    : _descriptionSection = _description(_item, wide ? 78 : width) {
    // Build the sections ahead of time so that we can determine where
    // everything will be positioned before we start drawing.

    // TODO: Handle armor that gives attack bonuses even though the item
    // itself has no attack.
    if (_item.attack != null) _attackSection = _AttackSection(hero, _item);

    if (_item.armor != 0 || _item.defense != null) {
      _defenseSection = _DefenseSection(_item);
    }

    // TODO: Show spells for spellbooks.

    if (_item.canEquip) _resistancesSection = _ResistancesSection(_item);

    if (_item.canUse) {
      _useSection = _TextSection(
        "Use",
        Log.wordWrap(wide ? 78 : width, _item.type.use!.description),
      );
    }

    // TODO: Max stack size?
  }

  /// Draw the floating inspector next to an item with the sections in a single
  /// column.
  void draw(int x, int itemY, Terminal terminal) {
    var sections = [
      if (_attackSection case var section?) section,
      if (_defenseSection case var section?) section,
      if (_resistancesSection case var section?) section,
      if (_useSection case var section?) section,
      _descriptionSection,
    ];

    // Two for the frame and two more for the glyph box.
    var height = 2 + 2;

    height += _sectionsHeight(sections);

    // Try to align the box next to the item, but shift it as needed to keep it
    // in bounds and not overlapping the help box on the bottom.
    var top = (itemY - 1).clamp(0, terminal.height - 4 - height);
    terminal = terminal.rect(x, top, width, height);

    Draw.glyphFrame(
      terminal,
      0,
      0,
      terminal.width,
      terminal.height,
      _item.appearance as Glyph,
      _item.nounText,
    );

    // Draw the sections.
    var y = 3;
    for (var section in sections) {
      y = section.draw(terminal, y);
    }
  }

  /// Draw the inspector at the bottom of the terminal full width for use in
  /// the lore screens.
  void drawWide(Terminal terminal) {
    Draw.glyphFrame(
      terminal,
      0,
      0,
      terminal.width,
      terminal.height,
      _item.appearance as Glyph,
      _item.nounText,
    );

    // Attack and defense in a column on the left. (We put them in the same
    // column because most items don't have both.)
    var leftY = 3;
    if (_attackSection case var section?) {
      leftY = section.draw(terminal, leftY);
    }

    if (_defenseSection case var section?) {
      leftY = section.draw(terminal, leftY);
    }

    // Resistances in a column on the right.
    var rightTerminal = terminal.rect(
      40,
      0,
      terminal.width - 40,
      terminal.height,
    );
    var rightY = 3;

    if (_resistancesSection case var section?) {
      rightY = section.draw(rightTerminal, rightY);
    }

    // Use and description below both columns.
    var y = math.max(leftY, rightY);
    if (_useSection case var section?) {
      y = section.draw(terminal, y);
    }

    // Put the description below both columns.
    _descriptionSection.draw(terminal, y);
  }

  /// Get the height of a vertical list of [sections] including their headers
  /// and spacing between them.
  int _sectionsHeight(List<_Section> sections) {
    var height = 0;

    for (var section in sections) {
      // +1 for the header.
      height += section.height + 1;
    }

    // A line of space between each section.
    return height + sections.length - 1;
  }

  static _Section _description(Item item, int width) {
    // TODO: Support color codes in strings to make important information stand
    // out more.

    var sentences = <String>[];

    // TODO: General description.
    // TODO: Equip slot.

    for (var stat in Stat.values) {
      var bonus = 0;

      for (var affix in item.affixes) {
        bonus += affix.statBonus(stat);
      }

      if (bonus < 0) {
        sentences.add("It lowers your ${stat.name} by ${-bonus}.");
      } else if (bonus > 0) {
        sentences.add("It raises your ${stat.name} by $bonus.");
      }
    }

    var toss = item.toss;
    if (toss != null) {
      var element = "";
      if (toss.attack.element != Element.none) {
        element = " ${toss.attack.element.name}";
      }

      sentences.add(
        "It can be thrown for ${toss.attack.damage}$element"
        " damage up to range ${toss.attack.range}.",
      );

      if (toss.breakage != 0) {
        sentences.add(
          "It has a ${toss.breakage}% chance of breaking when thrown.",
        );
      }

      // TODO: Describe toss use.
    }

    if (item.emanationLevel > 0) {
      sentences.add("It emanates ${item.emanationLevel} light.");
    }

    for (var element in item.type.destroyChance.keys) {
      sentences.add("It can be destroyed by ${element.name.toLowerCase()}.");
    }

    return _TextSection(
      "Description",
      Log.wordWrap(width - 2, sentences.join(" ")),
    );
  }
}

abstract class _Section {
  String get header;
  int get height;

  int draw(Terminal terminal, int y) {
    terminal.writeAt(1, y, "$header:", UIHue.selection);
    _drawContent(terminal, y + 1);
    return y + height + 2;
  }

  void _drawContent(Terminal terminal, int y);

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

  void _writeStat(Terminal terminal, int y, String label, int value) {
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
    if (_item.attack!.isRanged) height++;

    return height;
  }

  _AttackSection(this._hero, this._item);

  @override
  void _drawContent(Terminal terminal, int y) {
    _writeLabel(terminal, y, "Damage");
    if (_item.element != Element.none) {
      terminal.writeAt(
        9,
        y,
        _item.element.abbreviation,
        elementColor(_item.element),
      );
    }

    terminal.writeAt(12, y, _item.attack!.damage.toString(), UIHue.text);
    _writeScale(terminal, 16, y, _item.damageScale);
    _writeBonus(terminal, 20, y, _item.damageBonus);
    terminal.writeAt(25, y, "=", UIHue.secondary);

    var damage = _item.attack!.damage * _item.damageScale + _item.damageBonus;
    terminal.writeAt(27, y, damage.toStringAsFixed(2).padLeft(6), carrot);
    y++;

    if (_item.strikeBonus != 0) {
      _writeLabel(terminal, y, "Strike");
      _writeBonus(terminal, 12, y, _item.strikeBonus);
      y++;
    }

    if (_item.attack!.isRanged) {
      _writeStat(terminal, y, "Range", _item.attack!.range);
      y++;
    }

    _writeLabel(terminal, y, "Heft");
    var strongEnough = _hero.strength.value >= _item.heft;
    var color = strongEnough ? UIHue.primary : red;
    terminal.writeAt(12, y, _item.heft.toString(), color);
    _writeScale(terminal, 16, y, _hero.strength.heftScale(_item.heft));
    // TODO: Show heft when dual-wielding somehow?
  }
}

class _DefenseSection extends _Section {
  final Item _item;

  @override
  String get header => "Defense";

  @override
  int get height {
    var result = 1; // Weight.
    if (_item.defense != null) result++;
    if (_item.armor != 0) result++;
    return result;
  }

  _DefenseSection(this._item);

  @override
  void _drawContent(Terminal terminal, int y) {
    if (_item.defense != null) {
      _writeStat(terminal, y, "Dodge", _item.defense!.amount);
      y++;
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
  void _drawContent(Terminal terminal, int y) {
    var x = 1;
    for (var element in Elements.all) {
      if (element == Element.none) continue;
      var resistance = _item.resistance(element);
      _writeBonus(terminal, x - 1, y, resistance);
      terminal.writeAt(
        x,
        y + 1,
        element.abbreviation,
        resistance == 0 ? UIHue.disabled : elementColor(element),
      );
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
  void _drawContent(Terminal terminal, int y) {
    for (var line in _lines) {
      terminal.writeAt(1, y, line, UIHue.text);
      y++;
    }
  }
}
