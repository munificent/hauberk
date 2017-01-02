import 'dart:html' as html;

import 'package:malison/malison.dart';

import 'package:hauberk/src/content/items.dart';

main() {
  var text = new StringBuffer();
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
      <td>Equip.</td>
      <td>Weapon</td>
      <td>Attack</td>
      <td>Armor</td>
      <td>Stack</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var item in items) {
    var glyph = item.appearance as Glyph;
    text.write('''
        <tr>
          <td>
<pre><span style="color: ${glyph.fore.cssColor}">${new String.fromCharCodes([glyph.char])}</span></pre>
          </td>
          <td>${item.name}</td>
        ''');

    if (item.depth == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.depth}</td>');
    }

    if (item.equipSlot == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.equipSlot}</td>');
    }

    if (item.weaponType == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.weaponType}</td>');
    }

    if (item.attack == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.attack.averageDamage}</td>');
    }

    text.write('<td>${item.armor != 0 ? item.armor : "&mdash;"}</td>');
    text.write('<td>${item.maxStack}</td>');
    text.write('</tr>');
  }
  text.write('</tbody>');

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table').setInnerHtml(text.toString(),
      validator: validator);
}
