import 'dart:js_interop';
import 'dart:math' as math;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/item/drops.dart';
import 'package:hauberk/src/content/item/items.dart';
import 'package:hauberk/src/engine.dart';
import 'package:web/web.dart' as web;

final content = createContent();

const simulationRounds = 20;

Breed breed = Breed(
  Noun("meat"),
  "",
  [Attack(null, "hits", 20)],
  [],
  dropAllOf([]),
  SpawnLocation.anywhere,
  Motility.walk,
  depth: 1,
  meander: 0,
  maxHealth: 200,
  flags: BreedFlags.fromSet({}),
  tracking: 10,
);

void main() {
  var rows = AgilityAxis();
  var columns = StrengthAxis();

  var table = Table(rows.name, columns.name);

  for (var x = 0; x <= columns.length; x++) {
    table.columns.add(columns.label(x));
  }

  for (var y = 0; y < rows.length; y++) {
    var row = Row(rows.label(y));
    table.rows.add(row);

    for (var x = 0; x <= columns.length; x++) {
      var save = content.createHero("temp");

      // TODO: Fix to use skills.
      //      save.attributes[Attribute.strength] = 20;
      //      save.attributes[Attribute.agility] = 20;
      //      save.attributes[Attribute.fortitude] = 20;
      //      save.attributes[Attribute.intellect] = 20;
      //      save.attributes[Attribute.will] = 20;

      rows.apply(y, save);
      columns.apply(x, save);

      if (save.inventory.isEmpty) {
        save.equipment.tryAdd(Item(Items.types.find("Scimitar"), 1));
      }

      var results = simulate(save);
      var winPercent = results.wins / results.rounds;
      row.cells.add(winPercent);
    }
  }

  table.render();
}

abstract class Axis {
  String get name;
  int get length;

  String label(int cell);
  void apply(int cell, HeroSave save);
}

class WeaponAxis implements Axis {
  final List<ItemType> _weapons = Items.types.all.where((itemType) {
    return itemType.attack != null && itemType.attack!.range == 0;
  }).toList();

  @override
  String get name => "Weapon";
  @override
  int get length => _weapons.length;

  @override
  String label(int cell) => _weapons[cell].name;

  @override
  void apply(int cell, HeroSave save) {
    save.equipment.tryAdd(Item(_weapons[cell], 1));
  }
}

abstract class StatAxis implements Axis {
  @override
  int get length => 20;

  @override
  String label(int cell) => _stat(cell).toString();

  int _stat(int cell) => cell * 3 + 1;
}

class StrengthAxis extends StatAxis {
  @override
  String get name => "Strength";
  @override
  void apply(int cell, HeroSave save) {
    // TODO: Fix to use skills.
    //    save.attributes[Attribute.strength] = _attribute(cell);
  }
}

class AgilityAxis extends StatAxis {
  @override
  String get name => "Agility";
  @override
  void apply(int cell, HeroSave save) {
    // TODO: Fix to use skills.
    //    save.attributes[Attribute.agility] = _attribute(cell);
  }
}

class FortitudeAxis extends StatAxis {
  @override
  String get name => "Fortitude";
  @override
  void apply(int cell, HeroSave save) {
    // TODO: Fix to use skills.
    //    save.attributes[Attribute.fortitude] = _attribute(cell);
  }
}

SimResult simulate(HeroSave save) {
  var game = Game(content, 1, save);

  var wins = 0;
  for (var i = 0; i < simulationRounds; i++) {
    var monster = Monster(breed, 0, 0, 1);
    while (true) {
      var action = AttackAction(monster);
      action.bind(game, game.hero);
      action.perform();

      if (monster.health == 0) {
        wins++;
        break;
      }

      action = AttackAction(game.hero);
      action.bind(game, monster);
      action.perform();

      if (game.hero.health == 0) break;
    }
  }

  return SimResult(simulationRounds, wins);
}

class Table {
  final String rowHeader;
  final String columnHeader;
  final List<Row> rows = [];
  final List<String> columns = [];

  Table(this.rowHeader, this.columnHeader);

  void render() {
    var min = rows[0].cells[0];
    var max = min;

    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < columns.length; column++) {
        var value = rows[row].cells[column];
        min = math.min(min, value);
        max = math.max(max, value);
      }
    }

    var buffer = StringBuffer();
    buffer.write("<thead><tr><td>$rowHeader \\ $columnHeader</td>");
    for (var column in columns) {
      buffer.write("<td style='text-align: right;' id='$column'>$column</td>");
    }
    buffer.write("</tr></thead>");

    for (var row = 0; row < rows.length; row++) {
      buffer.write("<tr>");
      buffer.write("<td>${rows[row].label}</td>");

      for (var column = 0; column < columns.length; column++) {
        var value = rows[row].cells[column];
        var normal = 0.0;
        if (max > min) normal = (value - min) / (max - min);

        var bg = "hsla(10, 40%, 30%, $normal)";
        buffer.write("<td style='text-align: right; background: $bg;'>");
        buffer.write("${value.fmt(d: 2)}</td>");
      }

      buffer.write("</tr>");
    }

    web.document.querySelector('table')!.innerHTML = buffer.toString().toJS;

    {
      var columns = web.document.querySelectorAll('thead td');
      for (var i = 0; i < columns.length; i++) {
        var column = columns.item(i)!;
        column.addEventListener(
          'click',
          () {
            sortBy(column.nodeName);
          }.toJS,
        );
      }
    }
  }

  void sortBy(String column) {
    var index = columns.indexOf(column);
    if (index == -1) return;

    rows.sort((a, b) => b.cells[index].compareTo(a.cells[index]));

    render();
  }
}

class Row {
  final String label;
  final List<double> cells = [];

  Row(this.label);
}

class SimResult {
  final int rounds;
  final int wins;

  SimResult(this.rounds, this.wins);
}
