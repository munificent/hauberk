import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/debug/histogram.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/engine.dart';
import 'package:malison/malison.dart';

html.SelectElement get _breedSelect =>
    html.querySelector("#breed") as html.SelectElement;

Breed get _selectedBreed => Monsters.breeds.find(_breedSelect.value!);

void main() {
  createContent();

  var selectedBreed = Monsters.breeds.all.first;

  // If there's a URL hash, show that monster.
  if (html.window.location.hash.isNotEmpty) {
    // Trim the leading "#".
    var name =
        Uri.decodeFull(html.window.location.hash.substring(1)).toLowerCase();

    for (var breed in Monsters.breeds.all) {
      if (breed.name.toLowerCase() == name) {
        selectedBreed = breed;
        break;
      }
    }
  }

  for (var breed in Monsters.breeds.all) {
    var glyph = breed.appearance as Glyph;
    _breedSelect.append(html.OptionElement(
        data: '[${String.fromCharCode(glyph.char)}] ${breed.name}',
        value: breed.name,
        selected: breed == selectedBreed));
  }

  _breedSelect.onChange.listen((event) {
    _update();
  });

  _update();
}

// TODO: There is similar code in generation.dart. Unify.
void _update() {
  var breed = _selectedBreed;

  html.querySelector('h1')!.innerHtml =
      '<a href="index.html">Debug</a> / Monster /  ${breed.name}';
  html.window.location.hash = Uri.encodeFull(breed.name);

  const dropTries = 1000;

  var items = Histogram<String>();
  var affixes = Histogram<String>();

  for (var i = 0; i < dropTries; i++) {
    breed.drop.dropItem(breed.depth, (item) {
      items.add(item.type.name);

      for (var affix in item.affixes) {
        affixes.add(affix.id);
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
      var percent =
          (100 * count / histogram.total).toStringAsFixed(2).padLeft(5, "0");
      var chance = (count / dropTries).toStringAsFixed(2).padLeft(6);

      builder.write(
          '<span style="font-family: monospace;">$percent% $chance </span>');
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
