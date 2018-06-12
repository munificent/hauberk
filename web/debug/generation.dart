import 'dart:html' as html;

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content.dart';

import '../histogram.dart';

Histogram<String> monsters = new Histogram();
Histogram<String> items = new Histogram();
Histogram<String> affixes = new Histogram();

final validator = new html.NodeValidatorBuilder.common()..allowInlineStyles();

HeroSave save = content.createHero("hero");
Content content = createContent();
Game game;

int generated = 0;

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value);
}

main() {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(new html.OptionElement(
        data: i.toString(), value: i.toString(), selected: i == 1));
  }

  depthSelect.onChange.listen((_) {
    monsters = new Histogram();
    items = new Histogram();
    affixes = new Histogram();
    generated = 0;

    generate();
    generateTable();
  });

  html.querySelector('table').onClick.listen((_) {
    generate();
    generateTable();
  });

  generate();
  generateTable();
}

void generate() {
  game = new Game(content, save, depth);

  for (var event in game.generate()) {
    print(event);
  }

  for (var actor in game.stage.actors) {
    if (actor is Monster) {
      monsters.add(actor.breed.name);

      actor.breed.drop.spawnDrop((item) {
        items.add(item.type.name);

        if (item.prefix != null) affixes.add("${item.prefix.name} ___");
        if (item.suffix != null) affixes.add("___ ${item.suffix.name}");
      });
    }
  }

  for (var item in game.stage.allItems) {
    items.add(item.type.name);

    if (item.prefix != null) affixes.add("${item.prefix.name} ___");
    if (item.suffix != null) affixes.add("___ ${item.suffix.name}");
  }

  generated++;
}

void generateTable() {
  var text = new StringBuffer();

  text.write('''<thead>
    <tr>
      <td>Monsters</td>
      <td>Items</td>
      <td>Affixes</td>
    </tr>
  </thead>''');

  text.write('<tr>');

  renderColumn(Histogram<String> histogram, int max) {
    text.write('<td width="25%">');
    for (var name in histogram.descending()) {
      var count = histogram.count(name);
      var width = 100 * count ~/ max;
      var percent = (100 * count / histogram.total).toStringAsFixed(2).padLeft(5, "0");
      var chance = (count / generated).toStringAsFixed(1).padLeft(6);

      text.write('<span style="font-family: monospace;">$percent% $chance </span>');
      text.write('<div class="bar" style="width: ${width}px;"></div> $name');
      text.write('<br>');
    }

    text.write('</td>');
  }

  renderColumn(monsters, monsters.max);
  renderColumn(items, items.max);
  renderColumn(affixes, items.max);

  text.write('</tr>');

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);
}
