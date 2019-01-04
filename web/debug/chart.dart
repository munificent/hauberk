import 'dart:html' as html;
import 'dart:svg' as svg;

import 'package:malison/malison.dart';

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/item/affixes.dart';
import 'package:hauberk/src/content/item/floor_drops.dart';
import 'package:hauberk/src/content/item/items.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/content/stage/architectural_style.dart';

import 'histogram.dart';

const batchSize = 1000;
const chartWidth = 600;
const barSize = 6;

final _svg = html.querySelector("svg") as svg.SvgElement;

final List<Chart> _charts = [
  BreedChart(),
  ItemTypesChart(),
  AffixesChart(),
  MonsterDepthsChart(),
  FloorDropsChart(),
  ArchitecturesChart()
];

final _colors = <String, String>{};

Chart get currentChart {
  var select = html.querySelector("select") as html.SelectElement;
  return _charts.firstWhere((chart) => chart.name == select.value);
}

main() {
  Items.initialize();
  Affixes.initialize();
  Monsters.initialize();
  FloorDrops.initialize();

  for (var itemType in Items.types.all) {
    _colors[itemType.name] = (itemType.appearance as Glyph).fore.cssColor;
    _colors["${itemType.name} (ego)"] =
        (itemType.appearance as Glyph).fore.blend(Color.black, 0.5).cssColor;
  }

  for (var breed in Monsters.breeds.all) {
    _colors[breed.name] = (breed.appearance as Glyph).fore.cssColor;
  }

  for (var i = -100; i <= 100; i++) {
    _colors[i.toString()] = "hsl(${(i + 100) * 10 % 360}, 70%, 40%)";
  }

  _svg.onClick.listen((_) => currentChart.generateMore());

  var select = html.querySelector("select") as html.SelectElement;
  select.onChange.listen((_) {
    currentChart.draw();
  });

  currentChart.generateMore();
}

abstract class Chart {
  final histograms = List.generate(Option.maxDepth, (_) => Histogram<String>());

  String get name;

  Iterable<String> get labels;

  void generateMore() {
    for (var depth = 1; depth <= Option.maxDepth; depth++) {
      var histogram = histograms[depth - 1];

      for (var i = 0; i < batchSize; i++) {
        generate(histogram, depth);
      }
    }

    draw();
  }

  void generate(Histogram<String> histogram, int depth);

  String describe(String label);

  void draw() {
    var buffer = StringBuffer();

    for (var depth = 0; depth < Option.maxDepth; depth++) {
      var histogram = histograms[depth];
      var total = 0;
      for (var label in labels) {
        total += histogram.count(label);
      }

      var x = chartWidth.toDouble();
      var y = depth * barSize;
      var right = chartWidth.toDouble();

      for (var label in labels) {
        var count = histogram.count(label);
        if (count == 0) continue;

        var fraction = count / total;
        var percent = ((fraction * 1000).toInt() / 10).toStringAsFixed(1);
        x -= fraction * chartWidth;
        buffer.write('<rect fill="${_colors[label]}" x="$x" y="$y" '
            'width="${right - x}" height="$barSize">');
        buffer.write('<title>depth ${depth + 1}: ${describe(label)} $percent% '
            '($count)</title></rect>');

        right = x;
      }
    }

    _svg.setInnerHtml(buffer.toString());
  }
}

class BreedChart extends Chart {
  final _labels = _makeLabels();

  static List<String> _makeLabels() {
    var names = Monsters.breeds.all.map((breed) => breed.name).toList();
    names.sort((a, b) {
      var aBreed = Monsters.breeds.find(a);
      var bBreed = Monsters.breeds.find(b);

      if (aBreed.depth != bBreed.depth) {
        return aBreed.depth.compareTo(bBreed.depth);
      }

      if (aBreed.experience != bBreed.experience) {
        return aBreed.experience.compareTo(bBreed.experience);
      }

      return aBreed.name.compareTo(bBreed.name);
    });
    return names;
  }

  String get name => "breeds";

  Iterable<String> get labels => _labels;

  void generate(Histogram<String> histogram, int depth) {
    var breed = Monsters.breeds.tryChoose(depth);
    if (breed == null) return;

    // Take groups and minions into account.
    for (var spawn in breed.spawnAll()) {
      histogram.add(spawn.name);
    }
  }

  String describe(String label) {
    var breed = Monsters.breeds.find(label);
    return "$label (depth ${breed.depth})";
  }
}

