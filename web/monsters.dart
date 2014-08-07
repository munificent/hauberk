library hauberk.web.monsters;

import 'dart:html' as html;

import 'package:malison/malison.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

main() {
  var content = createContent();

  var text = new StringBuffer();
  var breeds = new List.from(content.breeds.values);
  breeds.sort((a, b) => a.experienceCents.compareTo(b.experienceCents));

  // Generate a bunch of drops.
  var tries = 0;
  var drops = {};

  for (var breed in breeds) {
    drops[breed.name] = {};
  }

  for (var i = 0; i < 1000; i++) {
    tries++;

    for (Breed breed in breeds) {
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
            <span style="color: ${glyph.fore.cssColor}">${new String.fromCharCodes([glyph.char])}</span>
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
        (attack) => '${Log.makeVerbsAgree(attack.verb, breed.pronoun)} (${attack.averageDamage})');
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

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table').setInnerHtml(text.toString(),
      validator: validator);
}
