library hauberk.engine.items.recipe;

import 'package:piecemeal/piecemeal.dart';

import '../action/walk.dart';
import '../actor.dart';
import '../melee.dart';
import 'item.dart';

/// A recipe defines a set of items that can be placed into the crucible and
/// transmuted into something new.
// TODO: Figure out how this works with affixes.
class Recipe {
  final List<ItemType> ingredients;
  final Drop result;

  Recipe(this.ingredients, this.result);

  /// Returns `true` if [items] are valid (but not necessarily complete)
  /// ingredients for this recipe.
  bool allows(Iterable<Item> items) => getMissingIngredients(items) != null;

  /// Returns `true` if [items] are the complete ingredients needed for this
  /// recipe.
  bool isComplete(Iterable<Item> items) {
    final missing = getMissingIngredients(items);
    return missing != null && missing.length == 0;
  }

  /// Gets the remaining ingredients needed to complete this recipe given
  /// [items] ingredients. Returns `null` if [items] contains invalid
  /// ingredients.
  List<ItemType> getMissingIngredients(Iterable<Item> items) {
    final missing = new List.from(ingredients);

    for (final item in items) {
      final found = missing.indexOf(item.type);
      if (found == -1) return null;

      // Don't allow extra copies of ingredients.
      missing.removeAt(found);
    }

    return missing;
  }
}
