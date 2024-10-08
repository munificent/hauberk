import 'item.dart';
import 'item_type.dart';

/// A recipe defines a set of items that can be placed into the crucible and
/// transmuted into something new.
class Recipe {
  /// Maps each required item type to the count of items of that type that are
  /// needed.
  final Map<ItemType, int> ingredients;

  // TODO: Eventually we'll want something more sophisticated than just a [Drop]
  // since some recipes will modify one of the ingredient items.
  final Drop result;

  /// User-facing description of what this recipe does.
  final String produces;

  Recipe(this.ingredients, this.result, this.produces);

  /// Returns `true` if [items] are valid (but not necessarily complete)
  /// ingredients for this recipe.
  bool allows(Iterable<Item> items) => _missingIngredients(items) != null;

  /// Returns `true` if [items] are the complete ingredients needed for this
  /// recipe.
  bool isComplete(Iterable<Item> items) {
    var missing = _missingIngredients(items);
    return missing != null && missing.isEmpty;
  }

  /// Gets the remaining ingredients needed to complete this recipe given
  /// [items] ingredients. Returns `null` if [items] contains any ingredients
  /// that are not used by this recipe.
  Map<ItemType, int>? _missingIngredients(Iterable<Item> items) {
    var missing = {...ingredients};
    for (var item in items) {
      if (!missing.containsKey(item.type)) return null;
      missing[item.type] = missing[item.type]! - item.count;
    }

    // Remove the ingredients that are complete.
    for (var ingredient in missing.keys.toList()) {
      if (missing[ingredient]! <= 0) missing.remove(ingredient);
    }

    return missing;
  }
}
