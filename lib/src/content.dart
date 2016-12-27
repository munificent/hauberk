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
  void buildStage(Stage stage) {
    // TODO: Get rid of dungeon subclasses.
    // TODO: Tweak parameters based on depth.
    new Dungeon().generate(stage);
  }

  Map<String, Breed> get breeds => Monsters.all;
  Map<String, ItemType> get items => Items.all;
  List<Recipe> get recipes => Recipes.all;
  List<Shop> get shops => Shops.all;

  HeroSave createHero(String name, HeroClass heroClass) {
    var hero = new HeroSave(name, heroClass);
    for (var itemType in [
      Items.all["Mending Salve"],
      Items.all["Scroll of Sidestepping"]
    ]) {
      hero.inventory.tryAdd(new Item(itemType));
    }

    return hero;
  }
}
