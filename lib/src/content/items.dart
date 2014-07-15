library hauberk.content.items;

import '../engine.dart';
import '../util.dart';
import 'builder.dart';
import 'affixes.dart';

/// Builder class for defining [ItemType]s.
class Items extends ContentBuilder {
  static final Map<String, ItemType> all = {};

  int _sortIndex = 0;

  /// The current glyph. Any items defined will use this. Can be a string or
  /// a character code.
  var _glyph;

  String _category;
  String _equipSlot;

  void build() {
    // From Angband:
    // !   A potion (or flask)    /   A pole-arm
    // ?   A scroll (or book)     |   An edged weapon
    // ,   Food                   \   A hafted weapon
    // -   A wand or rod          }   A sling, bow, or x-bow
    // _   A staff                {   A shot, arrow, or bolt
    // =   A ring                 (   Soft armour (cloak, robes, leather armor)
    // "   An amulet              [   Hard armour (metal armor)
    // $   Gold or gems           ]   Misc. armour (gloves, helm, boots)
    // ~   Pelts and body parts   )   A shield
    // &   Chests, Containers

    // Unused: ; : ` % ^ < >

    foods();
    pelts();
    potions();
    scrolls();
    weapons();
    bodyArmor();
    boots();

    /*

    Pair[s] of Leather Gloves
    Set[s] of Bracers
    Pair[s] of Gauntlets

    Leather Cap[s]
    Chainmail Coif[s]
    Steel Cap[s]
    Visored Helm[s]
    Great Helm[s]

    Small Leather Shield[s]
    Wooden Targe[s]
    Large Leather Shield[s]
    Steel Buckler[s]
    Kite Shield[s]

     */
  }

  void foods() {
    category(CharCode.BLACK_HEART_SUIT, "food");
    food("Edible Mushroom",      1, lightGray,  20);
    food("Handful of Berries",   2, red,        30);
    food("Honeycomb",            3, gold,       40);
    food("Loaf of Bread",        4, lightBrown, 80);
    food("Berry Pie",            5, red,        100);
    food("Leg of Lamb",          6, darkBrown,  200);
    food("Traveler's Ration",    7, green,      300);
    // TODO: Magic foods that also cure/heal.
  }

  void pelts() {
    category("~");
    item("Flower",        1, lightAqua); // TODO: Use in recipe.
    item("Fur Pelt",      1, lightBrown);
    item("Insect Wing",   1, purple);
    item("Fox Pelt",      2, orange);
    item("Red Feather",   2, red); // TODO: Use in recipe.
    item("Black Feather", 2, darkGray);
    item("Stinger",       2, gold);
  }

  void potions() {
    // Healing.
    category("!", "magic/potion/healing");
    item("Soothing Balm", 1, lightRed,
        use: () => new HealAction(24));
    item("Mending Salve", 4, red,
        use: () => new HealAction(48));
    item("Healing Poultice", 12, darkRed,
        use: () => new HealAction(64, curePoison: true));
    item("Potion of Amelioration", 24, darkPurple,
        use: () => new HealAction(120, curePoison: true));
    item("Potion of Rejuvenation", 65, purple,
        use: () => new HealAction(1000, curePoison: true));

    item("Antidote", 5, green,
        use: () => new HealAction(0, curePoison: true));

    // Speed.
    category("!", "magic/potion/speed");
    item("Potion of Quickness", 3, lightGreen,
        use: () => new HasteAction(20, 1));
    item("Potion of Alacrity", 18, green,
        use: () => new HasteAction(30, 2));
    item("Potion of Speed", 34, darkGreen,
        use: () => new HasteAction(40, 3));

    // dram, draught, elixir, philter
  }

  void scrolls() {
    // Teleportation.
    category("?", "magic/scroll/teleportation");
    item("Scroll of Sidestepping", 3, lightPurple,
        use: () => new TeleportAction(6));
    item("Scroll of Phasing", 8, purple,
        use: () => new TeleportAction(12));
    item("Scroll of Teleportation", 15, darkPurple,
        use: () => new TeleportAction(24));
    item("Scroll of Disappearing", 26, darkBlue,
        use: () => new TeleportAction(48));

    // Detection.
    category("?", "magic/scroll/detection");
    item("Scroll of Item Detection", 2, lightOrange,
        use: () => new DetectItemsAction());

  }

