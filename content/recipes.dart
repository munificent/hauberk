library content.recipes;

import '../engine.dart';
import 'builder.dart';
import 'items.dart';

final List<Recipe> recipes = [];

/// Builder class for defining [Recipe]s.
class RecipeBuilder extends ContentBuilder {
  void build() {
    recipe('Fur Cloak', [
      'Fur pelt',
      'Fur pelt',
      'Fur pelt',
      'Fur pelt'
    ]);

    recipe('Mending Salve', [
      'Soothing Balm',
      'Soothing Balm',
      'Soothing Balm'
    ]);

    recipe('Scroll of Sidestepping', [
      'Insect wing',
      'Black feather',
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
      'Fur pelt',
      'Fur pelt'
    ]);
  }

  void recipe(String result, List<String> ingredientNames) {
    final ingredients = ingredientNames.map((name) => items[name]).toList();
    recipes.add(new Recipe(ingredients, items[result]));
  }
}
