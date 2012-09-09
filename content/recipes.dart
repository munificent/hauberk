/// Builder class for defining [Recipe]s.
class RecipeBuilder extends ContentBuilder {
  final Map<String, ItemType> _items;
  final List<Recipe> _recipes;

  RecipeBuilder(this._items)
  : _recipes = <Recipe>[];

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

    return _recipes;
  }

  void recipe(String result, List<String> ingredientNames) {
    final ingredients = ingredientNames.map((name) => _items[name]);
    _recipes.add(new Recipe(ingredients, _items[result]));
  }
}
