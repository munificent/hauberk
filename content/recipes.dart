/// Builder class for defining [Recipe]s.
class RecipeBuilder extends ContentBuilder {
  final Map<String, ItemType> _items;
  final List<Recipe> _recipes;

  RecipeBuilder(this._items)
  : _recipes = <Recipe>[];

  List<Recipe> build() {
    recipe({
      'Soothing Balm': 3
    }, 'Mending Salve');

    return _recipes;
  }

  void recipe(Map<String, int> ingredientNames, String result) {
    final ingredients = [];
    ingredientNames.forEach((name, amount) {
      final ingredient = _items[name];
      for (var i = 0; i < amount; i++) {
        ingredients.add(ingredient);
      }
    });

    _recipes.add(new Recipe(ingredients, _items[result]));
  }
}
