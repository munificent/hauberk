import 'dart:html' as html;

import 'package:malison/malison.dart';

import 'package:hauberk/src/content/items.dart';
import 'package:hauberk/src/content/monsters.dart';
import 'package:hauberk/src/engine.dart';

main() {
  var text = new StringBuffer();
  Items.initialize();
  Monsters.initialize();
  var breeds = Monsters.breeds.all.toList();
  breeds.sort((a, b) => a.depth.compareTo(b.depth));

  // Generate a bunch of drops.
  var tries = 0;
  var drops = {};

  for (var breed in breeds) {
    drops[breed.name] = {};
  }

  for (var i = 0; i < 100; i++) {
    tries++;

    for (var breed in breeds) {
      breed.drop.spawnDrop((item) {
        drops[breed.name].putIfAbsent(item.toString(), () => 0);
        drops[breed.name][item.toString()]++;
      });
    }
  }

  text.write('''
    <thead>
    <tr>
      <td colspan="2">Breed</td>
      <td>Depth</td>
      <td colspan="2">Health</td>
      <td>Meander</td>
      <td>Speed</td>
      <td>Exp/Level</td>
      <td>Attacks</td>
      <td>Moves</td>
      <td>Flags</td>
      <td>Drops</td>
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
          <td><span class="bar" style="width: ${breed.maxHealth / 10}px;"></span></td>
          <td class="r">${breed.meander}</td>
          <td class="r">${breed.speed}</td>
          <td class="r">$expPerLevel</td>
          <td>
        ''');

    var attacks = breed.attacks.map(
        (attack) => '${Log.makeVerbsAgree(attack.verb, breed.pronoun)} $attack');
    text.write(attacks.join(', '));

    text.write('</td><td>');

    text.writeln(breed.moves.join(', '));
    text.write('</td><td>');

    for (var flag in breed.flags) {
      text.write('$flag ');
    }

    text.write('</td><td>');

    var drop = drops[breed.name];
    var items = drop.keys.toList();
    items.sort((a, b) => drop[b].compareTo(drop[a]));

    text.write(items.map((item) {
      return "${(drop[item] / tries * 100).toStringAsFixed(1)}% $item";
    }).join("<br>"));

    text.write('</td></tr>');
  }
  text.write('</tbody>');

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table').setInnerHtml(text.toString(),
      validator: validator);
}
