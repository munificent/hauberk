import 'dart:html' as html;

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/affixes.dart';
import 'package:hauberk/src/content/items.dart';

import 'histogram.dart';

const tries = 10000;

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value);
}

main() {
  Items.initialize();
  Affixes.initialize();

  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(
      new html.OptionElement(data: i.toString(), value: i.toString(),
          selected: i == 1));
  }

  depthSelect.onChange.listen((event) {
    generate();
  });

  generate();
}

void generate() {
  var items = new Histogram<String>();
  var affixes = new Histogram<String>();

  for (var i = 0; i < tries; i++) {
    var itemType = Items.types.tryChoose(depth, "item");
    if (itemType == null) continue;

    // TODO: Pass in levelOffset.
    var item = Affixes.createItem(itemType);

    items.add(item.toString());
    if (item.prefix != null) affixes.add("${item.prefix.name} ___");
    if (item.suffix != null) affixes.add("___ ${item.suffix.name}");
  }

  var tableContents = new StringBuffer();
  tableContents.write('''
    <thead>
    <tr>
      <td width="300px">Item</td>
      <td>Count</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var affix in affixes.descending()) {
    tableContents.write('''
    <tr>
      <td>$affix</td>
      <td>${affixes.count(affix)}</td>
    </tr>
    ''');
  }

  for (var item in items.descending()) {
    tableContents.write('''
    <tr>
      <td>$item</td>
      <td>${items.count(item)}</td>
    </tr>
    ''');
  }

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table').setInnerHtml(tableContents.toString(),
      validator: validator);
}
