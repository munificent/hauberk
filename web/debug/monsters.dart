import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/debug/histogram.dart';
import 'package:hauberk/src/debug/table.dart';
import 'package:hauberk/src/engine.dart';
import 'package:malison/malison.dart';

final validator = html.NodeValidatorBuilder.common()..allowInlineStyles();
final breedDrops = <Breed, Histogram<String>>{};

void main() {
  createContent();

  var table = Table<Breed>("table", (a, b) {
    if (a.depth != b.depth) return a.depth.compareTo(b.depth);
    return a.experience.compareTo(b.experience);
  });

  table.column('Breed',
      compare: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  table.column('Depth', right: true);
  table.column('Health', right: true);
  table.column('Meander', right: true);
  table.column('Speed', right: true);
  table.column('Dodge',
      compare: (a, b) => _totalDodge(a).compareTo(_totalDodge(b)));
  table.column('Exp', right: true);
  table.column('Count', compare: (a, b) {
    if (a.countMin != b.countMin) return a.countMin.compareTo(b.countMin);
    return a.countMax.compareTo(b.countMax);
  });
  table.column('Attacks');
  table.column('Moves');
  table.column('Tags');
  table.column('Flags');

  for (var breed in Monsters.breeds.all) {
    var cells = <Object?>[];

    var glyph = breed.appearance as Glyph;
    cells.add('<code class="term"><span style="color: ${glyph.fore.cssColor}">'
        '${String.fromCharCodes([glyph.char])}'
        '</span></code>&nbsp;${breed.name}');

    cells.add(breed.depth);
    cells.add(breed.maxHealth);
    cells.add(breed.meander);
    cells.add(breed.speed);
    cells.add(_dodgesAndDefenses(breed).join('+'));
    cells.add(breed.experience);

    var count = breed.countMin.toString();
    if (breed.countMax != breed.countMin) {
      count += ":${breed.countMax}";
    }
    cells.add(count);

    var attacks = breed.attacks.map(
        (attack) => '${Log.conjugate(attack.verb, breed.pronoun)} $attack');
    cells.add(attacks.join('<br>'));

    cells.add(breed.moves.join("<br>"));

    cells.add([
      for (var tag in Monsters.breeds.getTags(breed.name))
        if (tag != "monster") tag,
    ].join(" "));

    cells.add(breed.flags.names.join(" "));

    table.row(breed, cells);
  }

  table.render();
}

int _totalDodge(Breed breed) =>
    _dodgesAndDefenses(breed).reduce((a, b) => a + b);

List<int> _dodgesAndDefenses(Breed breed) {
  return [breed.dodge, for (var defense in breed.defenses) defense.amount];
}
