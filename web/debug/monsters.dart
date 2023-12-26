import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/engine.dart';
import 'package:malison/malison.dart';

import 'histogram.dart';
import 'html_builder.dart';

final validator = html.NodeValidatorBuilder.common()..allowInlineStyles();
final breedDrops = <Breed, Histogram<String>>{};

void main() {
  createContent();

  var breeds = Monsters.breeds.all.toList();
  breeds.sort((a, b) {
    if (a.depth != b.depth) return a.depth.compareTo(b.depth);
    return a.experience.compareTo(b.experience);
  });

  var builder = HtmlBuilder();
  builder.thead();
  builder.td('Breed', colspan: 2);
  builder.td('Depth');
  builder.td('Health');
  builder.td('Meander');
  builder.td('Speed');
  builder.td('Dodge');
  builder.td('Exp', right: true);
  builder.td('Count');
  builder.td('Attacks');
  builder.td('Moves');
  builder.td('Tags and flags');
  builder.td('Drops', width: '20%');
  builder.tbody();

  for (var breed in breeds) {
    var glyph = breed.appearance as Glyph;

    builder.td('<pre><span style="color: ${glyph.fore.cssColor}">'
        '${String.fromCharCodes([glyph.char])}'
        '</span></pre>');

    builder.td(breed.name);
    builder.td(breed.depth);
    builder.td(breed.maxHealth);
    builder.td(breed.meander);
    builder.td(breed.speed);

    builder.tdBegin();
    builder.write(breed.dodge.toString());
    if (breed.defenses.isNotEmpty) {
      builder.write('+${breed.defenses.map((e) => e.amount).join("+")}');
    }
    builder.tdEnd();

    builder.td(breed.experience);

    var count = breed.countMin.toString();
    if (breed.countMax != breed.countMin) {
      count += ":${breed.countMax}";
    }

    builder.td(count, right: true);

    var attacks = breed.attacks.map(
        (attack) => '${Log.conjugate(attack.verb, breed.pronoun)} $attack');
    builder.td(attacks.join('<br>'));

    builder.td(breed.moves.join("<br>"));

    builder.td([
      for (var tag in Monsters.breeds.getTags(breed.name))
        if (tag != "monster") tag,
      ...breed.flags.names,
    ].join(" "));

    builder.td('<span class="drop" id="${breed.name}">(drops)</span>');

    builder.trEnd();
  }

  builder.replaceContents('table');

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
    breed.drop.dropItem(breed.depth, (item) {
      drops.add(item.toString());
    });
  }

  span.innerHtml = drops.descending().map((name) {
    return "$name (${drops.count(name)})";
  }).join('<br>');
}
