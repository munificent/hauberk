import 'dart:html' as html;

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/item/affixes.dart';
import 'package:hauberk/src/content/item/items.dart';

import 'histogram.dart';

const tries = 10000;

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value);
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
  return (count * 100 / tries).toStringAsFixed(3) + "%";
}

void generate() {
  var items = Histogram<String>();
  var affixes = Histogram<String>();

  for (var i = 0; i < tries; i++) {
    var itemType = Items.types.tryChoose(depth);
    if (itemType == null) continue;

    // TODO: Pass in levelOffset.
    var item = Affixes.createItem(itemType, depth);

    items.add(item.toString());
    if (item.prefix != null) affixes.add("${item.prefix.name} _");
    if (item.suffix != null) affixes.add("_ ${item.suffix.name}");
  }

  var tableContents = StringBuffer();
  tableContents.write('''
    <thead>
    <tr>
      <td width="300px">Item</td>
      <td>Chance</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var affix in affixes.descending()) {
    tableContents.write('''
    <tr>
      <td>$affix</td>
      <td>${percent(affixes.count(affix))}</td>
    </tr>
    ''');
  }

  for (var item in items.descending()) {
    tableContents.write('''
    <tr>
      <td>$item</td>
      <td>${percent(items.count(item))}</td>
    </tr>
    ''');
  }

  var validator = html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html
      .querySelector('table')
      .setInnerHtml(tableContents.toString(), validator: validator);
}
