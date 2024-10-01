import 'dart:html' as html;

import 'package:hauberk/src/content/item/affixes.dart';
import 'package:hauberk/src/content/item/drops.dart';
import 'package:hauberk/src/content/item/items.dart';
import 'package:hauberk/src/debug/histogram.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/engine.dart';

const tries = 10000;

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value!);
}

void main() {
  Items.initialize();
  Affixes.initialize();

  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(html.OptionElement(
        data: i.toString(), value: i.toString(), selected: i == 1));
  }

  depthSelect.onChange.listen((event) {
    generate();
  });

  generate();
}

String percent(int count) {
  return "${(count * 100 / tries).toStringAsFixed(3)}%";
}

void generate() {
  var items = Histogram<String>();
  var affixes = Histogram<String>();

  var dropAny = parseDrop('item');

  for (var i = 0; i < tries; i++) {
    var itemType = Items.types.tryChoose(depth);
    if (itemType == null) continue;

    // Create a blank lore each time so that we can count how often a given
    // artifact shows up without uniqueness coming into play.
    var lore = Lore();

    // TODO: Pass in levelOffset.
    dropAny.dropItem(lore, depth, (item) {
      items.add(item.toString());

      for (var affix in item.affixes) {
        affixes.add(affix.id);
      }
    });
  }

  var builder = HtmlBuilder();
  builder.thead();
  builder.td('Item', width: 300);
  builder.tbody();

  for (var affix in affixes.descending()) {
    builder.td(affix);
    builder.td(percent(affixes.count(affix)));
    builder.trEnd();
  }

  for (var item in items.descending()) {
    builder.td(item);
    builder.td(percent(items.count(item)));
    builder.trEnd();
  }

  builder.replaceContents('table');
}
