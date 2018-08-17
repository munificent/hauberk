import '../../engine.dart';
import 'drops.dart';

/// Static class containing all of the [Shop]s.
class Shops {
  static final Map<String, Shop> all = {};

  static void initialize() {
    shop("The General's General Store", {
      "Loaf of Bread": 1.0,
      "Tallow Candle": 1.0,
      "Wax Candle": 0.7,
      "Oil Lamp": 0.5,
      "Torch": 0.4,
      "Lantern": 0.1,
      "Soothing Balm": 0.8,
      "Mending Salve": 0.6,
      "Healing Poultice": 0.3,
      "Club": 0.3,
      "Staff": 0.2,
      "Quarterstaff": 0.1,
      "Whip": 0.2,
      "Dagger": 0.2,
      "Hatchet": 0.1,
      "Axe": 0.05
    });

    // TODO: Update based on new items. Update frequencies.
    shop("Dirk's Death Emporium", {
      "Hammer": 1.0,
      "Mattock": 1.0,
      "War Hammer": 1.0,
      "Morningstar": 1.0,
      "Mace": 1.0,
      "Chain Whip": 1.0,
      "Flail": 1.0,
      "Falchion": 1.0,
      "Rapier": 1.0,
      "Shortsword": 1.0,
      "Scimitar": 1.0,
      "Cutlass": 1.0,
      "Spear": 1.0,
      "Angon": 1.0,
      "Lance": 1.0,
      "Partisan": 1.0,
      "Valaska": 1.0,
      "Battleaxe": 1.0,
      "Short Bow": 1.0,
      "Longbow": 1.0,
      "Crossbow": 1.0
    });

    shop("Skullduggery and Bamboozelry", {
      "Dirk": 1.0,
      "Dagger": 1.0,
      "Stiletto": 1.0,
      "Rondel": 1.0,
      "Baselard": 1.0
    });

    shop("Garthag's Armoury", {
      "Cloak": 1.0,
      "Fur Cloak": 1.0,
      "Cloth Shirt": 1.0,
      "Leather Shirt": 1.0,
      "Jerkin": 1.0,
      "Leather Armor": 1.0,
      "Padded Armor": 1.0,
      "Studded Armor": 1.0,
      "Mail Hauberk": 1.0,
      "Scale Mail": 1.0,
      "Robe": 1.0,
      "Fur-lined Robe": 1.0,
      "Pair of Sandals": 1.0,
      "Pair of Shoes": 1.0,
      "Pair of Boots": 1.0,
      "Pair of Plated Boots": 1.0,
      "Pair of Greaves": 1.0
    });

    shop("Unguence the Alchemist", {
      "Soothing Balm": 1.0,
      "Mending Salve": 1.0,
      "Healing Poultice": 1.0,
      "Antidote": 1.0,
      "Potion of Quickness": 1.0,
      "Potion of Alacrity": 1.0,
      "Bottled Wind": 1.0,
      "Bottled Ice": 1.0,
      "Bottled Fire": 1.0,
      "Bottled Ocean": 1.0,
      "Bottled Earth": 1.0,
    });

    shop("The Droll Magery", {
      "Spellbook \"Elemental Primer\"": 1.0,
      "Scroll of Sidestepping": 1.0,
      "Scroll of Phasing": 1.0,
      "Scroll of Item Detection": 1.0,
    });
  }

/*
  Glur's Rare Artifacts
  */
}

void shop(String name, Map<String, double> itemTypes) {
  var drops = <Drop, double>{};
  itemTypes.forEach((name, frequency) {
    drops[parseDrop(name, 1)] = frequency;
  });

  Shops.all[name] = Shop(name, dropOneOf(drops));
}
