import '../../engine.dart';
import 'drops.dart';
import 'items.dart';

/// Static class containing all of the [Recipe]s.
class Recipes {
  static final List<Recipe> all = [];

  static void initialize() {
    healing();
    teleportation();
    armor();
  }
}

void healing() {
  // TODO: Bring these back when the ingredients exist and are dropped.
  // recipe("Healing Poultice", {'Flower': 1, 'Soothing Balm': 1});
  // recipe('Soothing Balm', {'Flower': 3});
  recipe('Mending Salve', {'Soothing Balm': 3});
  recipe('Healing Poultice', {'Mending Salve': 3});
  recipe('Potion of Amelioration', {'Healing Poultice': 3});
  recipe('Potion of Rejuvenation', {'Potion of Amelioration': 4});
}

void teleportation() {
  recipe('Scroll of Sidestepping', {'Insect Wing': 1, 'Feather': 1});
  recipe('Scroll of Phasing', {'Scroll of Sidestepping': 2});
  recipe('Scroll of Teleportation', {'Scroll of Phasing': 2});
  recipe('Scroll of Disappearing', {'Scroll of Teleportation': 2});
}

void armor() {
  // TODO: Bring these back when the ingredients exist and are dropped.
  // recipe('Fur Cloak', {'Fox Pelt': 1});
  // recipe('Fur Cloak', {'Fur Pelt': 1});
  // recipe('Fur-lined Robe', {'Robe': 1, 'Fur Pelt': 2});
  // recipe('Fur-lined Robe', {'Robe': 1, 'Fox Pelt': 1});
}

void recipe(String drop, Map<String, int> ingredientNames) {
  var ingredients = <ItemType, int>{
    for (var MapEntry(key: name, value: ingredient) in ingredientNames.entries)
      Items.types.find(name): ingredient
  };

  // TODO: Allow more interesting descriptions when we have recipes that do
  // things like modify one of the ingredients.
  var produces = drop;
  Recipes.all.add(Recipe(ingredients, parseDrop(drop, depth: 1), produces));
}
