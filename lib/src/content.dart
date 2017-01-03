import 'engine.dart';

import 'content/affixes.dart';
import 'content/dungeon.dart';
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

  return new GameContent();
}

class GameContent implements Content {
  void buildStage(Stage stage, int depth) {
    new Dungeon(stage, depth).generate();
  }

  Affix findAffix(String name) => Affixes.find(name);
  ItemType findItem(String name) => Items.types.find(name);

  List<Recipe> get recipes => Recipes.all;
  List<Shop> get shops => Shops.all;

  HeroSave createHero(String name, HeroClass heroClass) {
    var hero = new HeroSave(name, heroClass);
    for (var itemType in [
      Items.types.find("Mending Salve"),
      Items.types.find("Scroll of Sidestepping")
    ]) {
      hero.inventory.tryAdd2(new Item(itemType, 1));
    }

    return hero;
  }
}
