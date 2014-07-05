library dngn.content.items;

import '../engine.dart';
import '../util.dart';
import 'builder.dart';
import 'item_group.dart';
import 'powers.dart';

/// Builder class for defining [ItemType]s.
class Items extends ContentBuilder {
  static final Map<String, ItemType> all = {};

  int _sortIndex = 0;

  /// The current glyph. Any items defined will use this. Can be a string or
  /// a character code.
  var _glyph;

  String _group;

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
    group(CharCode.BLACK_HEART_SUIT, "food");
    food("Edible Mushroom",      1, lightGray,  20);
    food("Handful of Berries",   1, red,        30);
    food("Honeycomb",            3, gold,       40);
    food("Loaf of Bread",        4, lightBrown, 80);
    food("Berry Pie",            5, red,        100);
    food("Leg of Lamb",          6, darkBrown,  200);
    food("Traveler's Ration",    7, green,      300);
    // TODO: Magic foods that also cure/heal.
  }

  void pelts() {
    group("~");
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
    group("!", "magic/potion/healing");
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
    group("!", "magic/potion/speed");
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
    group("?", "magic/scroll/teleportation");
    item("Scroll of Sidestepping", 3, lightPurple,
        use: () => new TeleportAction(6));
    item("Scroll of Phasing", 8, purple,
        use: () => new TeleportAction(12));
    item("Scroll of Teleportation", 15, darkPurple,
        use: () => new TeleportAction(24));
    item("Scroll of Disappearing", 26, darkBlue,
        use: () => new TeleportAction(48));

    // Detection.
    group("?", "magic/scroll/detection");
    item("Scroll of Item Detection", 2, lightOrange,
        use: () => new DetectItemsAction());

  }

  void weapons() {
    // Bludgeons.
    group(r"\", "equipment/weapon/club");
    weapon("Stick", 1, brown, "hit[s]", 4);
    weapon("Cudgel", 3, gray, "hit[s]", 5);
    weapon("Club", 6, lightBrown, "hit[s]", 6);

    // Staves.
    group("_", "equipment/weapon/staff");
    weapon("Walking Stick", 3, darkBrown, "hit[s]", 5);
    weapon("Staff", 11, lightBrown, "hit[s]", 7);
    weapon("Quarterstaff", 15, brown, "hit[s]", 12);

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
    group("|", "equipment/weapon/dagger");
    weapon("Knife", 3, gray, "stab[s]", 5);
    weapon("Dirk", 6, lightGray, "stab[s]", 6);
    weapon("Dagger", 10, white, "stab[s]", 8);
    weapon("Stiletto", 16, darkGray, "stab[s]", 11);
    weapon("Rondel", 20, lightAqua, "stab[s]", 14);
    weapon("Baselard", 40, lightBlue, "stab[s]", 16);
    // Main-guache
    // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

    // Spears.
    group(r"\", "equipment/weapon/spear");
    weapon("Pointed Stick", 5, brown, "stab[s]", 7);
    weapon("Spear", 25, gray, "stab[s]", 12);
    weapon("Angon", 35, lightGray, "stab[s]", 16);
    weapon("Lance", 45, white, "stab[s]", 24);
    weapon("Partisan", 55, darkGray, "stab[s]", 36);

    // glaive, voulge, halberd, pole-axe, lucerne hammer,

    /*
    Hatchet[s]
    Axe[s]
    Valaska[s]
    Battleaxe[s]
    */

    // Bows.
    group("}", "equipment/weapon/bow");
    bow("Short Bow", 7, brown, "the arrow", 4);
    bow("Longbow", 13, lightBrown, "the arrow", 6);
    bow("Crossbow", 28, gray, "the bolt", 10);
  }

  void bodyArmor() {
    group("(", "equipment/armor/cloak");
    armor("Cloak", 4, darkBlue, 2);
    armor("Fur Cloak", 9, lightBrown, 3);

    group("(", "equipment/armor/body");
    armor("Cloth Shirt", 2, lightGray, 2);
    armor("Leather Shirt", 5, lightBrown, 5);
    armor("Leather Armor", 13, brown, 8);
    armor("Padded Armor", 17, darkBrown, 11);
    armor("Studded Leather Armor", 21, gray, 15);

    group("(", "equipment/armor/robe");
    armor("Robe", 4, aqua, 4, equipSlot: "body");
    armor("Fur-lined Robe", 9, darkAqua, 6, equipSlot: "body");

    /*
    Jerkin
    Soft Leather Armor[s]
    Hard Leather Armor[s]
    Leather Scale Mail[s]
    Mail Hauberk[s]
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
    group("]", "equipment/armor/boots");
    armor("Leather Sandals", 3, lightBrown, 1);
    armor("Leather Shoes", 8, brown, 2);
    armor("Leather Boots", 14, darkBrown, 4);
    armor("Metal Shod Boots", 22, gray, 7);
    armor("Greaves", 47, lightGray, 12);
  }

  group(glyph, [String group]) {
    _glyph = glyph;
    _group = group;
  }

  food(String name, int level, appearance, int amount) {
    return item(name, level, appearance, use: () => new EatAction(amount));
  }

  ItemType weapon(String name, int level, appearance, String verb, int damage) {
    var category = _group.split("/").last;
    return item(name, level, appearance, equipSlot: "weapon",
        category: category, attack: attack(verb, damage, Element.NONE));
  }

  ItemType bow(String name, int level, appearance, String noun, int damage) {
    return item(name, level, appearance, equipSlot: "bow", category: "bow",
        attack: attack("pierce[s]", damage, Element.NONE, new Noun(noun)));
  }

  ItemType armor(String name, int level, appearance, int armor,
        {String equipSlot}) {
    if (equipSlot == null) equipSlot = _group.split("/").last;
    return item(name, level, appearance, equipSlot: equipSlot, armor: armor);
  }

  ItemType item(String name, int level, appearance, {ItemUse use,
      String equipSlot, String category, Attack attack, int armor: 0}) {
    // If the appearance isn"t an actual glyph, it should be a color function
    // that will be applied to the current glyph.
    if (appearance is! Glyph) {
      appearance = appearance(_glyph);
    }

    var itemType = new ItemType(name, appearance, _sortIndex++, use,
        equipSlot, category, attack, armor);
    Items.all[name] = itemType;

    if (_group != null) {
      ItemGroup.define(_group, itemType, level);
    }

    return itemType;
  }
}

/// Drops an item of a given type.
class ItemDrop implements Drop {
  final ItemType _type;

  ItemDrop(this._type);

  void spawnDrop(Game game, AddItem addItem) {
    addItem(Powers.createItem(_type));
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

/// Drops an item whose probability is based on the hero's level in some skill.
class SkillDrop implements Drop {
  final Skill skill;
  final Drop drop;

  SkillDrop(this.skill, this.drop);

  void spawnDrop(Game game, AddItem addItem) {
    if (rng.range(100) < skill.getDropChance(game.hero.skills[skill])) {
      drop.spawnDrop(game, addItem);
    }
  }
}
