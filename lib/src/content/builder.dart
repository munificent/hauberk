library hauberk.content.builder;

import '../engine.dart';
import '../util.dart';
import 'items.dart';

final _categoryDropPattern = new RegExp(r"([a-z/]+):(\d+)");

/// Base class for a builder that provides a DSL for creating game content.
class ContentBuilder {
  Drop allOf(drop) {
    var drops = [];
    var percents = [];
    _parsePercentList(drop, drops, percents);
    return new AllOfDrop(drops, percents);
  }

  Drop chanceOf(int percent, drop) {
    return new OneOfDrop([parseDrop(drop)], [percent]);
  }

  /// Parses a drop description. It can be any of:
  ///
  ///  *  If it's a string like "equipment 10" or "magic/scroll 4" then it's
  ///     a group drop. The leading string is the path to the group to choose
  ///     from and the trailing number is the level of the drop.
  ///  *  If it's any other string, that's the (singular) name of an item type
  ///     to drop.
  ///  *  If it's a list, each element is in turn parsed as a drop, and the
  ///     outer drop selects from one of them.
  Drop parseDrop(drop) {
    if (drop == null) return new OneOfDrop([], []);
    if (drop is Drop) return drop;

    if (drop is String) {
      // See if it's a category.
      var match = _categoryDropPattern.firstMatch(drop);
      if (match != null) {
        var category = match[1];

        // Find an item in this category so we can figure out the full path
        // to it.
        var categories;
        for (var item in Items.all.values) {
          if (item.categories.contains(category)) {
            categories = item.categories;
            break;
          }
        }

        if (categories == null) {
          throw 'Could not find item in category "$category".';
        }

        var level = int.parse(match[2]);
        return new CategoryDrop(categories, level);
      }

      // Otherwise, just drop that item.
      var itemType = Items.all[drop];
      if (itemType == null) throw "Couldn't find item type $drop.";

      // See if the item is in a group.
      return new ItemDrop(itemType);
    }

    if (drop is List) {
      var drops = [];
      var percents = [];
      _parsePercentList(drop, drops, percents);
      return new OneOfDrop(drops, percents);
    }

    throw 'Unknown drop type $drop.';
  }

  /// Parses the drops in [drop] into percent/drop pairs, normalizes the odds,
  /// and populates [drops] and [percents] with the results.
  void _parsePercentList(List drop, List<Drop> drops, List<int> percents) {
    for (var element in drop) {
      if (element is OneOfDrop && element.drops.length == 1) {
        drops.add(element.drops[0]);
        percents.add(element.percents[0]);
      } else {
        // A drop without an explicit chance will just have an even chance.
        drops.add(parseDrop(element));
        percents.add(null);
      }
    }

    // Fix up the calculated percents.
    var remaining = 100;
    var calculated = [];
    for (var i = 0; i < percents.length; i++) {
      if (percents[i] != null) {
        remaining -= percents[i];
      } else {
        calculated.add(i);
      }
    }

    for (var i = 0; i < calculated.length; i++) {
      if (i == calculated.length - 1) {
        // Handle the last calculated one to round up. Ensures that if,
        // for example there are three calculated ones, you don't get
        // 33/33/33 and then have a 1% chance of not dropping anything.
        percents[i] = remaining -
            (remaining ~/ calculated.length * (calculated.length - 1));
      } else {
        percents[i] = remaining ~/ calculated.length;
      }
    }
  }

  Attack attack(String verb, int damage, [Element element = Element.NONE,
      Noun noun]) {
    return new Attack(verb, damage, element, noun);
  }

  Glyph black(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.BLACK, back);
  Glyph white(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.WHITE, back);
  Glyph lightGray(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_GRAY, back);
  Glyph gray(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.GRAY, back);
  Glyph darkGray(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_GRAY, back);
  Glyph lightRed(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.LIGHT_RED, back);
  Glyph red(char, [Color back = Color.BLACK])         => new Glyph.fromDynamic(char, Color.RED, back);
  Glyph darkRed(char, [Color back = Color.BLACK])     => new Glyph.fromDynamic(char, Color.DARK_RED, back);
  Glyph lightOrange(char, [Color back = Color.BLACK]) => new Glyph.fromDynamic(char, Color.LIGHT_ORANGE, back);
  Glyph orange(char, [Color back = Color.BLACK])      => new Glyph.fromDynamic(char, Color.ORANGE, back);
  Glyph darkOrange(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.DARK_ORANGE, back);
  Glyph lightGold(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_GOLD, back);
  Glyph gold(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.GOLD, back);
  Glyph darkGold(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_GOLD, back);
  Glyph lightYellow(char, [Color back = Color.BLACK]) => new Glyph.fromDynamic(char, Color.LIGHT_YELLOW, back);
  Glyph yellow(char, [Color back = Color.BLACK])      => new Glyph.fromDynamic(char, Color.YELLOW, back);
  Glyph darkYellow(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.DARK_YELLOW, back);
  Glyph lightGreen(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.LIGHT_GREEN, back);
  Glyph green(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.GREEN, back);
  Glyph darkGreen(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.DARK_GREEN, back);
  Glyph lightAqua(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_AQUA, back);
  Glyph aqua(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.AQUA, back);
  Glyph darkAqua(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_AQUA, back);
  Glyph lightBlue(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_BLUE, back);
  Glyph blue(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.BLUE, back);
  Glyph darkBlue(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_BLUE, back);
  Glyph lightPurple(char, [Color back = Color.BLACK]) => new Glyph.fromDynamic(char, Color.LIGHT_PURPLE, back);
  Glyph purple(char, [Color back = Color.BLACK])      => new Glyph.fromDynamic(char, Color.PURPLE, back);
  Glyph darkPurple(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.DARK_PURPLE, back);
  Glyph lightBrown(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.LIGHT_BROWN, back);
  Glyph brown(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.BROWN, back);
  Glyph darkBrown(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.DARK_BROWN, back);
}
