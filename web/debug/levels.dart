import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

import 'histogram.dart';

/// Number of dungeons generated at each depth.
final generated = <int, int>{};

final allMonsters = List<Histogram<String>>.generate(101, (_) => Histogram());

final allItems = List<Histogram<String>>.generate(101, (_) => Histogram());

final allAffixes = List<Histogram<String>>.generate(101, (_) => Histogram());

final validator = html.NodeValidatorBuilder.common()..allowInlineStyles();

Content content = createContent();

main() {
  for (var i = 1; i <= Option.maxDepth; i++) {
    generated[i] = 0;
  }

  html.querySelector("table").onClick.listen((event) {
    var target = event.target;
    if (target is html.TableCellElement) {
      var row = target.parent;
      if (row.id != null) {
        var depth = int.tryParse(row.id);
        if (depth != null) {
          spawnStuff(depth);
        }
      }
    }
  });

  generateTable();
}

void spawnStuff(int depth) {
  var game = Game(content, content.createHero("temp"), depth);
  for (var _ in game.generate()) {}

  var monsters = allMonsters[depth];
  var items = allItems[depth];
  var affixes = allAffixes[depth];

  for (var actor in game.stage.actors) {
    if (actor is Monster) monsters.add(actor.breed.name);
  }

  for (var item in game.stage.allItems) {
    items.add(item.type.name);

    if (item.prefix != null) affixes.add("${item.prefix.name} _");
    if (item.suffix != null) affixes.add("_ ${item.suffix.name}");
  }

  generated[depth]++;
  generateTable();
}

void generateTable() {
  var text = StringBuffer();

  text.write('''<thead>
    <tr>
      <td>Depth</td>
      <td>Monsters</td>
      <td>Items</td>
      <td>Affixes</td>
    </tr>
  </thead>''');

  for (var depth = 1; depth <= 100; depth++) {
    text.write('<tr id="$depth"><td>$depth</td>');

    renderColumn(Histogram<String> histogram) {
      text.write('<td width="25%">');
      var more = 0;
      for (var name in histogram.descending()) {
        var count = histogram.count(name) / generated[depth];
//        if (count < 1) {
//          more++;
//          continue;
//        }
        if (count > 100) {
          count = 100;
        }

        text.write(
            '<div class="bar" style="width: ${count.toInt()}px;"></div>');
        text.write(" $name (${count.toStringAsFixed(2)})");
        text.write("<br>");
      }

      if (more > 0) {
        text.write("<em>$more more&hellip;</em>");
      }

      text.write('</td>');
    }

    renderColumn(allMonsters[depth]);
    renderColumn(allItems[depth]);
    renderColumn(allAffixes[depth]);

    text.write('</tr>');
  }

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);
}
