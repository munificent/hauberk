import '../engine.dart';
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
  recipe("Healing Poultice", {
    'Flower': 1,
    'Soothing Balm': 1
  });

  recipe('Antidote', {
    'Soothing Balm': 1,
    'Stinger': 1
  });

  recipe('Soothing Balm', {
    'Flower': 3
  });

  recipe('Mending Salve', {
    'Soothing Balm': 3
  });

  recipe('Healing Poultice', {
    'Mending Salve': 3
  });

  recipe('Potion of Amelioration', {
    'Healing Poultice': 3
  });

  recipe('Potion of Rejuvenation', {
    'Potion of Amelioration': 4
  });
}

void teleportation() {
  recipe('Scroll of Sidestepping', {
    'Insect Wing': 1,
    'Black Feather': 1
  });

  recipe('Scroll of Phasing', {
    'Scroll of Sidestepping': 2
  });

  recipe('Scroll of Teleportation', {
    'Scroll of Phasing': 2
  });

  recipe('Scroll of Disappearing', {
    'Scroll of Teleportation': 2
  });
}

void armor() {
  recipe('Fur Cloak', {
    'Fox Pelt': 1
  });

  recipe('Fur Cloak', {
    'Fur Pelt': 1
  });

  recipe('Fur-lined Robe', {
    'Robe': 1,
    'Fur Pelt': 2
  });

  recipe('Fur-lined Robe', {
    'Robe': 1,
    'Fox Pelt': 1
  });
}

void recipe(drop, Map<String, int> ingredientNames) {
  List<String> produces;

  var ingredients = <ItemType, int>{};
  for (var name in ingredientNames.keys) {
    ingredients[Items.types.find(name)] = ingredientNames[name];
  }

  if (drop is String) {
    produces = ["Produces: $drop"];
    drop = parseDrop(drop, 1);
  } else {
    // TODO: This isn't right anymore.
    produces = [
      "May create a random piece of equipment similar to",
      "the placed item. Add coins to improve the quality",
      "and chance of a successful forging."
    ];
  }
  Recipes.all.add(new Recipe(ingredients, drop, produces));
}