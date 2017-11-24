import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

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
      <td>Rarity</td>
      <td>Equip.</td>
      <td>Weapon</td>
      <td>Attack</td>
      <td>Armor</td>
      <td>Use</td>
      <td>Stack</td>
      <td>Toss</td>
      <td>Flags</td>
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

    text.write('<td>${Items.types.rarity(item.name)}</td>');

    if (item.equipSlot == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.equipSlot}</td>');
    }

    if (item.weaponType == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.weaponType} (${item.heft} heft)</td>');
    }

    if (item.attack == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.attack}</td>');
    }

    if (item.armor == 0) {
      text.write('<td>&mdash;</td>');
    } else if (item.encumbrance == 0) {
      text.write('<td>${item.armor}</td>');
    } else {
      text.write('<td>${item.armor} (${item.encumbrance} encumber)</td>');
    }

    if (item.use == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.use().runtimeType}</td>');
    }

    text.write('<td>${item.maxStack}</td>');

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

    text.write('<td>${item.flags.join(" ")}</td>');
    text.write('</tr>');
  }
  text.write('</tbody>');

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);
}
