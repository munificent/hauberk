import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../input.dart';
import '../item/item_inspector.dart';
import '../widget/draw.dart';
import '../widget/table.dart';
import 'info_dialog.dart';

class EquipmentInfoDialog extends InfoDialog {
  final Table<Item?> _table = Table(scrollBar: false);

  _Columns _columns = _Columns.uninitialized;

  @override
  String get name => "Equipment";

  @override
  Map<String, String> get extraHelp => {
    ..._table.extraHelp,
    ...switch (_columns) {
      _Columns.uninitialized => const {},
      _Columns.stats => {"R": "Show resistances"},
      _Columns.resistances => {"R": "Show stats"},
      _Columns.all => const {},
    },
  };

  EquipmentInfoDialog(super.content, super.hero) : super.base() {
    _buildRows();
  }

  @override
  void resize(Vec size) {
    // If the screen is wide enough, show all the columns at once. Otherwise,
    // let the user page through them.
    if (size.x > 110) {
      _setColumns(_Columns.all);
    } else if (_columns case _Columns.uninitialized || _Columns.all) {
      _setColumns(_Columns.stats);
    }
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (_table.keyDown(keyCode, shift: shift, alt: alt)) {
      dirty();
      return true;
    }

    if (!alt) {
      switch (keyCode) {
        case KeyCode.r when !shift && _columns == _Columns.stats:
          _setColumns(_Columns.resistances);
          return true;
        case KeyCode.r when !shift && _columns == _Columns.resistances:
          _setColumns(_Columns.stats);
          return true;
      }
    }

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

  @override
  bool handleInput(Input input) {
    if (_table.handleInput(input)) {
      dirty();
      return true;
    }

    return super.handleInput(input);
  }

  @override
  void drawInfo(Terminal terminal) {
    _table.draw(terminal.rect(0, 1, terminal.width, terminal.height - 3));

    const totalY = 21;
    var cellsX = terminal.width - 32;
    switch (_columns) {
      case _Columns.uninitialized:
        break;
      case _Columns.stats:
        _writeStatHeader(terminal, cellsX);
        _writeStatTotals(terminal, cellsX, totalY);
      case _Columns.resistances:
        _writeResistancesHeader(terminal, cellsX);
        _writeResistanceTotals(terminal, cellsX, totalY);
      case _Columns.all:
        cellsX = terminal.width - 65;
        _writeStatHeader(terminal, cellsX);
        _writeResistancesHeader(terminal, cellsX + 33);
        _writeStatTotals(terminal, cellsX, totalY);
        _writeResistanceTotals(terminal, cellsX + 33, totalY);
    }

    terminal.writeAt(cellsX - 7, totalY, "Totals", coolGray);

    if (_table.selectedRow.data case var item?) {
      var inspector = ItemInspector(hero, item, wide: true);
      inspector.drawWide(
        terminal.rect(0, terminal.height - 15, terminal.width, 14),
      );
    } else {
      // Just draw an empty frame.
      Draw.glyphFrame(terminal, 0, terminal.height - 15, terminal.width, 14);
    }
  }

  void _setColumns(_Columns columns) {
    _columns = columns;
    _buildRows();
    dirty();
  }

  void _buildRows() {
    _table.rebuild(
      columns: [
        Column("Item"),
        ...switch (_columns) {
          _Columns.uninitialized => const [],
          _Columns.stats => _buildStatColumns(),
          _Columns.resistances => _buildResistanceColumns(),
          _Columns.all => [
            ..._buildStatColumns(),
            ..._buildResistanceColumns(),
          ],
        },
      ],
      () sync* {
        for (var i = 0; i < hero.equipment.slots.length; i++) {
          var item = hero.equipment.slots[i];

          if (item != null) {
            yield Row(item, glyph: item.appearance as Glyph, [
              Cell(item.noun.short),
              ...switch (_columns) {
                _Columns.uninitialized => const [],
                _Columns.stats => _buildStatCells(item),
                _Columns.resistances => _buildResistanceCells(item),
                _Columns.all => [
                  ..._buildStatCells(item),
                  ..._buildResistanceCells(item),
                ],
              },
            ]);
          } else {
            yield Row(null, [
              Cell("(${hero.equipment.slotTypes[i]})", enabled: false),
            ]);
          }
        }
      },
    );
  }

  Iterable<Column> _buildStatColumns() {
    return [
      Column("El", width: 2),
      Column("Damage", width: 11),
      Column("Hit", width: 4),
      Column("Dodge", width: 5),
      Column("Armor", width: 6),
    ];
  }

  Iterable<Column> _buildResistanceColumns() sync* {
    for (var element in content.elements) {
      if (element == Element.none) continue;
      yield Column(
        element.abbreviation,
        color: elementColor(element),
        width: 2,
      );
    }
  }

  Iterable<Cell> _buildStatCells(Item item) sync* {
    if (item.attack case var attack?) {
      // Use [element] directly from the item because [attack] is just
      // the base attack before modifiers.
      yield Cell.colored(item.element.abbreviation, elementColor(item.element));
      yield Cell.spans([
        TextSpan(attack.damage.fmt(w: 2)),
        ..._writeScale(item.damageScale),
        ..._writeBonus(item.damageBonus),
        ..._writeBonus(item.strikeBonus),
      ]);
      yield Cell.spans(_writeBonus(item.strikeBonus));
    } else {
      yield Cell(""); // Element.
      yield Cell(""); // Damage.
      yield Cell(""); // Hit.
    }

    // TODO: Dodge bonuses.
    yield Cell("");

    if (item.baseArmor != 0) {
      yield Cell.spans([
        TextSpan(item.baseArmor.fmt(w: 2)),
        ..._writeBonus(item.armorModifier),
      ]);
    } else {
      yield Cell("");
    }
  }

  Iterable<Cell> _buildResistanceCells(Item item) sync* {
    for (var element in content.elements) {
      if (element == Element.none) continue;

      var resistance = item.resistance(element);
      switch (resistance) {
        case > 0:
          yield Cell.colored(resistance.fmt(), peaGreen);
        case 0:
          yield Cell("");
        case < 0:
          yield Cell.colored(resistance.fmt(), red);
      }
    }
  }

  void _writeStatHeader(Terminal terminal, int x) {
    terminal.writeAt(x, 0, "══════Attack═══════ ══Defense═══", darkerCoolGray);
    terminal.writeAt(x + 6, 0, "Attack", darkCoolGray);
    terminal.writeAt(x + 22, 0, "Defense", darkCoolGray);
    // terminal.writeAt(x, 0, "══════Attack═══════ ══Defense═══", darkCoolGray);
    // terminal.writeAt(x, 0, "┌───── Attack ────┐ ┌─ Defend ─┐", darkCoolGray);
  }

  void _writeResistancesHeader(Terminal terminal, int x) {
    terminal.writeAt(x, 0, "══════════Resistances═══════════", darkerCoolGray);
    terminal.writeAt(x + 10, 0, "Resistances", darkCoolGray);
    // terminal.writeAt(x, 0, "══════════Resistances═══════════", darkCoolGray);
    // terminal.writeAt(x, 0, "══════════Resistances═══════════", darkCoolGray);
    // terminal.writeAt(x, 0, "┌───────── Resistances ────────┐", darkCoolGray);
  }

  void _writeStatTotals(Terminal terminal, int x, int y) {
    var element = Element.none;
    var baseDamage = Hero.punchDamage;
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

    TextSpan.draw(terminal, x: x + 3, y: y, width: 11, [
      TextSpan(baseDamage.fmt(w: 2)),
      ..._writeScale(totalDamageScale),
      ..._writeBonus(totalDamageBonus),
      ..._writeBonus(totalStrikeBonus),
    ]);

    // TODO: Might need three digits for armor.
    TextSpan.draw(terminal, x: x + 26, y: y, width: 6, [
      TextSpan(totalArmor.fmt(w: 2)),
      ..._writeBonus(totalArmorBonus),
    ]);

    // TODO: Show resulting average damage. Include stat bonuses and stuff too.
    // TODO: Show heft, weight, encumbrance, etc.
  }

  void _writeResistanceTotals(Terminal terminal, int x, int y) {
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

  List<TextSpan> _writeScale(double scale) {
    var string = scale.fmt(d: 1);

    if (scale > 1.0) {
      return [
        TextSpan(" " * (4 - string.length)),
        TextSpan("x", sherwood),
        TextSpan(string, peaGreen),
      ];
    } else if (scale < 1.0) {
      return [
        TextSpan(" " * (4 - string.length)),
        TextSpan("x", maroon),
        TextSpan(string, red),
      ];
    } else {
      return [TextSpan("   ")];
    }
  }

  List<TextSpan> _writeBonus(int bonus) {
    var string = bonus.abs().fmt();

    if (bonus > 0) {
      return [
        TextSpan(" " * (3 - string.length)),
        TextSpan("+", sherwood),
        TextSpan(string, peaGreen),
      ];
    } else if (bonus < 0) {
      return [
        TextSpan(" " * (3 - string.length)),
        TextSpan("+", maroon),
        TextSpan(string, red),
      ];
    } else {
      return [TextSpan("   ")];
    }
  }
}

enum _Columns {
  /// We haven't rendered the table yet, so we don't know if it's wide enough
  /// for all the columns or not.
  uninitialized,

  /// Showing only the weapon and armor stats.
  stats,

  /// Showing only resistances.
  resistances,

  /// Showing everything.
  all,
}
