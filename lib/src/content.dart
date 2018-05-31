import 'package:piecemeal/piecemeal.dart';

import 'content/classes.dart';
import 'content/dungeon/dungeon.dart';
import 'content/elements.dart';
import 'content/floor_drops.dart';
import 'content/item/affixes.dart';
import 'content/item/items.dart';
import 'content/monster/monsters.dart';
import 'content/old/recipes.dart';
import 'content/old/shops.dart';
import 'content/races.dart';
import 'content/skill/skills.dart';
import 'content/tiles.dart';
import 'engine.dart';

Content createContent() {
  // Note: The order is significant here. For example, monster drops will
  // reference items, which need to have already been created.
  Tiles.initialize();
  Items.initialize();
  Monsters.initialize();
  Recipes.initialize();
  Affixes.initialize();
  Shops.initialize();
  FloorDrops.initialize();

  return new GameContent();
}

class GameContent implements Content {
  Iterable<String> buildStage(
      Lore lore, Stage stage, int depth, Function(Vec) placeHero) {
    return new Dungeon(lore, stage, depth).generate(placeHero);
  }

  Affix findAffix(String name) => Affixes.find(name);
  Breed findBreed(String name) => Monsters.breeds.find(name);
  ItemType tryFindItem(String name) => Items.types.tryFind(name);
  Skill findSkill(String name) => Skills.find(name);

  Iterable<Breed> get breeds => Monsters.breeds.all;
  List<HeroClass> get classes => Classes.all;
  Iterable<Element> get elements => Elements.all;
  List<Race> get races => Races.all;
  Iterable<Skill> get skills => Skills.all;
  Iterable<Recipe> get recipes => Recipes.all;
  Iterable<Shop> get shops => Shops.all;

  HeroSave createHero(String name, [Race race, HeroClass heroClass]) {
    race ??= Races.human;
    heroClass ??= Classes.adventurer;

    var hero = new HeroSave(name, race, heroClass);

    var initialItems = {
      "Mending Salve": 3,
      "Scroll of Sidestepping": 2,
      "Tallow Candle": 4
    };

    // TODO: Need to discover skills for these items too.
    initialItems.forEach((type, amount) {
      hero.inventory.tryAdd(new Item(Items.types.find(type), amount));
    });

    heroClass.startingItems.spawnDrop(hero.inventory.tryAdd);

    return hero;
  }
}
