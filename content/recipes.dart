part of content;

/// Builder class for defining [Recipe]s.
class RecipeBuilder extends ContentBuilder {
  List<Recipe> build() {
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

    recipe('Fur-lined Robe', [
      'Robe',
      'Fur pelt',
      'Fur pelt'
    ]);
  }

  void recipe(String result, List<String> ingredientNames) {
    final ingredients = ingredientNames.map((name) => _items[name]).toList();
    _recipes.add(new Recipe(ingredients, _items[result]));
  }
}
