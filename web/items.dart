library hauberk.web.items;

import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/util.dart';

main() {
  var content = createContent();

  var text = new StringBuffer();
  var items = new List.from(content.items.values);

  /*
  items.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  */
  items.sort((a, b) {
    var levelA = content.getItemLevel(a);
    var levelB = content.getItemLevel(b);

    if (levelA == null && levelB == null) {
      return a.sortIndex.compareTo(b.sortIndex);
    }

    if (levelA == null) return -1;
    if (levelB == null) return 1;

    return levelA.compareTo(levelB);
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
<pre><span class="${glyph.fore.cssClass}">${new String.fromCharCodes([glyph.char])}</span></pre>
          </td>
          <td>${item.name}</td>
        ''');

    var level = content.getItemLevel(item);
    if (level == null) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>$level</td>');
    }

    var group = content.getItemPath(item);
    if (group.isEmpty) {
      text.write('<td>&mdash;</td>');
    } else {
      text.write('<td>${group.join("&thinsp;/&thinsp;")}</td>');
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

  html.querySelector('table').innerHtml = text.toString();
}
