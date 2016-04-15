import 'dart:html' as html;

import 'package:malison/malison.dart';

import 'package:hauberk/src/content.dart';

main() {
  var content = createContent();

  var text = new StringBuffer();
  var items = new List.from(content.items.values);

  /*
  items.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  */
  items.sort((a, b) {
    if (a.level == null && b.level == null) {
      return a.sortIndex.compareTo(b.sortIndex);
    }

    if (a.level == null) return -1;
    if (b.level == null) return 1;

    return a.level.compareTo(b.level);
  });

  text.write('''
    <thead>
    <tr>
      <td colspan="2">Item</td>
      <td>Level</td>
      <td>Group</td>
      <td>Equip.</td>
      <td>Attack</td>
      <td>Armor</td>
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

    if (item.level == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.level}</td>');
    }

    if (item.categories.isEmpty) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${item.categories.join("&thinsp;/&thinsp;")}</td>');
    }

    text.write('''
          <td>${item.equipSlot != null ? item.equipSlot : "&mdash;"}</td>
          <td>
        ''');

    if (item.attack != null) {
      text.write(item.attack.averageDamage);
    } else {
      text.write('&mdash;');
    }

    text.write('<td>${item.armor != 0 ? item.armor : "&mdash;"}</td>');

    text.write('</td></tr>');
  }
  text.write('</tbody>');

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table').setInnerHtml(text.toString(),
      validator: validator);
}
