library items;

import 'dart:html' as html;

import 'content.dart';
import 'ui.dart';

main() {
  var content = createContent();

  var text = new StringBuffer();
  var items = new List.from(content.items.values);
  items.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  text.write('''
    <thead>
    <tr>
      <td colspan="2">Item</td>
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
<pre>
<span class="${glyph.fore.cssClass}">${new String.fromCharCodes([glyph.char])}</span>
</pre>
          </td>
          <td>${item.name}</td>
          <td>${item.equipSlot != null ? item.equipSlot : "&mdash;"}</td>
          <td>
        ''');

    if (item.attack != null) {
      text.write(item.attack.damage);
    } else {
      text.write('&mdash;');
    }

    text.write('<td>${item.armor != 0 ? item.armor : "&mdash;"}</td>');

    text.write('</td></tr>');
  }
  text.write('</tbody>');

  html.querySelector('table').innerHtml = text.toString();
}
