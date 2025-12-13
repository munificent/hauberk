import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../hero/ability.dart';
import '../hero/hero_class.dart';
import '../hero/hero_save.dart';
import '../hero/lore.dart';
import '../hero/race.dart';
import '../hero/skill.dart';
import '../items/affix.dart';
import '../items/item.dart';
import '../items/item_type.dart';
import '../items/recipe.dart';
import '../items/shop.dart';
import '../monster/breed.dart';
import '../stage/stage.dart';
import 'element.dart';

/// Defines the actual content for the game: the breeds, items, etc. that
/// define the play experience.
abstract class Content {
  // TODO: Temp. Figure out where dungeon generator lives.
  // TODO: Using a callback to set the hero position is kind of hokey.
  Iterable<String> buildStage(
    Lore lore,
    Stage stage,
    int depth,
    Function(Vec) placeHero,
  );

  AffixType? findAffix(String name);

  Breed? tryFindBreed(String name);

  ItemType? tryFindItem(String name);

  Skill findSkill(String name);

  Spell findSpell(String name);

  Iterable<Breed> get breeds;

  List<HeroClass> get classes;

  Iterable<Element> get elements;

  Iterable<ItemType> get items;

  Iterable<AffixType> get affixes;

  List<Race> get races;

  List<Skill> get skills;

  List<Spell> get spells;

  Map<String, Shop> get shops;

  List<Recipe> get recipes;

  HeroSave createHero(
    String name, {
    Race? race,
    HeroClass? heroClass,
    bool permadeath,
  });

  List<Item> startingItems(HeroSave hero);

  Action? updateSubstance(Stage stage, Vec pos);
}
