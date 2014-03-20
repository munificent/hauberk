library content.recipes;

import '../engine.dart';
import 'builder.dart';
import 'items.dart';

/// Builder class for defining [Recipe]s.
class Recipes extends ContentBuilder {
  static final List<Recipe> all = [];

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
    final ingredients = ingredientNames.map((name) => Items.all[name]).toList();
    Recipes.all.add(new Recipe(ingredients, Items.all[result]));
  }
}
