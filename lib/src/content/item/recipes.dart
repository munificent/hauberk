import '../../engine.dart';
import 'drops.dart';
import 'items.dart';

/// Static class containing all of the [Recipe]s.
class Recipes {
  static final List<Recipe> all = [];

  static void initialize() {
    gems();
    healing();
    teleportation();
    armor();
  }
}

void gems() {
  recipe("Uncut Amethyst", {"Amethyst Shard": 4});
  recipe("Faceted Amethyst", {"Uncut Amethyst": 4});

  recipe("Uncut Sapphire", {"Sapphire Shard": 4});
  recipe("Faceted Sapphire", {"Uncut Sapphire": 4});

  recipe("Uncut Emerald", {"Emerald Shard": 4});
  recipe("Faceted Emerald", {"Uncut Emerald": 4});

  recipe("Uncut Ruby", {"Ruby Shard": 4});
  recipe("Faceted Ruby", {"Uncut Ruby": 4});

  recipe("Uncut Diamond", {"Diamond Shard": 4});
  recipe("Faceted Diamond", {"Uncut Diamond": 4});

  // TODO: Recipes to socket them into equipment.
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

/// Adds a new recipe.
void recipe(String drop, Map<String, int> ingredientNames) {
  var ingredients = <ItemType, int>{
    for (var MapEntry(key: name, value: ingredient) in ingredientNames.entries)
      Items.types.find(name): ingredient,
  };

  // TODO: Allow more interesting descriptions when we have recipes that do
  // things like modify one of the ingredients.
  var produces = drop;
  Recipes.all.add(Recipe(ingredients, parseDrop(drop, depth: 1), produces));
}
