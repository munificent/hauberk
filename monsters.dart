#library('monsters');

#import('dart:html', prefix: 'html');

#import('content.dart');
#import('engine.dart');
#import('util.dart');
#import('ui.dart');

main() {
  var content = createContent();

  var text = new StringBuffer();
  var names = new List.from(content.breeds.getKeys());
  names.sort((a, b) => a.compareTo(b));

  text.add('''
    <thead>
    <tr>
      <td colspan="2">Breed</td>
      <td>Health</td>
      <td>Olfaction</td>
      <td>Meander</td>
      <td>Speed</td>
      <td>Experience</td>
      <td>Flags</td>
    </tr>
    </thead>
    <tbody>
    ''');
  for (var name in names) {
    var breed = content.breeds[name];
    var glyph = breed.appearance as Glyph;
    text.add('''
        <tr>
          <td>
<pre>
<span class="${glyph.fore.cssClass}">${glyph.char}</span>
</pre>
          </td>
          <td>${breed.name}</td>
          <td>${breed.maxHealth}</td>
          <td>${breed.olfaction}</td>
          <td>${breed.meander}</td>
          <td>${breed.speed}</td>
          <td>${breed.experienceCents ~/ 100}</td>
          <td>
        ''');

    for (var flag in breed.flags) {
      text.add('<span class="flag">${flag}</span> ');
    }

    text.add('</td></tr>');
  }
  text.add('</tbody>');

  html.query('table').innerHTML = text.toString();
}
