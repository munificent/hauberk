import 'dart:async';
import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/dungeon2.dart';
import 'package:hauberk/src/content/room.dart';
import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/hues.dart';

import 'histogram.dart';

var depthSelect = html.querySelector("#depth") as html.SelectElement;
var canvas = html.querySelector("canvas#tiles") as html.CanvasElement;
var stateCanvas = html.querySelector("canvas#states") as html.CanvasElement;

var content = createContent();
var heroClass = new Warrior();
var save = new HeroSave("Hero", heroClass);
Game _game;
RenderableTerminal terminal;

int get depth {
  return int.parse(depthSelect.value);
}

main() {
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(
      new html.OptionElement(data: i.toString(), value: i.toString(),
          selected: i == 1));
  }

  depthSelect.onChange.listen((event) {
    generate();
  });

  canvas.onClick.listen((_) {
    generate();
  });

  stateCanvas.onClick.listen((_) {
    generate();
  });

  generate();
}

Future generate() async {
  _game = new Game(content, save, depth);
  var stage = _game.stage;

  //  terminal = new RetroTerminal(stage.width, stage.height, "font_16.png",
//      canvas: canvas, charWidth: 16, charHeight: 16);
  terminal = new RetroTerminal(stage.width, stage.height, "font_8.png",
      canvas: canvas, charWidth: 8, charHeight: 8);

  stateCanvas.width = stage.width * 8;
  stateCanvas.height = stage.height * 8;

  for (var event in _game.generate()) {
    print(event);
    render();
    await html.window.animationFrame;
  }

  render(showStates: false);

  var monsters = new Histogram<Breed>();
  for (var actor in stage.actors) {
    if (actor is Monster) {
      var breed = actor.breed;
      monsters.add(breed);
    }
  }

  var tableContents = new StringBuffer();
  tableContents.write('''
    <thead>
    <tr>
      <td>Count</td>
      <td colspan="2">Breed</td>
      <td>Depth</td>
      <td colspan="2">Health</td>
      <td>Exp.</td>
      <!--<td>Drops</td>-->
    </tr>
    </thead>
    <tbody>
    ''');

  for (var breed in monsters.descending()) {
    var glyph = breed.appearance as Glyph;
    tableContents.write('''
      <tr>
        <td>${monsters.count(breed)}</td>
        <td>
          <pre><span style="color: ${glyph.fore.cssColor}">${new String.fromCharCodes([glyph.char])}</span></pre>
        </td>
        <td>${breed.name}</td>
        <td>${breed.depth}</td>
        <td class="r">${breed.maxHealth}</td>
        <td><span class="bar" style="width: ${breed.maxHealth}px;"></span></td>
        <td class="r">${(breed.experienceCents / 100).toStringAsFixed(2)}</td>
        <td>
      ''');

    var attacks = breed.attacks.map(
        (attack) => '${Log.conjugate(attack.verb, breed.pronoun)} (${attack.damage})');
    tableContents.write(attacks.join(', '));

    tableContents.write('</td><td>');

    for (var flag in breed.flags) {
      tableContents.write('$flag ');
    }

    tableContents.write('</td></tr>');
  }
  tableContents.write('</tbody>');

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table[id=monsters]').setInnerHtml(tableContents.toString(),
      validator: validator);

  tableContents.clear();
  tableContents.write('''
    <thead>
    <tr>
      <td colspan="2">Item</td>
      <td>Depth</td>
      <td>Tags</td>
      <td>Equip.</td>
      <td>Attack</td>
      <td>Armor</td>
    </tr>
    </thead>
    <tbody>
    ''');

  var items = new Histogram<String>();
  for (var item in stage.allItems) {
    items.add(item.toString());
  }

  tableContents.clear();
  tableContents.write('''
    <thead>
    <tr>
      <td>Count</td>
      <td width="300px">Item</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var item in items.descending()) {
    tableContents.write('''
    <tr>
      <td>${items.count(item)}</td>
      <td>$item</td>
    </tr>
    ''');
  }
  html.querySelector('table[id=items]').setInnerHtml(tableContents.toString(),
      validator: validator);
}

void render({bool showStates = true}) {
  var stage = _game.stage;

  for (var y = 0; y < stage.height; y++) {
    for (var x = 0; x < stage.width; x++) {
      var glyph = stage.get(x, y).type.appearance[0] as Glyph;
      terminal.drawGlyph(x, y, glyph);

      var pos = new Vec(x, y);
      var items = stage.itemsAt(pos);
      if (items.isNotEmpty) {
        terminal.drawGlyph(x, y, items.first.appearance as Glyph);
      }

      var actor = stage.actorAt(pos);
      if (actor != null) {
        if (actor.appearance is String) {
          terminal.drawChar(x, y, CharCode.at, ash);
        } else {
          terminal.drawGlyph(x, y, actor.appearance as Glyph);
        }
      }
    }
  }

  terminal.render();

  if (!showStates) return;

  var states = Dungeon2.currentStates;
  var context = stateCanvas.context2D;
  context.clearRect(0, 0, stateCanvas.width, stateCanvas.height);
  for (var y = 0; y < states.height; y++) {
    for (var x = 0; x < states.width; x++) {
      var fill = const {
        TileState.unused: 'rgba(0, 0, 0, 0.1)',
        TileState.natural: 'rgba(0, 240, 0, 0.1)',
        TileState.reached: 'rgba(0, 0, 240, 0.1)'
      }[states.get(x, y)];

      context.fillStyle = fill;
      context.fillRect(x * 8, y * 8, 8, 8);
    }
  }

  context.fillStyle = 'rgba(255, 255, 255, 0.5)';
  var junctions = Dungeon2.currentJunctions;
  for (var junction in junctions) {
    context.fillRect(junction.position.x * 8 + 2,
        junction.position.y * 8 + 2, 4, 4);
  }
}