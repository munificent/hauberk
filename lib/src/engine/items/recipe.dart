import 'item.dart';

/// A recipe defines a set of items that can be placed into the crucible and
/// transmuted into something new.
class Recipe {
  final List<ItemType> ingredients;
  final Drop result;

  // TODO: Instead of hard-coding the word wrapping here, wrap it in the UI.
  /// If this recipe results in a specific item, [produces] will store that
  /// item's name. Otherwise, [produces] will be null.
  final List<String> produces;

  Recipe(this.ingredients, this.result, this.produces);

  /// Returns `true` if [items] are valid (but not necessarily complete)
  /// ingredients for this recipe.
  bool allows(Iterable<Item> items) => getMissingIngredients(items) != null;

  /// Returns `true` if [items] are the complete ingredients needed for this
  /// recipe.
  bool isComplete(Iterable<Item> items) {
    var missing = getMissingIngredients(items);
    return missing != null && missing.length == 0;
  }

  /// Gets the remaining ingredients needed to complete this recipe given
  /// [items] ingredients. Returns `null` if [items] contains invalid
  /// ingredients.
  List<ItemType> getMissingIngredients(Iterable<Item> items) {
    var missing = ingredients.toSet();
    missing.removeAll(items);
    return missing.toList();
  }
}
