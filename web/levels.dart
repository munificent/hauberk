import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/drops.dart';
import 'package:hauberk/src/content/monsters.dart';

import 'histogram.dart';

main() {
  createContent();
  var text = new StringBuffer();

  for (var depth = 1; depth <= 100; depth++) {
    text.write('<tr><td>$depth</td><td width="50%">');

    var drop = parseDrop("item", depth);
    var items = new Histogram<String>();

    var tries = 100;
    for (var i = 0; i < tries; i++) {
      drop.spawnDrop((item) {
        items.add(item.nounText);
      });
    }

    var more = 0;
    for (var item in items.descending()) {
      var width = items.count(item) * 300 ~/ tries;
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

    text.write('</td><td width="50%">');

    var breeds = new Histogram<String>();
    for (var i = 0; i < tries; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      if (breed == null) continue;

      for (var i = 0; i < breed.numberInGroup; i++) {
        breeds.add(breed.name);
      }
    }

    more = 0;
    for (var breed in breeds.descending()) {
      var width = breeds.count(breed) * 300 ~/ tries;
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
