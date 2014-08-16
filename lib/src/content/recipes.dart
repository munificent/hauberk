library hauberk.content.recipes;

import 'dart:math' as math;

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
    coins();
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

void coins() {
  var coins = [
    'Copper', 'Bronze', 'Silver', 'Electrum', 'Gold', 'Platinum'
  ];

  // For each item in an equipment category, make recipes to reroll a similar
  // item.
  for (var item in Items.all.values) {
    if (item.categories.length < 2) continue;
    if (item.categories[1] != "equipment") continue;

    equipmentRecipe(ItemType item, int chance, int levelBoost,
        List<String> coins) {
      var level = math.min(100, item.level + levelBoost);
      recipe(percent(chance, item.category, level),
          [item.name]..addAll(coins));
    }

    // Better coins increase the level of the rerolled item. More coins
    // increase the odds of a drop.
    equipmentRecipe(item, 50, 0, []);
    for (var i = 0; i < coins.length; i++) {
      var coin = '${coins[i]} Coin';
      var boost = 5 + i * 10;
      equipmentRecipe(item, 70, boost, [coin]);
      equipmentRecipe(item, 80, boost, [coin, coin]);
      equipmentRecipe(item, 90, boost, [coin, coin, coin]);
      equipmentRecipe(item, 100, boost, [coin, coin, coin, coin]);
    }
  }

  // Recipes to upgrade coins.
  for (var i = 0; i < coins.length - 1; i++) {
    var coin = "${coins[i]} Coin";
    recipe("${coins[i + 1]} Coin", [coin, coin, coin]);
  }
}

void recipe(drop, List<String> ingredientNames) {
  String produces;
  var ingredients = ingredientNames.map((name) => Items.all[name]).toList();
  if (drop is String) {
    produces = drop;
    drop = parseDrop(drop);
  }
  Recipes.all.add(new Recipe(ingredients, drop, produces));
}