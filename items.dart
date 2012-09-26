#library('items');

#import('dart:html', prefix: 'html');

#import('content.dart');
#import('engine.dart');
#import('util.dart');
#import('ui.dart');

main() {
  var content = createContent();

  var text = new StringBuffer();
  var items = new List.from(content.items.getValues());
  items.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  text.add('''
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
    text.add('''
        <tr>
          <td>
<pre>
<span class="${glyph.fore.cssClass}">${glyph.char}</span>
</pre>
          </td>
          <td>${item.name}</td>
          <td>${item.equipSlot != null ? item.equipSlot : "&mdash;"}</td>
          <td>
        ''');

    if (item.attack != null) {
      text.add(item.attack.damage);
    } else {
      text.add('&mdash;');
    }

    text.add('<td>${item.armor != 0 ? item.armor : "&mdash;"}</td>');

    text.add('</td></tr>');
  }
  text.add('</tbody>');

  html.query('table').innerHTML = text.toString();
}
