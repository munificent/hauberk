/// Builder class for defining [Recipe]s.
class RecipeBuilder extends ContentBuilder {
  final Map<String, ItemType> _items;
  final List<Recipe> _recipes;

  RecipeBuilder(this._items)
  : _recipes = <Recipe>[];

  List<Recipe> build() {
    recipe([
      'Soothing Balm',
      'Soothing Balm',
      'Soothing Balm'
    ], 'Mending Salve');

    recipe([
      'Insect wing',
      'Black feather',
      'Parchment'
    ], 'Scroll of Sidestepping');

    return _recipes;
  }

  void recipe(List<String> ingredientNames, String result) {
    final ingredients = ingredientNames.map((name) => _items[name]);
    _recipes.add(new Recipe(ingredients, _items[result]));
  }
}
