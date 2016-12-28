import '../engine.dart';
import 'items.dart';

/// Static class containing all of the [Shop]s.
class Shops {
  static final List<Shop> all = [];

  static void initialize() {
    shop("The General's General Store", [
      "Club",
      "Staff",
      "Quarterstaff",
      "Whip",
      "Dagger",
      "Hatchet",
      "Axe",
      "Sling",
    ]);

    shop("Dirk's Death Emporium", [
      "Hammer",
      "Mattock",
      "War Hammer",
      "Morningstar",
      "Mace",
      "Chain Whip",
      "Flail",
      "Falchion",
      "Rapier",
      "Shortsword",
      "Scimitar",
      "Cutlass",
      "Spear",
      "Angon",
      "Lance",
      "Partisan",
      "Valaska",
      "Battleaxe",
      "Short Bow",
      "Longbow",
      "Crossbow"
    ]);

    shop("Skullduggery and Bamboozelry", [
      "Dirk",
      "Dagger",
      "Stiletto",
      "Rondel",
      "Baselard"
    ]);

    shop("Garthag's Armoury", [
      "Cloak",
      "Fur Cloak",
      "Cloth Shirt",
      "Leather Shirt",
      "Jerkin",
      "Leather Armor",
      "Padded Armor",
      "Studded Leather Armor",
      "Mail Hauberk",
      "Scale Mail",
      "Robe",
      "Fur-lined Robe",
      "Leather Sandals",
      "Leather Shoes",
      "Leather Boots",
      "Metal Shod Boots",
      "Greaves"
    ]);
  }

  /*
  Unguence the Alchemist
  The Droll Magery
  Glur's Rare Artifacts
  */
}

void shop(String name, List<String> itemTypes) {
  var items = itemTypes
      .map((typeName) => new Item(Items.types.find(typeName))).toList();
  Shops.all.add(new Shop(name, items));
}
