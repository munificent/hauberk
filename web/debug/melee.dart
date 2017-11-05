import 'dart:collection';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/dungeon/dungeon.dart';
import 'package:hauberk/src/content/items.dart';
import 'package:hauberk/src/content/monsters.dart';
import 'package:hauberk/src/engine.dart';

html.CanvasElement canvas;
html.CanvasRenderingContext2D context;

Content content;

Breed breed = new Breed(
    "meat", Pronoun.it, null, [], [], null, SpawnLocation.anywhere,
    maxHealth: 1000, flags: new Set());

main() {
  content = createContent();

  var table = new Table("Weapon", "Strength");

  for (var strength = 1; strength <= 60; strength += 3) {
    table.columns.add(strength.toString());
  }

  for (var itemType in Items.types.all) {
    if (itemType.attack == null || itemType.attack.range > 0) continue;

    var row = new Row(itemType.name);
    table.rows.add(row);

    for (var strength = 1; strength <= 60; strength += 3) {
      var save = new HeroSave("Hero");
      save.attributes[Attribute.strength] = strength;
      save.equipment.tryAdd(new Item(itemType, 1));

      var results = simulate(save, 100);
      var damage = results.totalDamage / results.rounds;
      row.cells.add(damage);
    }
  }

  table.render();
}

SimResult simulate(HeroSave save, int rounds) {
  var game = new Game(content, save, 1);
  var hero = new Hero(game, Vec.zero, save);

  var actions = new Queue<Action>();
  var gameResult = new GameResult();

  var totalDamage = 0;
  for (var i = 0; i < rounds; i++) {
    var monster = new Monster(game, breed, 0, 0, breed.maxHealth, 1);

    var action = new AttackAction(monster);
    action.bind(hero, true);
    action.perform(actions, gameResult);

    totalDamage += monster.health.max - monster.health.current;
  }

  return new SimResult(rounds, totalDamage);
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
  final int totalDamage;

  SimResult(this.rounds, this.totalDamage);
}
