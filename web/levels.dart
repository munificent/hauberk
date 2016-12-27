import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/drops.dart';
import 'package:hauberk/src/content/monsters.dart';
import 'package:hauberk/src/engine.dart';

main() {
  createContent();
  var text = new StringBuffer();

  for (var depth = 1; depth <= 100; depth++) {
    text.write('<tr><td>$depth</td><td>');

    var drop = parseDrop("item", depth);
    var drops = {};

    var tries = 100;
    for (var i = 0; i < tries; i++) {
      drop.spawnDrop((item) {
        var name = item.type.name;
        if (item.prefix != null) name = "${item.prefix.name} $name";
        if (item.suffix != null) name = "$name ${item.suffix.name}";

        drops.putIfAbsent(name, () => 0);
        drops[name]++;
      });
    }

    var items = drops.keys.toList();
    items.sort((a, b) => drops[b].compareTo(drops[a]));

    var more = 0;
    for (var item in items) {
      var width = drops[item] * 400 ~/ tries;
      if (width < 1) {
        more++;
        continue;
      }
      text.write('<div class="bar" style="width: ${width}px;"></div>');
      //return "${(drops[item] / tries * 100).toStringAsFixed(3)}% $item";
      text.write(" $item");
      text.write("<br>");
    }

    if (more > 0) {
      text.write("<em>$more more&hellip;</em>");
    }

    text.write('</td><td>');

    var breedCounts = {};
    for (var i = 0; i < tries; i++) {
      var breed = Monsters.rootTag.choose(depth, Monsters.all) as Breed;
      if (breed == null) continue;

      breedCounts.putIfAbsent(breed.name, () => 0);
      breedCounts[breed.name] += breed.numberInGroup;
    }

    var breeds = breedCounts.keys.toList();
    breeds.sort((a, b) => breedCounts[b].compareTo(breedCounts[a]));

    more = 0;
    for (var breed in breeds) {
      var width = breedCounts[breed] * 400 ~/ tries;
      if (width < 1) {
        more++;
        continue;
      }
      text.write('<div class="bar" style="width: ${width}px;"></div>');
      text.write(" ${breed}");
      text.write("<br>");
    }

    if (more > 0) {
      text.write("<em>$more more&hellip;</em>");
    }

    text.write('</td></tr>');
  }

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table').setInnerHtml(text.toString(),
      validator: validator);
}

int pickDepth(int depth, int numLevels) {
  while (rng.oneIn(4) && depth > 0) depth--;
  while (rng.oneIn(6) && depth < numLevels - 1) depth++;

  return depth;
}
