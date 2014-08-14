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
String _verb;
int _tossDamage;
int _tossRange;

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

    category(",", null);
    item("Rock", 1, lightBrown, tossAttack:
        new RangedAttack("the rock", "hits", 6, Element.EARTH, 8));

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
  category(r"$", "treasure/coin", tossDamage: 1, tossRange: 7);
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
  category("%", null);
  item("Flower",        1, lightAqua); // TODO: Use in recipe.
  item("Fur Pelt",      1, lightBrown);
  item("Insect Wing",   1, purple);
  item("Fox Pelt",      2, orange);
  item("Red Feather",   2, red); // TODO: Use in recipe.
  item("Black Feather", 2, darkGray);
  item("Stinger",       2, gold);
}

void potions() {
  // TODO: Make these foods?

  // TODO: Potions should shatter when thrown. Some should perform an effect.

  // Healing.
  category("!", "magic/potion/healing", tossDamage: 1, tossRange: 7);
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

  category("!", "magic/potion/resistance", tossDamage: 1, tossRange: 7);
  resistSalve(String name, int level, appearance, Element element) {
    item("Salve of $name Resistance", level, appearance,
        use: () => new ResistAction(40, element));
  }

  resistSalve("Heat", 5, orange, Element.FIRE);
  resistSalve("Cold", 6, lightBlue, Element.COLD);
  resistSalve("Light", 7, lightYellow, Element.LIGHT);
  resistSalve("Wind", 8, lightAqua, Element.AIR);
  resistSalve("Electricity", 9, lightPurple, Element.LIGHTNING);
  resistSalve("Darkness", 10, darkGray, Element.DARK);
  resistSalve("Earth", 13, brown, Element.EARTH);
  resistSalve("Water", 16, blue, Element.WATER);
  resistSalve("Acid", 19, lightOrange, Element.ACID);
  resistSalve("Poison", 23, green, Element.POISON);
  resistSalve("Death", 30, purple, Element.SPIRIT);

  // TODO: "Insulation", "the Elements" and other multi-element resistances.

  item("Antidote", 15, green,
      use: () => new HealAction(0, curePoison: true));

  // Speed.
  category("!", "magic/potion/speed", tossDamage: 1, tossRange: 7);
  item("Potion of Quickness", 3, lightGreen,
      use: () => new HasteAction(20, 1));
  item("Potion of Alacrity", 18, green,
      use: () => new HasteAction(30, 2));
  item("Potion of Speed", 34, darkGreen,
      use: () => new HasteAction(40, 3));

  // dram, draught, elixir, philter

  // TODO: Make monsters drop these.
  category("?", "magic/potion/bottled", tossDamage: 1, tossRange: 7);
  item("Bottled Wind", 2, white,
      use: () => new RingSelfAction(new RangedAttack("the wind", "blasts",
          8, Element.AIR, 6)));
  item("Bottled Ice", 5, lightBlue,
      use: () => new RingSelfAction(new RangedAttack("the ice", "freezes",
          15, Element.COLD, 7)));
  item("Bottled Fire", 8, red,
      use: () => new RingSelfAction(new RangedAttack("the fire", "burns",
          22, Element.FIRE, 8)));
  item("Bottled Lightning", 12, lightPurple,
      use: () => new RingSelfAction(new RangedAttack("the lightning", "shocks",
          34, Element.LIGHTNING, 9)));
  // TODO: Other elements, other intensities.

}

void scrolls() {
  // Teleportation.
  category("?", "magic/scroll/teleportation", tossDamage: 1, tossRange: 5);
  item("Scroll of Sidestepping", 3, lightPurple,
      use: () => new TeleportAction(6));
  item("Scroll of Phasing", 8, purple,
      use: () => new TeleportAction(12));
  item("Scroll of Teleportation", 15, darkPurple,
      use: () => new TeleportAction(24));
  item("Scroll of Disappearing", 26, darkBlue,
      use: () => new TeleportAction(48));

  // Detection.
  category("?", "magic/scroll/detection", tossDamage: 1, tossRange: 5);
  item("Scroll of Item Detection", 2, lightOrange,
      use: () => new DetectItemsAction());
}