class ItemTypesChart extends Chart {
  static final _labels = _makeLabels();

  static List<String> _makeLabels() {
    var names = Items.types.all.map((type) => type.name).toList();
    names.sort((a, b) {
      var aType = Items.types.find(a);
      var bType = Items.types.find(b);

      if (aType.depth != bType.depth) {
        return aType.depth.compareTo(bType.depth);
      }

      if (aType.price != bType.price) {
        return aType.price.compareTo(bType.price);
      }

      return aType.name.compareTo(bType.name);
    });

    names.addAll(names.map((name) => "$name (ego)").toList());
    return names;
  }

  String get name => "item-types";

  Iterable<String> get labels => _labels;

  void generate(Histogram<String> histogram, int depth) {
    var itemType = Items.types.tryChoose(depth);
    if (itemType == null) return;

    var item = Affixes.createItem(itemType, depth);
    if (item.prefix != null || item.suffix != null) {
      histogram.add("${itemType.name} (ego)");
    } else {
      histogram.add(itemType.name);
    }
  }

  String describe(String label) {
    var typeName = label;
    if (typeName.endsWith(" (ego)")) {
      typeName = typeName.substring(0, typeName.length - 6);
    }

    var type = Items.types.find(typeName);
    return "$label (depth ${type.depth})";
  }
}

class AffixesChart extends Chart {
  static final _labels = _makeLabels();

  static List<String> _makeLabels() {
    var names = ["(none)"];
    names.addAll(Affixes.prefixes.all.map((affix) => "${affix.name} _"));
    names.addAll(Affixes.suffixes.all.map((affix) => "_ ${affix.name}"));

    // TODO: Sort by depth and rarity?
    names.sort();

    for (var i = 0; i < names.length; i++) {
      _colors[names[i]] = 'hsl(${i * 17 % 360}, 50%, 50%)';
    }

    return names;
  }

  String get name => "affixes";

  Iterable<String> get labels => _labels;

  void generate(Histogram<String> histogram, int depth) {
    var itemType = Items.types.tryChoose(depth, tag: "equipment");
    if (itemType == null) return;

    // Don't count items that can't have affixes.
    if (!Items.types.hasTag(itemType.name, "equipment")) return;

    var item = Affixes.createItem(itemType, depth);

    if (item.prefix != null) histogram.add("${item.prefix.name} _");
    if (item.suffix != null) histogram.add("_ ${item.suffix.name}");
    if (item.prefix == null && item.suffix == null) histogram.add("(none)");
  }

  String describe(String label) => label;
}

class MonsterDepthsChart extends Chart {
  String get name => "monster-depths";
  final List<String> labels = [];

  MonsterDepthsChart() {
    for (var i = -100; i <= 100; i++) {
      labels.add("$i");
    }
  }

  void generate(Histogram<String> histogram, int depth) {
    var breed = Monsters.breeds.tryChoose(depth);
    if (breed == null) return;

    histogram.add((breed.depth - depth).toString());
  }

  String describe(String label) {
    var relative = int.parse(label);
    if (relative == 0) return "same";
    if (relative < 0) return "${-relative} shallower monster";
    return "$label deeper monster";
  }
}

class FloorDropsChart extends Chart {
  String get name => "floor-drops";

  Iterable<String> get labels => ItemTypesChart._labels;

  void generate(Histogram<String> histogram, int depth) {
    var drop = FloorDrops.choose(depth);
    drop.drop.spawnDrop(depth, (item) {
      histogram.add(item.type.name);
    });
  }

  String describe(String label) {
    var type = Items.types.find(label);
    return "$label (depth ${type.depth})";
  }
}

class ArchitecturesChart extends Chart {
  static final List<String> _labels = _makeLabels();

  static List<String> _makeLabels() {
    var labels = <String>[];
    for (var style in ArchitecturalStyle.styles.all) {
      labels.add(style.name);
    }

    for (var i = 0; i < labels.length; i++) {
      _colors[labels[i]] = 'hsl(${i * 17 % 360}, 50%, 50%)';
    }

    return labels;
  }

  String get name => "architectures";

  Iterable<String> get labels => _labels;

  void generate(Histogram<String> histogram, int depth) {
    var styles = ArchitecturalStyle.pick(depth);
    for (var style in styles) {
      histogram.add(style.name);
    }
  }

  // TODO: Show min and max depths?
  String describe(String label) => label;
}
