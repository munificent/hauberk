library dngn.content.builder;

import '../engine.dart';
import '../ui.dart';
import 'items.dart';
import 'skills.dart';

/// Base class for a builder that provides a DSL for creating game content.
class ContentBuilder {
  Drop hunting(drop) {
    return new SkillDrop(Skills.all['Hunting'], parseDrop(drop));
  }

  Drop botany(drop) {
    return new SkillDrop(Skills.all['Botany'], parseDrop(drop));
  }

  Drop allOf(drop) {
    var drops = [];
    var percents = [];
    _parsePercentList(drop, drops, percents);
    return new AllOfDrop(drops, percents);
  }

  Drop chanceOf(int percent, drop) {
    return new OneOfDrop([parseDrop(drop)], [percent]);
  }

  Drop parseDrop(drop) {
    if (drop == null) return new OneOfDrop([], []);
    if (drop is Drop) return drop;

    if (drop is String) {
      // Look for a matching sequence.
      var sequence = Items.sequences[drop];
      if (sequence != null) {
        return sequence.drop(drop);
      }

      // Otherwise, just drop that item.
      return new ItemDrop(Items.all[drop]);
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