  void weapons() {
    // Bludgeons.
    category(r"\", "equipment/weapon/club");
    weapon("Stick", 1, brown, "hit[s]", 4);
    weapon("Cudgel", 3, gray, "hit[s]", 5);
    weapon("Club", 6, lightBrown, "hit[s]", 6);

    // Staves.
    category("_", "equipment/weapon/staff");
    weapon("Walking Stick", 2, darkBrown, "hit[s]", 5);
    weapon("Staff", 5, lightBrown, "hit[s]", 7);
    weapon("Quarterstaff", 11, brown, "hit[s]", 12);

    /*
    Hammer[s]
    Mattock[s]

    Morningstar[s]
    Mace[s]
    War Hammer[s]

    // One-handed swords
    Rapier[s]
    Shortsword[s]
    Scimitar[s]
    Cutlass[es]
    Falchion[s]

    // Two-handed swords
    Bastard Sword[s]
    Longsword[s]
    Broadsword[s]
    Claymore[s]
    Flamberge[s]

    Whip[s]
    Chain Whip[s]
    Flail[s]

    */

    // Knives.
    category("|", "equipment/weapon/dagger");
    weapon("Knife", 1, gray, "stab[s]", 5);
    weapon("Dirk", 3, lightGray, "stab[s]", 6);
    weapon("Dagger", 6, white, "stab[s]", 8);
    weapon("Stiletto", 10, darkGray, "stab[s]", 11);
    weapon("Rondel", 20, lightAqua, "stab[s]", 14);
    weapon("Baselard", 30, lightBlue, "stab[s]", 16);
    // Main-guache
    // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

    // Spears.
    category(r"\", "equipment/weapon/spear");
    weapon("Pointed Stick", 2, brown, "stab[s]", 7);
    weapon("Spear", 7, gray, "stab[s]", 12);
    weapon("Angon", 14, lightGray, "stab[s]", 16);
    weapon("Lance", 28, white, "stab[s]", 24);
    weapon("Partisan", 35, darkGray, "stab[s]", 36);

    // glaive, voulge, halberd, pole-axe, lucerne hammer,

    /*
    Hatchet[s]
    Axe[s]
    Valaska[s]
    Battleaxe[s]
    */

    // Bows.
    category("}", "equipment/weapon/bow");
    bow("Short Bow", 3, brown, "the arrow", damage: 3, range: 10);
    bow("Longbow", 13, lightBrown, "the arrow", damage: 5, range: 12);
    bow("Crossbow", 28, gray, "the bolt", damage: 8, range: 14);
  }

  void bodyArmor() {
    category("(", "equipment/armor/cloak", "cloak");
    armor("Cloak", 4, darkBlue, 2);
    armor("Fur Cloak", 9, lightBrown, 3);

    category("(", "equipment/armor/body", "body");
    armor("Cloth Shirt", 2, lightGray, 2);
    armor("Leather Shirt", 5, lightBrown, 5);
    armor("Jerkin", 7, orange, 6);
    armor("Leather Armor", 13, brown, 8);
    armor("Padded Armor", 17, darkBrown, 11);
    armor("Studded Leather Armor", 21, gray, 15);
    armor("Mail Hauberk", 26, darkGray, 18);
    armor("Scale Mail", 30, lightGray, 21);

    category("(", "equipment/armor/body/robe", "body");
    armor("Robe", 2, aqua, 4);
    armor("Fur-lined Robe", 9, darkAqua, 6);

    /*
    Metal Lamellar Armor[s]
    Chain Mail Armor[s]
    Metal Scale Mail[s]
    Plated Mail[s]
    Brigandine[s]
    Steel Breastplate[s]
    Partial Plate Armor[s]
    Full Plate Armor[s]
    */
  }

  void boots() {
    category("]", "equipment/armor/boots", "boots");
    armor("Leather Sandals", 2, lightBrown, 1);
    armor("Leather Shoes", 8, brown, 2);
    armor("Leather Boots", 14, darkBrown, 4);
    armor("Metal Shod Boots", 22, gray, 7);
    armor("Greaves", 47, lightGray, 12);
  }

  category(glyph, [String category, String equipSlot]) {
    _glyph = glyph;
    if (category == null) {
      _category = null;
    } else {
    _category = "item/$category";
    }

    _equipSlot = equipSlot;
  }

  void food(String name, int level, appearance, int amount) {
    item(name, level, appearance, use: () => new EatAction(amount));
  }

  void weapon(String name, int level, appearance, String verb, int damage) {
    item(name, level, appearance, equipSlot: "weapon",
        attack: attack(verb, damage, Element.NONE));
  }

  void bow(String name, int level, appearance, String noun, {int damage,
      int range}) {
    item(name, level, appearance, equipSlot: "weapon",
        attack: attack("pierce[s]", damage, Element.NONE, new Noun(noun),
            range));
  }

  void armor(String name, int level, appearance, int armor) {
    item(name, level, appearance, armor: armor);
  }

  void item(String name, int level, appearance, {String equipSlot, ItemUse use,
      Attack attack, int armor: 0}) {
    // If the appearance isn"t an actual glyph, it should be a color function
    // that will be applied to the current glyph.
    if (appearance is! Glyph) {
      appearance = appearance(_glyph);
    }

    var categories = [];
    if (_category != null) categories = _category.split("/");

    if (equipSlot == null) equipSlot = _equipSlot;

    Items.all[name] = new ItemType(name, appearance, level, _sortIndex++,
        categories, equipSlot, use, attack, armor);
  }
}

/// Drops an item of a given type.
class ItemDrop implements Drop {
  final ItemType _type;

  ItemDrop(this._type);

  void spawnDrop(Game game, AddItem addItem) {
    addItem(Affixes.createItem(_type));
  }
}

/// Chooses zero or more [Drop]s from a list of possible options where each has
/// its own independent chance of being dropped.
class AllOfDrop implements Drop {
  final List<Drop> drops;
  final List<int> percents;

  AllOfDrop(this.drops, this.percents);

  void spawnDrop(Game game, AddItem addItem) {
    var roll = rng.range(100);

    for (var i = 0; i < drops.length; i++) {
      if (rng.range(100) < percents[i]) {
        drops[i].spawnDrop(game, addItem);
      }
    }
  }
}

/// Chooses a single [Drop] from a list of possible options with a percentage
/// chance for each. If the odds don"t add up to 100%, no item may be dropped.
class OneOfDrop implements Drop {
  final List<Drop> drops;
  final List<int> percents;

  OneOfDrop(this.drops, this.percents);

  void spawnDrop(Game game, AddItem addItem) {
    var roll = rng.range(100);

    for (var i = 0; i < drops.length; i++) {
      roll -= percents[i];
      if (roll <= 0) {
        drops[i].spawnDrop(game, addItem);
        return;
      }
    }
  }
}

/// Drops a randomly selected item near a level from a category.
class CategoryDrop implements Drop {
  /// The path to the category to choose from.
  final List<String> _category;

  /// The average level of the drop.
  final int _level;

  CategoryDrop(this._category, this._level);

  void spawnDrop(Game game, AddItem addItem) {
    // Possibly choose from the parent category.
    var categoryDepth = _category.length - 1;
    if (categoryDepth > 1 && rng.oneIn(10)) categoryDepth--;

    // Chance of out-of-depth items.
    var level = _level;
    if (rng.oneIn(1000)) {
      level += rng.range(20, 100);
    } else if (rng.oneIn(100)) {
      level += rng.range(5, 20);
    } else if (rng.oneIn(10)) {
      level += rng.range(1, 5);
    }

    // Find all of the items at or below the max level and in the category.
    var category = _category[categoryDepth];
    var items = Items.all.values
        .where((item) => item.level <= level &&
                         item.categories.contains(category)).toList();

    if (items.isEmpty) return;

    // TODO: Item rarity?

    // Pick an item. Try a few times and take the best.
    var itemType = rng.item(items);
    for (var i = 0; i < 3; i++) {
      var thisType = rng.item(items);
      if (thisType.level > itemType.level) itemType = thisType;
    }

    // Compare the item's actual level to the original desired level. If the
    // item is below that level, it increases the chances of an affix. (A weaker
    // item deeper in the dungeon is more likely to be magic.) Likewise, an
    // already-out-of-depth item is less likely to also be special.
    var levelOffset = itemType.level - _level;

    addItem(Affixes.createItem(itemType, levelOffset));
  }
}