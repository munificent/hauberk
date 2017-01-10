import 'dart:html' as html;

import 'package:malison/malison.dart';

import 'package:hauberk/src/content/items.dart';
import 'package:hauberk/src/content/monsters.dart';
import 'package:hauberk/src/engine.dart';

import 'histogram.dart';

final validator = new html.NodeValidatorBuilder.common()..allowInlineStyles();
final breedDrops = <Breed, Histogram<String>>{};

main() {
  var text = new StringBuffer();
  Items.initialize();
  Monsters.initialize();
  var breeds = Monsters.breeds.all.toList();
  breeds.sort((a, b) {
    if (a.depth != b.depth) return a.depth.compareTo(b.depth);
    return a.experienceCents.compareTo(b.experienceCents);
  });

  text.write('''
    <thead>
    <tr>
      <td colspan="2">Breed</td>
      <td>Depth</td>
      <td>Health</td>
      <td>Meander</td>
      <td>Speed</td>
      <td>Exp/Level</td>
      <td>Attacks</td>
      <td>Moves</td>
      <td>Flags</td>
      <td width="30%">Drops</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var breed in breeds) {
    var glyph = breed.appearance as Glyph;

    var expPerLevel = (breed.experienceCents / breed.depth / 100).toStringAsFixed(2);
    text.write('''
        <tr>
          <td>
            <pre><span style="color: ${glyph.fore.cssColor}">${new String.fromCharCodes([glyph.char])}</span></pre>
          </td>
          <td>${breed.name}</td>
          <td>${breed.depth}</td>
          <td class="r">${breed.maxHealth}</td>
          <td class="r">${breed.meander}</td>
          <td class="r">${breed.speed}</td>
          <td class="r">$expPerLevel</td>
          <td>
        ''');

    var attacks = breed.attacks.map(
        (attack) => '${Log.conjugate(attack.verb, breed.pronoun)} $attack');
    text.write(attacks.join(', '));

    text.write('</td><td>');

    text.writeln(breed.moves.join(', '));
    text.write('</td><td>');

    for (var flag in breed.flags) {
      text.write('$flag ');
    }

    text.write('</td><td><span class="drop" id="${breed.name}">(drops)</span></td>');
    text.write('</tr>');
  }
  text.write('</tbody>');

  html.querySelector('table').setInnerHtml(text.toString(),
      validator: validator);

  for (var span in html.querySelectorAll('span.drop')) {
    span.onClick.listen((_) {
      moreDrops(span);
    });
  }
}

void moreDrops(html.Element span) {
  var breed = Monsters.breeds.find(span.id);
  var drops = breedDrops.putIfAbsent(breed, () => new Histogram());

  for (var i = 0; i < 100; i++) {
    breed.drop.spawnDrop((item) {
      drops.add(item.toString());
    });
  }

  span.innerHtml = drops.descending().map((name) {
    return "$name (${drops.count(name)})";
  }).join('<br>');
}
