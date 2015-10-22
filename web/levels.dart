library hauberk.web.areas;

import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/drops.dart';

main() {
  createContent();
  var text = new StringBuffer();

  for (var i = 1; i <= 100; i++) {
    var drop = parseDrop("item", i);
    var drops = {};

    var tries = 1000;
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

    text.write('''
    <tr>
      <td>$i</td>
      <td>
    ''');

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

    text.write('''</td></tr>
    ''');
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
