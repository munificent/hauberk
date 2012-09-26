#library('monsters');

#import('dart:html', prefix: 'html');

#import('content.dart');
#import('engine.dart');
#import('util.dart');
#import('ui.dart');

main() {
  var content = createContent();

  var text = new StringBuffer();
  var breeds = new List.from(content.breeds.getValues());
  breeds.sort((a, b) => a.experienceCents.compareTo(b.experienceCents));

  text.add('''
    <thead>
    <tr>
      <td colspan="2">Breed</td>
      <td colspan="2">Health</td>
      <td>Smell</td>
      <td>Meander</td>
      <td>Speed</td>
      <td>Exp.</td>
      <td>Attacks</td>
      <td>Flags</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var breed in breeds) {
    var glyph = breed.appearance as Glyph;
    text.add('''
        <tr>
          <td>
<pre>
<span class="${glyph.fore.cssClass}">${glyph.char}</span>
</pre>
          </td>
          <td>${breed.name}</td>
          <td class="r">${breed.maxHealth}</td>
          <td><span class="bar" style="width: ${breed.maxHealth}px;"></span></td>
          <td class="r">${breed.olfaction}</td>
          <td class="r">${breed.meander}</td>
          <td class="r">${breed.speed}</td>
          <td class="r">${(breed.experienceCents / 100).toStringAsFixed(2)}</td>
          <td>
        ''');

    var attacks = breed.attacks.map(
        (attack) => '${Log.makeVerbsAgree(attack.verb, 3)} (${attack.damage})');
    text.add(Strings.join(attacks, ', '));

    text.add('</td><td>');

    for (var flag in breed.flags) {
      text.add('$flag ');
    }

    text.add('</td></tr>');
  }
  text.add('</tbody>');

  html.query('table').innerHTML = text.toString();
}
