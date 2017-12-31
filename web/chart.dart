import 'dart:html' as html;
import 'dart:svg' as svg;

import 'package:malison/malison.dart';

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/affixes.dart';
import 'package:hauberk/src/content/items.dart';
import 'package:hauberk/src/content/monsters.dart';

import 'histogram.dart';

final _svg = html.querySelector("svg") as svg.SvgElement;

final _breedCounts =
    new List.generate(Option.maxDepth, (_) => new Histogram<String>());
List<String> _breedNames;

final _itemCounts =
    new List.generate(Option.maxDepth, (_) => new Histogram<String>());
List<String> _itemNames;

final _affixCounts =
    new List.generate(Option.maxDepth, (_) => new Histogram<String>());
List<String> _affixNames;

final _colors = <String, String>{};

const batchSize = 1000;
const chartWidth = 600;
const barSize = 6;

String get shownData {
  var select = html.querySelector("select") as html.SelectElement;
  return select.value;
}

main() {
  Items.initialize();
  Affixes.initialize();
  Monsters.initialize();

  for (var itemType in Items.types.all) {
    _colors[itemType.name] = (itemType.appearance as Glyph).fore.cssColor;
  }

  for (var breed in Monsters.breeds.all) {
    _colors[breed.name] = (breed.appearance as Glyph).fore.cssColor;
  }

  _svg.onClick.listen((_) => _generateMore());

  var select = html.querySelector("select") as html.SelectElement;
  select.onChange.listen((_) {
    switch (shownData) {
      case "breeds":
        _drawBreeds();
        break;

      case "item-types":
        _drawItems();
        break;

      case "affixes":
        _drawAffixes();
        break;

      default:
        throw "Unknown select value '$shownData'.";
    }
  });

  _generateMore();
}

void _generateMore() {
  switch (shownData) {
    case "breeds":
      _moreBreeds();
      break;

    case "item-types":
      _moreItems();
      break;

    case "affixes":
      _moreAffixes();
      break;

    default:
      throw "Unknown select value '$shownData'.";
  }
}

void _moreBreeds() {
  for (var depth = 1; depth <= Option.maxDepth; depth++) {
    var histogram = _breedCounts[depth - 1];

    for (var i = 0; i < batchSize; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      if (breed == null) continue;

      // Take groups and minions into account
      for (var spawn in breed.spawnAll()) {
        histogram.add(spawn.name);
      }
    }
  }

  _drawBreeds();
}

void _moreItems() {
  for (var depth = 1; depth <= Option.maxDepth; depth++) {
    var histogram = _itemCounts[depth - 1];

    for (var i = 0; i < batchSize; i++) {
      var itemType = Items.types.tryChoose(depth, "item");
      if (itemType == null) continue;

      histogram.add(itemType.name);
    }
  }

  _drawItems();
}

void _moreAffixes() {
  for (var depth = 1; depth <= Option.maxDepth; depth++) {
    var histogram = _affixCounts[depth - 1];

    for (var i = 0; i < batchSize; i++) {
      var itemType = Items.types.tryChoose(depth, "item");
      if (itemType == null) continue;

      // Don't count items that can't have affixes.
      if (!Items.types.hasTag(itemType.name, "equipment")) {
        continue;
      }

      var item = Affixes.createItem(itemType, depth);

      if (item.prefix != null) histogram.add("${item.prefix.name} _");
      if (item.suffix != null) histogram.add("_ ${item.suffix.name}");
      if (item.prefix == null && item.suffix == null) histogram.add("(none)");
    }
  }

  _drawAffixes();
}

void _drawBreeds() {
  if (_breedNames == null) {
    _breedNames = Monsters.breeds.all.map((breed) => breed.name).toList();
    _breedNames.sort((a, b) {
      var aBreed = Monsters.breeds.find(a);
      var bBreed = Monsters.breeds.find(b);

      if (aBreed.depth != bBreed.depth) {
        return aBreed.depth.compareTo(bBreed.depth);
      }

      if (aBreed.experienceCents != bBreed.experienceCents) {
        return aBreed.experienceCents.compareTo(bBreed.experienceCents);
      }

      return aBreed.name.compareTo(bBreed.name);
    });
  }

  _redraw(_breedCounts, _breedNames, (label) {
    var breed = Monsters.breeds.find(label);
    return '$label (depth ${breed.depth})';
  });
}

void _drawItems() {
  if (_itemNames == null) {
    _itemNames = Items.types.all.map((type) => type.name).toList();
    _itemNames.sort((a, b) {
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
  }

  _redraw(_itemCounts, _itemNames, (label) {
    var type = Items.types.find(label);
    return '$label (depth ${type.depth})';
  });
}

void _drawAffixes() {
  if (_affixNames == null) {
    _affixNames = ["(none)"];
    _affixNames.addAll(Affixes.prefixes.map((affix) => "${affix.name} _"));
    _affixNames.addAll(Affixes.suffixes.map((affix) => "_ ${affix.name}"));

    // TODO: Sort by depth and rarity?
    _affixNames.sort();
  }

  _redraw(_affixCounts, _affixNames, (label) => label);
}

void _redraw(List<Histogram<String>> histograms, List<String> labels,
    String describe(String label)) {
  var buffer = new StringBuffer();

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

      var color = _colors[label];
      if (color == null) {
        color = 'hsl(${label.hashCode % 360}, 70%, 50%)';
      }

      var fraction = count / total;
      var percent = ((fraction * 1000).toInt() / 10).toStringAsFixed(1);
      x -= fraction * chartWidth;
      buffer.write(
          '<rect fill="$color" x="$x" y="$y" width="${right - x}" height="$barSize">');
      buffer.write(
          '<title>depth ${depth + 1}: ${describe(label)} $percent% ($count)</title></rect>');

      right = x;
    }
  }

  _svg.setInnerHtml(buffer.toString());
}
