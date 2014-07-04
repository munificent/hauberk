library dngn.web.areas;

import 'dart:html' as html;

import 'package:dngn/src/content.dart';
import 'package:dngn/src/engine.dart';
import 'package:dngn/src/util.dart';

main() {
  var content = createContent();

  var heroClass = new Warrior();
  var save = new HeroSave({}, "Hero", heroClass);
  var game = new Game(content.areas[0], 0, content, save);

  var text = new StringBuffer();

  for (var area in content.areas) {
    var levelNum = 0;
    for (var level in area.levels) {
      var drops = {};

      var tries = 100000;
      for (var i = 0; i < tries; i++) {
        final itemDepth = pickDepth(levelNum, area.levels.length);
        final drop = area.levels[itemDepth].floorDrop;

        area.levels[itemDepth].floorDrop.spawnDrop(game, (item) {
          drops.putIfAbsent(item.toString(), () => 0);
          drops[item.toString()]++;
        });
      }

      var items = drops.keys.toList();
      items.sort((a, b) => drops[b].compareTo(drops[a]));

      text.write('''
      <tr>
        <td>${area.name} $levelNum</td>
        <td>
      ''');

      text.write(items.map((item) {
        return "${(drops[item] / tries * 100).toStringAsFixed(3)}% $item";
      }).join("<br>"));

      text.write('''</td></tr>
      ''');

      levelNum++;
    }
  }

  html.querySelector('table').innerHtml = text.toString();
}

int pickDepth(int depth, int numLevels) {
  while (rng.oneIn(4) && depth > 0) depth--;
  while (rng.oneIn(6) && depth < numLevels - 1) depth++;

  return depth;
}
