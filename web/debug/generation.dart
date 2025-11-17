import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/debug/histogram.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/engine.dart';

Histogram<String> monsters = Histogram();
Histogram<String> items = Histogram();
Histogram<String> affixes = Histogram();

Content content = createContent();

int generated = 0;

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value!);
}

void main() {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(
      html.OptionElement(
        data: i.toString(),
        value: i.toString(),
        selected: i == 1,
      ),
    );
  }

  depthSelect.onChange.listen((_) {
    monsters = Histogram();
    items = Histogram();
    affixes = Histogram();
    generated = 0;

    generate();
    generateTable();
  });

  html.querySelector('table')!.onClick.listen((_) {
    generate();
    generateTable();
  });

  generate();
  generateTable();
}

void generate() {
  // Create a new hero every time so that we get better statistics for
  // artifacts.
  var save = content.createHero("hero");
  var game = Game(content, depth, save);

  for (var event in game.generate()) {
    print(event);
  }

  void addItem(Item item) {
    items.add(item.type.name);

    for (var affix in item.affixes) {
      affixes.add(affix.type.id);
    }
  }

  for (var actor in game.stage.actors) {
    if (actor is Monster) {
      monsters.add(actor.breed.name);

      actor.breed.drop.dropItem(game.hero.lore, depth, addItem);
    }
  }

  game.stage.allItems.forEach(addItem);

  generated++;
}

void generateTable() {
  var builder = HtmlBuilder();
  builder.thead();
  builder.td('Monsters');
  builder.td('Items');
  builder.td('Affixes');

  builder.tbody();

  void renderColumn(Histogram<String> histogram, int max) {
    builder.tdBegin(width: '25%');
    for (var name in histogram.descending()) {
      var count = histogram.count(name);
      var width = 100 * count ~/ max;
      var percent = (100 * count / histogram.total)
          .toStringAsFixed(2)
          .padLeft(5, "0");
      var chance = (count / generated).toStringAsFixed(1).padLeft(6);

      builder.write(
        '<span style="font-family: monospace;">$percent% $chance </span>',
      );
      builder.write('<div class="bar" style="width: ${width}px;"></div> $name');
      builder.write('<br>');
    }

    builder.tdEnd();
  }

  renderColumn(monsters, monsters.max);
  renderColumn(items, items.max);
  renderColumn(affixes, items.max);

  builder.tbodyEnd();
  builder.replaceContents('table');
}