void weapons() {
  // Bludgeons.
  category(r"\", "equipment/weapon/club", verb: "hit[s]");
  weapon("Stick",          1, brown,       4,  3, 7);
  weapon("Cudgel",         3, gray,        5,  4, 7);
  weapon("Club",           6, lightBrown,  6,  5, 7);

  // Staves.
  category("_", "equipment/weapon/staff", verb: "hit[s]");
  weapon("Walking Stick",  2, darkBrown,   5,  3, 6);
  weapon("Staff",          5, lightBrown,  7,  5, 6);
  weapon("Quarterstaff",  11, brown,      12,  8, 6);

  // Hammers.
  category("=", "equipment/weapon/hammer", verb: "bash[es]");
  weapon("Hammer",        27, brown,      16, 12, 5);
  weapon("Mattock",       39, darkBrown,  20, 16, 5);
  weapon("War Hammer",    45, lightGray,  24, 20, 5);

  category("=", "equipment/weapon/mace", verb: "bash[es]");
  weapon("Morningstar",   24, gray,       13, 11, 5);
  weapon("Mace",          33, darkGray,   18, 16, 5);

  category("~", "equipment/weapon/whip", verb: "whip[s]");
  weapon("Whip",           4, lightBrown,  5,  1, 5);
  weapon("Chain Whip",    15, darkGray,    9,  2, 5);
  weapon("Flail",         27, darkGray,   14,  4, 5);

  category("|", "equipment/weapon/sword", verb: "slash[es]");
  weapon("Rapier",         4, gray,        5,  4, 6);
  weapon("Shortsword",     9, darkGray,    8,  6, 6);
  weapon("Scimitar",      15, lightGray,  11,  9, 6);
  weapon("Cutlass",       21, lightGold,  15, 11, 6);
  weapon("Falchion",      34, white,      21, 15, 6);

  /*

  // Two-handed swords
  Bastard Sword[s]
  Longsword[s]
  Broadsword[s]
  Claymore[s]
  Flamberge[s]

  */

  // Knives.
  category("|", "equipment/weapon/dagger", verb: "stab[s]");
  weapon("Knife",          1, gray,        5,  5, 10);
  weapon("Dirk",           3, lightGray,   6,  6, 10);
  weapon("Dagger",         6, white,       8,  8, 10);
  weapon("Stiletto",      10, darkGray,   11, 11, 10);
  weapon("Rondel",        20, lightAqua,  14, 14, 10);
  weapon("Baselard",      30, lightBlue,  16, 16, 10);
  // Main-guache
  // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

  // Spears.
  category(r"\", "equipment/weapon/spear", verb: "stab[s]");
  weapon("Pointed Stick",  2, brown,       7,  9, 11);
  weapon("Spear",          7, gray,       12, 15, 11);
  weapon("Angon",         14, lightGray,  16, 20, 11);
  weapon("Lance",         28, white,      24, 28, 11);
  weapon("Partisan",      35, darkGray,   36, 40, 11);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(r"\", "equipment/weapon/axe", verb: "chop[s]");
  weapon("Hatchet",        6, darkGray,   10, 12, 10);
  weapon("Axe",           12, lightBrown, 16, 18, 9);
  weapon("Valaska",       20, gray,       26, 26, 8);
  weapon("Battleaxe",     30, lightBlue,  32, 32, 7);

  // Sling. In a category itself because many box affixes don't apply to it.
  category("}", "equipment/weapon/sling", verb: "hit[s]");
  ranged("Sling",          3, darkBrown,  "the stone",  3, 10, 1, 5);

  // Bows.
  category("}", "equipment/weapon/bow", verb: "hit[s]");
  ranged("Short Bow",      5, brown,      "the arrow",  5, 12, 2, 5);
  ranged("Longbow",       13, lightBrown, "the arrow",  8, 14, 3, 5);
  ranged("Crossbow",      28, gray,       "the bolt",  12, 16, 4, 5);
}

void bodyArmor() {
  // TODO: Make some armor throwable.

  category("(", "equipment/armor/cloak", equip: "cloak");
  armor("Cloak", 3, darkBlue, 2);
  armor("Fur Cloak", 9, lightBrown, 3);

  category("(", "equipment/armor/body", equip: "body");
  armor("Cloth Shirt", 2, lightGray, 2);
  armor("Leather Shirt", 5, lightBrown, 5);
  armor("Jerkin", 7, orange, 6);
  armor("Leather Armor", 10, brown, 8);
  armor("Padded Armor", 14, darkBrown, 11);
  armor("Studded Leather Armor", 17, gray, 15);
  armor("Mail Hauberk", 20, darkGray, 18);
  armor("Scale Mail", 23, lightGray, 21);

  category("(", "equipment/armor/body/robe", equip: "body");
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
  category("]", "equipment/armor/boots", equip: "boots");
  armor("Leather Sandals", 2, lightBrown, 1);
  armor("Leather Shoes", 8, brown, 2);
  armor("Leather Boots", 14, darkBrown, 4);
  armor("Metal Shod Boots", 22, gray, 7);
  armor("Greaves", 47, lightGray, 12);
}

void category(glyph, String category, {String equip, String verb,
    int tossDamage, int tossRange}) {
  _glyph = glyph;
  if (category == null) {
    _category = null;
  } else {
    _category = "item/$category";
  }

  _equipSlot = equip;
  _verb = verb;
  _tossDamage = tossDamage;
  _tossRange = tossRange;
}

void weapon(String name, int level, appearance, int damage, int tossDamage,
      int tossRange) {
  var toss = new RangedAttack("the ${name.toLowerCase()}",
      Log.makeVerbsAgree(_verb, Pronoun.IT), tossDamage, Element.NONE,
      tossRange);
  item(name, level, appearance, equipSlot: "weapon",
      attack: attack(_verb, damage, Element.NONE), tossAttack: toss);
}

void ranged(String name, int level, appearance, String noun, int damage,
    int range, int tossDamage, int tossRange) {
  var toss = new RangedAttack("the ${name.toLowerCase()}",
      Log.makeVerbsAgree(_verb, Pronoun.IT), tossDamage, Element.NONE,
      tossRange);
  item(name, level, appearance, equipSlot: "weapon",
      attack: new RangedAttack(noun, "pierce[s]", damage, Element.NONE, range),
      tossAttack: toss);
}

void armor(String name, int level, appearance, int armor) {
  item(name, level, appearance, armor: armor);
}

void item(String name, int level, appearance, {String equipSlot, ItemUse use,
    Attack attack, Attack tossAttack, int armor: 0}) {
  // If the appearance isn"t an actual glyph, it should be a color function
  // that will be applied to the current glyph.
  if (appearance is! Glyph) {
    appearance = appearance(_glyph);
  }

  var categories = [];
  if (_category != null) categories = _category.split("/");

  if (equipSlot == null) equipSlot = _equipSlot;

  if (tossAttack == null && _tossDamage != null) {
    tossAttack = new RangedAttack("the ${name.toLowerCase()}", "hits",
        _tossDamage, Element.NONE, _tossRange);
  }

  Items.all[name] = new ItemType(name, appearance, level, _sortIndex++,
      categories, equipSlot, use, attack, tossAttack, armor);
}

