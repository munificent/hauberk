import 'package:piecemeal/piecemeal.dart';

import 'content/action/element.dart';
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
      "Tallow Candle": 4,
      "Loaf of Bread": 5
    };

    // TODO: Need to discover skills for these items too.
    initialItems.forEach((type, amount) {
      hero.inventory.tryAdd(new Item(Items.types.find(type), amount));
    });

    heroClass.startingItems.spawnDrop(hero.inventory.tryAdd);

    return hero;
  }

  // TODO: Putting this right here in content is kind of lame. Is there a
  // better place for it?
  Action updateSubstance(Stage stage, Vec pos) {
    // TODO: More interactions:
    // fire:
    // - burns fuel (amount) and goes out when it hits zero
    // - if tile is not burning but is burnable and has nearby fire, random
    //   chance of catching fire
    // - burns actors (set on fire?)
    // - changes tiles -> table to ashes, etc.
    // water:
    // - diffuses
    //   - will put out fire
    // - tile has absorption rate that reduces amount each turn
    // - move actors?
    // - move items
    // - make tile non-walkable
    // poison:
    // - diffuses like gas
    // - disappates
    // - does not diffuse into fire or water
    // - poisons actors
    // cold:
    // - does not spread much, if at all
    // - slowly thaws
    // - freezes actors
    var tile = stage[pos];

    neighborElement(int x, int y, Element element) {
      var neighbor = stage.get(pos.x + x, pos.y + y);
      if (neighbor.substance == 0) return 0;
      return neighbor.element == element ? 1 : 0;
    }

    if (tile.substance == 0) {
      // TODO: Water first.

      // See if this tile catches fire.
      var ignition = Tiles.ignition(tile.type);
      if (ignition > 0) {
        // The more neighboring tiles on fire, the greater the chance of this
        // one catching fire.
        var fire = 0;
        fire += neighborElement(-1, 0, Elements.fire) * 3;
        fire += neighborElement(1, 0, Elements.fire) * 3;
        fire += neighborElement(0, -1, Elements.fire) * 3;
        fire += neighborElement(0, 1, Elements.fire) * 3;
        fire += neighborElement(-1, -1, Elements.fire) * 2;
        fire += neighborElement(-1, 1, Elements.fire) * 2;
        fire += neighborElement(1, -1, Elements.fire) * 2;
        fire += neighborElement(1, 1, Elements.fire) * 2;

        // TODO: Subtract neighboring cold?

        if (fire > rng.range(50 + ignition)) {
          var fuel = Tiles.fuel(tile.type);
          tile.substance = rng.range(fuel ~/ 2, fuel);
          tile.element = Elements.fire;
          stage.floorEmanationChanged();
        }
      }
      // TODO: Poison.
      // TODO: Cold?
    } else {
      if (tile.element == Elements.fire) {
        // Consume fuel.
        tile.substance--;

        if (tile.substance == 0) {
          tile.type = rng.item(Tiles.burnResult(tile.type));
          stage.floorEmanationChanged();
        } else {
          return new BurningFloorAction(pos);
        }
      }

      // TODO: Poison.
      // TODO: Cold.
      // TODO: Water.
    }

    return null;
  }
}
