import 'dart:collection';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/items.dart';
import 'package:hauberk/src/engine.dart';

html.CanvasElement canvas;
html.CanvasRenderingContext2D context;

Content content;

const simulationRounds = 20;

Breed breed = new Breed(
    "meat",
    Pronoun.it,
    null,
    [new Attack(null, "hits", 20)],
    [],
    null,
    SpawnLocation.anywhere,
    MotilitySet.walk,
    meander: 0,
    maxHealth: 200,
    flags: new Set());

main() {
  content = createContent();

  var rows = new AgilityAxis();
  var columns = new StrengthAxis();

  var table = new Table(rows.name, columns.name);

  for (var x = 0; x <= columns.length; x++) {
    table.columns.add(columns.label(x));
  }

  for (var y = 0; y < rows.length; y++) {
    var row = new Row(rows.label(y));
    table.rows.add(row);

    for (var x = 0; x <= columns.length; x++) {
      var save = new HeroSave("Hero");

      // TODO: Fix to use skills.
//      save.attributes[Attribute.strength] = 20;
//      save.attributes[Attribute.agility] = 20;
//      save.attributes[Attribute.fortitude] = 20;
//      save.attributes[Attribute.intellect] = 20;
//      save.attributes[Attribute.will] = 20;

      rows.apply(y, save);
      columns.apply(x, save);

      if (save.inventory.isEmpty) {
        save.equipment.tryAdd(new Item(Items.types.find("Scimitar"), 1));
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
    return itemType.attack != null && itemType.attack.range == 0;
  }).toList();

  String get name => "Weapon";
  int get length => _weapons.length;

  String label(int cell) => _weapons[cell].name;

  void apply(int cell, HeroSave save) {
    save.equipment.tryAdd(new Item(_weapons[cell], 1));
  }
}

abstract class AttributeAxis implements Axis {
  int get length => 20;

  String label(int cell) => _attribute(cell).toString();

  int _attribute(int cell) => cell * 3 + 1;
}

class StrengthAxis extends AttributeAxis {
  String get name => "Strength";
  void apply(int cell, HeroSave save) {
    // TODO: Fix to use skills.
//    save.attributes[Attribute.strength] = _attribute(cell);
  }
}

class AgilityAxis extends AttributeAxis {
  String get name => "Agility";
  void apply(int cell, HeroSave save) {
    // TODO: Fix to use skills.
//    save.attributes[Attribute.agility] = _attribute(cell);
  }
}

class FortitudeAxis extends AttributeAxis {
  String get name => "Fortitude";
  void apply(int cell, HeroSave save) {
    // TODO: Fix to use skills.
//    save.attributes[Attribute.fortitude] = _attribute(cell);
  }
}

SimResult simulate(HeroSave save) {
  var game = new Game(content, save, 1);

  var actions = new Queue<Action>();
  var gameResult = new GameResult();

  var wins = 0;
  for (var i = 0; i < simulationRounds; i++) {
    var monster = new Monster(game, breed, 0, 0, breed.maxHealth, 1);
    var hero = new Hero(game, Vec.zero, save);
    game.hero = hero;

    while (true) {
      var action = new AttackAction(monster);
      action.bind(hero, true);
      action.perform(actions, gameResult);

      if (monster.health.current <= 0) {
        wins++;
        break;
      }

      action = new AttackAction(hero);
      action.bind(monster, true);
      action.perform(actions, gameResult);

      if (hero.health.current <= 0) break;
    }
  }

  return new SimResult(simulationRounds, wins);
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

    var buffer = new StringBuffer();
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
        buffer.write("${value.toStringAsFixed(2)}</td>");
      }

      buffer.write("</tr>");
    }

    var validator = new html.NodeValidatorBuilder.common();
    validator.allowInlineStyles();

    html
        .querySelector('table')
        .setInnerHtml(buffer.toString(), validator: validator);

    for (var column in html.querySelectorAll('thead td')) {
      column.onClick.listen((_) {
        sortBy(column.id);
      });
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
