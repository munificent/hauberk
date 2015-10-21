library hauberk.content.recipes;

import '../engine.dart';
import 'drops.dart';
import 'items.dart';

/// Static class containing all of the [Recipe]s.
class Recipes {
  static final List<Recipe> all = [];

  static void initialize() {
    healing();
    teleportation();
    armor();
  }
}

void healing() {
  recipe("Healing Poultice", [
    'Flower',
    'Soothing Balm'
  ]);

  recipe('Antidote', [
    'Soothing Balm',
    'Stinger'
  ]);

  recipe('Soothing Balm', [
    'Flower',
    'Flower',
    'Flower'
  ]);

  recipe('Mending Salve', [
    'Soothing Balm',
    'Soothing Balm',
    'Soothing Balm'
  ]);

  recipe('Healing Poultice', [
    'Mending Salve',
    'Mending Salve',
    'Mending Salve'
  ]);

  recipe('Potion of Amelioration', [
    'Healing Poultice',
    'Healing Poultice',
    'Healing Poultice'
  ]);

  recipe('Potion of Rejuvenation', [
    'Potion of Amelioration',
    'Potion of Amelioration',
    'Potion of Amelioration',
    'Potion of Amelioration'
  ]);
}

void teleportation() {
  recipe('Scroll of Sidestepping', [
    'Insect Wing',
    'Black Feather'
  ]);

  recipe('Scroll of Phasing', [
    'Scroll of Sidestepping',
    'Scroll of Sidestepping'
  ]);

  recipe('Scroll of Teleportation', [
    'Scroll of Phasing',
    'Scroll of Phasing'
  ]);

  recipe('Scroll of Disappearing', [
    'Scroll of Teleportation',
    'Scroll of Teleportation'
  ]);
}

void armor() {
  recipe('Fur Cloak', [
    'Fox Pelt'
  ]);

  recipe('Fur Cloak', [
    'Fur Pelt',
    'Fur Pelt',
    'Fur Pelt'
  ]);

  recipe('Fur-lined Robe', [
    'Robe',
    'Fur Pelt',
    'Fur Pelt'
  ]);

  recipe('Fur-lined Robe', [
    'Robe',
    'Fox Pelt'
  ]);
}

void recipe(drop, List<String> ingredientNames) {
  List<String> produces;
  var ingredients = ingredientNames.map((name) => Items.all[name]).toList();
  if (drop is String) {
    produces = ["Produces: $drop"];
    drop = parseDrop(drop);
  } else {
    produces = [
      "May create a random piece of equipment similar to",
      "the placed item. Add coins to improve the quality",
      "and chance of a successful forging."
    ];
  }
  Recipes.all.add(new Recipe(ingredients, drop, produces));
}