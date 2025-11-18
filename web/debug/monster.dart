import 'dart:js_interop';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/debug/histogram.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/engine.dart';
import 'package:malison/malison.dart';
import 'package:web/web.dart' as web;

web.HTMLSelectElement get _breedSelect =>
    web.document.querySelector("#breed") as web.HTMLSelectElement;

Breed get _selectedBreed => Monsters.breeds.find(_breedSelect.value);

void main() {
  createContent();

  var selectedBreed = Monsters.breeds.all.first;

  // If there's a URL hash, show that monster.
  if (web.window.location.hash.isNotEmpty) {
    // Trim the leading "#".
    var name = Uri.decodeFull(
      web.window.location.hash.substring(1),
    ).toLowerCase();

    for (var breed in Monsters.breeds.all) {
      if (breed.name.toLowerCase() == name) {
        selectedBreed = breed;
        break;
      }
    }
  }

  for (var breed in Monsters.breeds.all) {
    var glyph = breed.appearance as Glyph;
    _breedSelect.append(
      web.HTMLOptionElement()
        ..text = '[${String.fromCharCode(glyph.char)}] ${breed.name}'
        ..value = breed.name
        ..selected = breed == selectedBreed,
    );
  }

  _breedSelect.onChange.listen((event) {
    _update();
  });

  _update();
}

// TODO: There is similar code in generation.dart. Unify.
void _update() {
  var breed = _selectedBreed;

  web.document.querySelector('h1')!.innerHTML =
      '<a href="index.html">Debug</a> / Monster /  ${breed.name}'.toJS;
  web.window.location.hash = Uri.encodeFull(breed.name);

  const dropTries = 1000;

  var items = Histogram<String>();
  var affixes = Histogram<String>();

  for (var i = 0; i < dropTries; i++) {
    // Create a blank lore each time so that we can count how often a given
    // artifact shows up without uniqueness coming into play.
    var lore = Lore();

    breed.drop.dropItem(lore, breed.depth, (item) {
      items.add(item.type.name);

      for (var affix in item.affixes) {
        affixes.add(affix.type.id);
      }
    });
  }

  var builder = HtmlBuilder();
  builder.thead();
  builder.td('Items');
  builder.td('Affixes');
  builder.tbody();

  void renderColumn(Histogram<String> histogram, int max) {
    builder.tdBegin(width: '25%');
    for (var name in histogram.descending()) {
      var count = histogram.count(name);
      var width = 100 * count ~/ max;
      var percent = (100 * count / histogram.total)
          .toStringAsFixed(2)
          .padLeft(5, "0");
      var chance = (count / dropTries).toStringAsFixed(2).padLeft(6);

      builder.write(
        '<span style="font-family: monospace;">$percent% $chance </span>',
      );
      builder.write('<div class="bar" style="width: ${width}px;"></div> $name');
      builder.write('<br>');
    }

    builder.tdEnd();
  }

  renderColumn(items, items.max);
  renderColumn(affixes, items.max);

  builder.tbodyEnd();
  builder.replaceContents('#drops');
}
