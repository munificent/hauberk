import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/engine.dart';

import '../histogram.dart';

final allBreeds =
    new List<Histogram<String>>.generate(101, (_) => new Histogram());

final allSpawns =
    new List<Histogram<String>>.generate(101, (_) => new Histogram());

final allItems =
    new List<Histogram<String>>.generate(101, (_) => new Histogram());

final validator = new html.NodeValidatorBuilder.common()..allowInlineStyles();

Game game;

main() {
  var content = createContent();
  game = new Game(content, content.createHero("temp"), 1);

  spawnStuff();
  generateTable();

  html.querySelector('table').onClick.listen((_) {
    spawnStuff();
    generateTable();
  });
}

int pickDepth(int depth, int numLevels) {
  while (rng.oneIn(4) && depth > 0) depth--;
  while (rng.oneIn(6) && depth < numLevels - 1) depth++;

  return depth;
}

void spawnStuff() {
  for (var depth = 1; depth <= 100; depth++) {
    var breeds = allBreeds[depth];
    var spawns = allSpawns[depth];
    var items = allItems[depth];

    var numSpawns = 30 + depth;
    for (var i = 0; i < numSpawns; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      breeds.add(breed.name);
      for (var spawn in breed.spawnAll()) {
        spawns.add(spawn.name);
      }
    }

    var numCorpses = 5 + (depth ~/ 2);
    for (var i = 0; i < numCorpses; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      if (breed == null) continue;

      for (var spawn in breed.spawnAll()) {
        spawn.drop.spawnDrop((item) {
          items.add(item.toString());
        });
      }
    }
  }
}

void generateTable() {
  var text = new StringBuffer();

  text.write('''<thead>
    <tr>
      <td>Depth</td>
      <td>Breeds</td>
      <td>Monsters</td>
      <td>Items</td>
    </tr>
  </thead>''');

  for (var depth = 1; depth <= 100; depth++) {
    text.write('<tr><td>$depth</td>');

    renderColumn(Histogram<String> histogram) {
      text.write('<td width="34%">');
      var more = 0;
      for (var name in histogram.descending()) {
        var width = histogram.count(name);
        if (width < 1) {
          more++;
          continue;
        }
        text.write('<div class="bar" style="width: ${width}px;"></div>');
        text.write(" $name");
        text.write("<br>");
      }

      if (more > 0) {
        text.write("<em>$more more&hellip;</em>");
      }

      text.write('</td>');
    }

    renderColumn(allBreeds[depth]);
    renderColumn(allSpawns[depth]);
    renderColumn(allItems[depth]);

    text.write('</tr>');
  }

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);
}
