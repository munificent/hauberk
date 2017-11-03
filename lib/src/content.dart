import 'package:piecemeal/piecemeal.dart';

import 'engine.dart';

import 'content/affixes.dart';
import 'content/dungeon/dungeon.dart';
import 'content/encounters.dart';
import 'content/items.dart';
import 'content/monsters.dart';
import 'content/recipes.dart';
import 'content/shops.dart';
import 'content/tiles.dart';

Content createContent() {
  // Note: The order is significant here. For example, monster drops will
  // reference items, which need to have already been created.
  Tiles.initialize();
  Items.initialize();
  Monsters.initialize();
  Recipes.initialize();
  Affixes.initialize();
  Shops.initialize();
  Encounters.initialize();

  return new GameContent();
}

class GameContent implements Content {
  Iterable<String> buildStage(Stage stage, int depth, Function(Vec) placeHero) {
    return new Dungeon(stage, depth).generate(placeHero);
  }

  Affix findAffix(String name) => Affixes.find(name);
  ItemType tryFindItem(String name) => Items.types.tryFind(name);

  List<Recipe> get recipes => Recipes.all;
  List<Shop> get shops => Shops.all;

  HeroSave createHero(String name) {
    var hero = new HeroSave(name);
    for (var itemType in [
      Items.types.find("Mending Salve"),
      Items.types.find("Scroll of Sidestepping")
    ]) {
      hero.inventory.tryAdd(new Item(itemType, 1));
    }

    return hero;
  }
}
