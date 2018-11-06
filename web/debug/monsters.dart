import 'dart:html' as html;

import 'package:malison/malison.dart';

import 'package:hauberk/src/content/item/items.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/engine.dart';

import 'histogram.dart';

final validator = html.NodeValidatorBuilder.common()..allowInlineStyles();
final breedDrops = <Breed, Histogram<String>>{};

main() {
  var text = StringBuffer();
  Items.initialize();
  Monsters.initialize();
  var breeds = Monsters.breeds.all.toList();
  breeds.sort((a, b) {
    if (a.depth != b.depth) return a.depth.compareTo(b.depth);
    return a.experience.compareTo(b.experience);
  });

  text.write('''
    <thead>
    <tr>
      <td colspan="2">Breed</td>
      <td>Depth</td>
      <td>Health</td>
      <td>Meander</td>
      <td>Speed</td>
      <td>Dodge</td>
      <td>Exp</td>
      <td>Count</td>
      <td>Attacks</td>
      <td>Moves</td>
      <td>Tags</td>
      <td>Flags</td>
      <td width="20%">Drops</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var breed in breeds) {
    var glyph = breed.appearance as Glyph;

    var count = breed.countMin.toString();
    if (breed.countMax != breed.countMin)
      count += "&thinsp;&ndash;&thinsp;${breed.countMax}";

    text.write('''
        <tr>
          <td>
            <pre><span style="color: ${glyph.fore.cssColor}">${String.fromCharCodes([
      glyph.char
    ])}</span></pre>
          </td>
          <td>${breed.name}</td>
          <td>${breed.depth}</td>
          <td class="r">${breed.maxHealth}</td>
          <td class="r">${breed.meander}</td>
          <td class="r">${breed.speed}</td>
        ''');

    text.write('<td>${breed.dodge}');
    if (breed.defenses.isNotEmpty) {
      text.write('+${breed.defenses.map((e) => e.amount).join("+")}');
    }
    text.write('</td>');
    text.write('<td class="r">${breed.experience}</td>');
    text.write('<td class="r">$count</td>');

    text.write('<td>');
    var attacks = breed.attacks.map(
        (attack) => '${Log.conjugate(attack.verb, breed.pronoun)} $attack');
    text.write(attacks.join('<br>'));
    text.write('</td>');

    text.writeln('<td>${breed.moves.join("<br>")}</td>');

    var tags = Monsters.breeds.getTags(breed.name).toList()..remove("monster");
    text.write('<td>${tags.join(", ")}</td>');
    text.write('<td>${breed.flags}</td>');
    text.write('<td><span class="drop" id="${breed.name}">(drops)</span></td>');
    text.write('</tr>');
  }
  text.write('</tbody>');

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);

  for (var span in html.querySelectorAll('span.drop')) {
    span.onClick.listen((_) {
      moreDrops(span);
    });
  }
}

void moreDrops(html.Element span) {
  var breed = Monsters.breeds.find(span.id);
  var drops = breedDrops.putIfAbsent(breed, () => Histogram());

  for (var i = 0; i < 100; i++) {
    breed.drop.spawnDrop(breed.depth, (item) {
      drops.add(item.toString());
    });
  }

  span.innerHtml = drops.descending().map((name) {
    return "$name (${drops.count(name)})";
  }).join('<br>');
}
