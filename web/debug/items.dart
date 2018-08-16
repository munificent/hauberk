import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content/item/items.dart';

main() {
  var text = StringBuffer();
  Items.initialize();
  var items = Items.types.all.toList();

  items.sort((a, b) {
    if (a.depth == null && b.depth == null) {
      return a.sortIndex.compareTo(b.sortIndex);
    }

    if (a.depth == null) return -1;
    if (b.depth == null) return 1;

    return a.depth.compareTo(b.depth);
  });

  text.write('''
    <thead>
    <tr>
      <td colspan="2">Item</td>
      <td>Depth</td>
      <td>Freq.</td>
      <td>Stack</td>
      <td>Price</td>
      <td>Equip.</td>
      <td>Weapon</td>
      <td>Attack</td>
      <td>Armor</td>
      <td>Weight</td>
      <td>Heft</td>
      <td>Use</td>
      <td>Toss</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var item in items) {
    var glyph = item.appearance as Glyph;
    text.write('''
        <tr>
          <td>
<pre><span style="color: ${glyph.fore.cssColor}">${String.fromCharCodes([
      glyph.char
    ])}</span></pre>
          </td>
          <td>${item.name}</td>
        ''');

    writeCell(Object value, Object defaultValue) {
      if (value == defaultValue) {
        text.write('<td>&mdash;</td>');
      } else {
        text.write('<td>$value</td>');
      }
    }

    writeCell(item.depth, null);
    writeCell(Items.types.frequency(item.name), "none");
    writeCell(item.maxStack, "none");
    writeCell(item.price, "none");

    writeCell(item.equipSlot, null);
    writeCell(item.weaponType, null);
    writeCell(item.attack, null);
    writeCell(item.armor, 0);
    writeCell(item.heft, 0);
    writeCell(item.weight, 0);

    if (item.use == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.use().runtimeType}</td>');
    }

    if (item.toss == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.toss.attack}');
      if (item.toss.use != null) {
        text.write(' ${item.toss.use(Vec.zero).runtimeType} ');
      }

      if (item.toss.breakage != 0) {
        text.write(' ${item.toss.breakage}%');
      }

      text.write('</td>');
    }

    text.write('</tr>');
  }
  text.write('</tbody>');

  var validator = html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);
}
