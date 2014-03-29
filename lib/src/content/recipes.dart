library dngn.content.recipes;

import '../engine.dart';
import 'builder.dart';
import 'items.dart';

/// Builder class for defining [Recipe]s.
class Recipes extends ContentBuilder {
  static final List<Recipe> all = [];

  void build() {
    recipe('Berry Pie', [
      'Handful of Berries',
      'Handful of Berries',
      'Handful of Berries'
    ]);

    recipe("Traveler's Ration", [
      'Edible Mushroom',
      'Handful of Berries',
      'Honeycomb',
      'Honeycomb',
      'Honeycomb'
    ]);

    recipe('Fur Cloak', [
      'Fox Pelt'
    ]);

    recipe('Fur Cloak', [
      'Fur Pelt',
      'Fur Pelt',
      'Fur Pelt'
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

    recipe('Scroll of Sidestepping', [
      'Insect Wing',
      'Black Feather',
      'Parchment'
    ]);

    recipe('Scroll of Phasing', [
      'Scroll of Sidestepping',
      'Scroll of Sidestepping',
      'Scroll of Sidestepping'
    ]);

    recipe('Scroll of Teleportation', [
      'Scroll of Phasing',
      'Scroll of Phasing',
      'Scroll of Phasing'
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

  void recipe(String result, List<String> ingredientNames) {
    final ingredients = ingredientNames.map((name) => Items.all[name]).toList();
    Recipes.all.add(new Recipe(ingredients, Items.all[result]));
  }
}
