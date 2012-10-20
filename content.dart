library content;

import 'dart:math' as math;
import 'engine.dart';
import 'ui.dart';
import 'util.dart';

part 'content/areas.dart';
part 'content/dungeon.dart';
part 'content/feature_creep.dart';
part 'content/items.dart';
part 'content/maze.dart';
part 'content/monsters.dart';
part 'content/recipes.dart';
part 'content/skills.dart';
part 'content/tiles.dart';

final List<Area> _areas = [];
final Map<String, Skill> _skills = {};
final Map<String, ItemType> _items = {};
final Map<String, Breed> _breeds = {};
final List<Recipe> _recipes = [];

Content createContent() {
  // Note: The order is significant here. For example, monster drops will
  // reference items, which need to have already been created.
  new TileBuilder().build();
  new SkillBuilder().build();
  new ItemBuilder().build();
  new MonsterBuilder().build();
  new AreaBuilder().build();
  new RecipeBuilder().build();

  // The items that a new hero starts with.
  final heroItems = [
    _items['Mending Salve'],
    _items['Scroll of Sidestepping']
  ];

  return new Content(_areas, _breeds, _items, _recipes, _skills, heroItems);
}

/// Base class for a builder that provides a DSL for creating game content.
class ContentBuilder {
  Drop hunting(drop) {
    return new SkillDrop(_skills['Hunting'], _parseDrop(drop));
  }

  Drop botany(drop) {
    return new SkillDrop(_skills['Botany'], _parseDrop(drop));
  }

  Drop chanceOf(int percent, drop) {
    return new OneOfDrop([_parseDrop(drop)], [percent]);
  }

  Drop _parseDrop(drop) {
    if (drop == null) return new OneOfDrop([], []);
    if (drop is Drop) return drop;
    if (drop is String) return new ItemDrop(_items[drop]);

    if (drop is List) {
      final drops = [];
      final percents = [];

      for (final element in drop) {
        if (element is OneOfDrop && element.drops.length == 1) {
          drops.add(element.drops[0]);
          percents.add(element.percents[0]);
        } else {
          // A drop without an explicit chance will just have an even chance.
          drops.add(_parseDrop(element));
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

      return new OneOfDrop(drops, percents);
    }

    throw 'Unknown drop type $drop.';
  }

  Attack attack(String verb, int damage, [Element element = Element.NONE,
      Noun noun]) {
    return new Attack(verb, damage, element, noun);
  }

  Glyph black(String char)       => new Glyph(char, Color.BLACK);
  Glyph white(String char)       => new Glyph(char, Color.WHITE);
  Glyph lightGray(String char)   => new Glyph(char, Color.LIGHT_GRAY);
  Glyph gray(String char)        => new Glyph(char, Color.GRAY);
  Glyph darkGray(String char)    => new Glyph(char, Color.DARK_GRAY);
  Glyph lightRed(String char)    => new Glyph(char, Color.LIGHT_RED);
  Glyph red(String char)         => new Glyph(char, Color.RED);
  Glyph darkRed(String char)     => new Glyph(char, Color.DARK_RED);
  Glyph lightOrange(String char) => new Glyph(char, Color.LIGHT_ORANGE);
  Glyph orange(String char)      => new Glyph(char, Color.ORANGE);
  Glyph darkOrange(String char)  => new Glyph(char, Color.DARK_ORANGE);
  Glyph lightGold(String char)   => new Glyph(char, Color.LIGHT_GOLD);
  Glyph gold(String char)        => new Glyph(char, Color.GOLD);
  Glyph darkGold(String char)    => new Glyph(char, Color.DARK_GOLD);
  Glyph lightYellow(String char) => new Glyph(char, Color.LIGHT_YELLOW);
  Glyph yellow(String char)      => new Glyph(char, Color.YELLOW);
  Glyph darkYellow(String char)  => new Glyph(char, Color.DARK_YELLOW);
  Glyph lightGreen(String char)  => new Glyph(char, Color.LIGHT_GREEN);
  Glyph green(String char)       => new Glyph(char, Color.GREEN);
  Glyph darkGreen(String char)   => new Glyph(char, Color.DARK_GREEN);
  Glyph lightAqua(String char)   => new Glyph(char, Color.LIGHT_AQUA);
  Glyph aqua(String char)        => new Glyph(char, Color.AQUA);
  Glyph darkAqua(String char)    => new Glyph(char, Color.DARK_AQUA);
  Glyph lightBlue(String char)   => new Glyph(char, Color.LIGHT_BLUE);
  Glyph blue(String char)        => new Glyph(char, Color.BLUE);
  Glyph darkBlue(String char)    => new Glyph(char, Color.DARK_BLUE);
  Glyph lightPurple(String char) => new Glyph(char, Color.LIGHT_PURPLE);
  Glyph purple(String char)      => new Glyph(char, Color.PURPLE);
  Glyph darkPurple(String char)  => new Glyph(char, Color.DARK_PURPLE);
  Glyph lightBrown(String char)  => new Glyph(char, Color.LIGHT_BROWN);
  Glyph brown(String char)       => new Glyph(char, Color.BROWN);
  Glyph darkBrown(String char)   => new Glyph(char, Color.DARK_BROWN);
}
