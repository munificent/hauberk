import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/monsters.dart';
import 'package:hauberk/src/engine.dart';

import 'histogram.dart';

final allBreeds =
    new List<Histogram<String>>.generate(101, (_) => new Histogram());

final allItems =
    new List<Histogram<String>>.generate(101, (_) => new Histogram());

final validator = new html.NodeValidatorBuilder.common()..allowInlineStyles();

Game game;

main() {
  game = new Game(createContent(), new HeroSave("temp"), 1);

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
    var items = allItems[depth];

    var numSpawns = 30 + depth;
    for (var i = 0; i < numSpawns; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      for (var breed in breed.spawnAll(game)) {
        breeds.add(breed.name);
      }
    }

    var numCorpses = 5 + (depth ~/ 2);
    for (var i = 0; i < numCorpses; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      for (var breed in breed.spawnAll(game)) {
        breed.drop.spawnDrop((item) {
          items.add(item.toString());
        });
      }
    }

//    for (var i = 0; i < 100; i++) {
//      var encounter = Encounters.choose(depth);
//
//      for (var spawn in encounter.spawns) {
//        var count = rng.inclusive(spawn.min, spawn.max);
//        if (count == 0) continue;
//
//        for (var i = 0; i < count; i++) {
//          breeds.add(spawn.breed.name);
//        }
//      }
//
//      for (var drop in encounter.drops) {
//        drop.spawnDrop((item) {
//          items.add(item.toString());
//        });
//      }
//    }
  }
}

void generateTable() {
  var text = new StringBuffer();

  for (var depth = 1; depth <= 100; depth++) {
    text.write('<tr><td>$depth</td>');

    renderColumn(Histogram<String> histogram) {
      text.write('<td width="50%">');
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
    renderColumn(allItems[depth]);

    text.write('</tr>');
  }

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);
}
