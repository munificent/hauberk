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
final _chart = html.querySelector("select[name=chart]") as html.SelectElement;
final _highlight =
    html.querySelector("select[name=highlight]") as html.SelectElement;

final List<Chart> _charts = [
  BreedChart(),
  ItemTypesChart(),
  AffixesChart(),
  MonsterDepthsChart(),
  FloorDropsChart(),
  ArchitecturesChart()
];

final _colors = <String, Color>{};

Chart get currentChart {
  return _charts.firstWhere((chart) => chart.name == _chart.value);
}

void main() {
  Items.initialize();
  Affixes.initialize();
  Monsters.initialize();
  FloorDrops.initialize();

  for (var itemType in Items.types.all) {
    _colors[itemType.name] = (itemType.appearance as Glyph).fore;
    _colors["${itemType.name} (ego)"] =
        (itemType.appearance as Glyph).fore.blend(Color.black, 0.5);
  }

  for (var breed in Monsters.breeds.all) {
    _colors[breed.name] = (breed.appearance as Glyph).fore;
  }

  for (var i = -100; i <= 100; i++) {
    _colors[i.toString()] = _rainbow((i + 100) * 10);
  }

  _svg.onClick.listen((_) => currentChart.generateMore());

  _chart.onChange.listen((_) {
    currentChart.refresh();
  });

  _highlight.onChange.listen((_) {
    currentChart.refresh();
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

    refresh();
  }

  void generate(Histogram<String> histogram, int depth);

  String describe(String label);

  void refresh() {
    var buffer = StringBuffer();

    var currentHighlight = _highlight.value;

    buffer.writeln('<option value="">(none)</option>');
    for (var label in labels) {
      var selected = currentHighlight == label ? "selected" : "";
      buffer.writeln('<option value="$label" $selected>$label</option>');
    }

    _highlight.setInnerHtml(buffer.toString());

    _draw();
  }

  void _draw() {
    var highlight = _highlight.value;

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

        var color = _colors[label];
        if (highlight != "" && label != highlight) {
          color = color.blend(Color.white, 0.80);
        }

        buffer.write('<rect fill="${color.cssColor}" x="$x" y="$y" '
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
    var names = [
      "(none)",
      ...Affixes.prefixes.all.map((affix) => "${affix.name} _"),
      ...Affixes.suffixes.all.map((affix) => "_ ${affix.name}"),
    ];

    // TODO: Sort by depth and rarity?
    names.sort();

    for (var i = 0; i < names.length; i++) {
      _colors[names[i]] = _rainbow(i * 17);
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
    drop.drop.dropItem(depth, (item) {
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
      _colors[labels[i]] = _rainbow(i * 17);
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

Color _rainbow(int hue) {
  var normal = (hue % 360) / 60.0;

  if (normal < 1.0) {
    return Color.red.blend(Color.yellow, normal);
  } else if (normal < 2.0) {
    return Color.yellow.blend(Color.green, normal - 1.0);
  } else if (normal < 3.0) {
    return Color.green.blend(Color.aqua, normal - 2.0);
  } else if (normal < 4.0) {
    return Color.aqua.blend(Color.blue, normal - 3.0);
  } else if (normal < 5.0) {
    return Color.blue.blend(Color.purple, normal - 4.0);
  } else {
    return Color.purple.blend(Color.red, normal - 5.0);
  }
}
