library hauberk.content;

import 'engine.dart';

import 'content/affixes.dart';
import 'content/areas.dart';
import 'content/items.dart';
import 'content/monsters.dart';
import 'content/recipes.dart';
import 'content/tiles.dart';

Content createContent() {
  // Note: The order is significant here. For example, monster drops will
  // reference items, which need to have already been created.
  new Tiles().build();
  new Items().build();
  new Monsters().build();
  new Areas().build();
  new Recipes().build();
  Affixes.build();

  return new GameContent();
}

class GameContent implements Content {
  List<Area> get areas => Areas.all;
  Map<String, Breed> get breeds => Monsters.all;
  Map<String, ItemType> get items => Items.all;
  List<Recipe> get recipes => Recipes.all;

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

  Map serializeAffix(Affix affix) => Affixes.serialize(affix);
  Affix deserializeAffix(Map data) => Affixes.deserialize(data);
}
