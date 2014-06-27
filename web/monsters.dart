library dngn.web.monsters;

import 'dart:html' as html;

import 'package:dngn/src/content.dart';
import 'package:dngn/src/engine.dart';
import 'package:dngn/src/util.dart';

main() {
  var content = createContent();

  var text = new StringBuffer();
  var breeds = new List.from(content.breeds.values);
  breeds.sort((a, b) => a.experienceCents.compareTo(b.experienceCents));

  // Generate a bunch of drops.
  var tries = 0;
  var drops = {};

  var save = new HeroSave({}, "Hero");
  var game = new Game(content.areas[0], 0, content, save);

  for (var breed in breeds) {
    drops[breed.name] = {};
  }

  for (var i = 0; i < 100000; i++) {
    tries++;

    for (Breed breed in breeds) {
      breed.drop.spawnDrop(game, (item) {
        drops[breed.name].putIfAbsent(item.type.name, () => 0);
        drops[breed.name][item.type.name]++;
      });
    }
  }

  text.write('''
    <thead>
    <tr>
      <td colspan="2">Breed</td>
      <td colspan="2">Health</td>
      <td>Meander</td>
      <td>Speed</td>
      <td>Exp.</td>
      <td>Attacks</td>
      <td>Flags</td>
      <td>Drops</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var breed in breeds) {
    var glyph = breed.appearance as Glyph;
    text.write('''
        <tr>
          <td>
<pre>
<span class="${glyph.fore.cssClass}">${new String.fromCharCodes([glyph.char])}</span>
</pre>
          </td>
          <td>${breed.name}</td>
          <td class="r">${breed.maxHealth}</td>
          <td><span class="bar" style="width: ${breed.maxHealth}px;"></span></td>
          <td class="r">${breed.meander}</td>
          <td class="r">${breed.speed}</td>
          <td class="r">${(breed.experienceCents / 100).toStringAsFixed(2)}</td>
          <td>
        ''');

    var attacks = breed.attacks.map(
        (attack) => '${Log.makeVerbsAgree(attack.verb, breed.pronoun)} (${attack.damage})');
    text.write(attacks.join(', '));

    text.write('</td><td>');

    for (var flag in breed.flags) {
      text.write('$flag ');
    }

    text.write('</td><td>');

    var drop = drops[breed.name];
    var items = drop.keys.toList();
    items.sort((a, b) => drop[b].compareTo(drop[a]));

    text.write(items.map((item) {
      return "${(drop[item] / tries * 100).toStringAsFixed(3)}% $item";
    }).join("<br>"));

    text.write('</td></tr>');
  }
  text.write('</tbody>');

  html.querySelector('table').innerHtml = text.toString();
}
