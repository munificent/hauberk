library hauberk.content.items;

import 'package:malison/malison.dart';

import '../engine.dart';
import 'utils.dart';

int _sortIndex = 0;

/// The current glyph. Any items defined will use this. Can be a string or
/// a character code.
var _glyph;

String _category;
String _equipSlot;

/// Static class containing all of the [ItemType]s.
class Items {
  static final Map<String, ItemType> all = {};

  static void initialize() {
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

    treasure();
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
}

void treasure() {
  // TODO: Use cent symbol?
  // TODO: Use in recipe.
  // TODO: Make stuff drop.
  category(r"$", "treasure/coin");
  item("Copper Coin", 1, brown);
  item("Bronze Coin", 15, darkGold);
  item("Silver Coin", 30, gray);
  item("Electrum Coin", 40, lightGold);
  item("Gold Coin", 60, gold);
  item("Platinum Coin", 80, lightGray);

  /*

  Gems:
  Amethyst[s] LightPurple $
  Sapphire[s] Blue $
  Emerald[s] Green $
  Ruby|Rubies Red $
  Diamond[s] White $
  Blue Diamond[s] LightBlue $

  Rocks:
  Turquoise Stone[s] Cyan $
  Onyx Stone[s] DarkGray $
  Malachite Stone[s] DarkCyan $
  Jade Stone[s] DarkGreen $
  Pearl[s] LightYellow $
  Opal[s] LightPurple $

   */
}

void pelts() {
  category("%");
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

  // Hammers.
  category("=", "equipment/weapon/hammer");
  weapon("Hammer", 27, brown, "bash[es]", 16);
  weapon("Mattock", 39, darkBrown, "bash[es]", 20);
  weapon("War Hammer", 45, lightGray, "bash[es]", 24);

  category("=", "equipment/weapon/mace");
  weapon("Morningstar", 24, gray, "bash[es]", 13);
  weapon("Mace", 33, darkGray, "bash[es]", 18);

  category("~", "equipment/weapon/whip");
  weapon("Whip", 4, lightBrown, "whip[s]", 5);
  weapon("Chain Whip", 15, darkGray, "whip[s]", 9);
  weapon("Flail", 27, darkGray, "whip[s]", 14);

  /*
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

