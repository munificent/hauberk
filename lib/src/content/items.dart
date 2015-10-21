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
Element _tossElement;

/// Percent chance of objects in the current category breaking when thrown.
int _breakage;

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
    tossable(damage: 4, range: 8, element: Element.EARTH, breakage: 10);
    item("Rock", 1, lightBrown);

    treasures();
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

void treasures() {
  // TODO: Make monsters and areas drop these.
  // Coins.
  category("¢", "treasure/coin");
  treasure("Copper Coins",    1, brown,           1);
  treasure("Bronze Coins",    7, darkGold,        8);
  treasure("Silver Coins",   11, gray,           20);
  treasure("Electrum Coins", 20, lightGold,      50);
  treasure("Gold Coins",     30, gold,           100);
  treasure("Platinum Coins", 40, lightGray,      300);

  // Bars.
  category(r"$", "treasure/bar");
  treasure("Copper Bar",     35, brown,          150);
  treasure("Bronze Bar",     50, darkGold,       500);
  treasure("Silver Bar",     60, gray,           800);
  treasure("Electrum Bar",   70, lightGold,     1200);
  treasure("Gold Bar",       80, gold,          2000);
  treasure("Platinum Bar",   90, lightGray,     3000);

  // TODO: Could add more treasure using other currency symbols.

  // TODO: Instead of treasure, make these recipe components.
  /*
  // Gems
  category(r"$", "treasure/gem");
  tossable(damage: 2, range: 7, breakage: 5);
  treasure("Amethyst",      3,  lightPurple,   100);
  treasure("Sapphire",      12, blue,          200);
  treasure("Emerald",       20, green,         300);
  treasure("Ruby",          35, red,           500);
  treasure("Diamond",       60, white,        1000);
  treasure("Blue Diamond",  80, lightBlue,    2000);

  // Rocks
  category(r"$", "treasure/rock");
  tossable(damage: 2, range: 7, breakage: 5);
  treasure("Turquoise Stone", 15, aqua,         60);
  treasure("Onyx Stone",      20, darkGray,    160);
  treasure("Malachite Stone", 25, lightGreen,  400);
  treasure("Jade Stone",      30, darkGreen,   400);
  treasure("Pearl",           35, lightYellow, 600);
  treasure("Opal",            40, lightPurple, 800);
  treasure("Fire Opal",       50, lightOrange, 900);
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
  category("!", "magic/potion/healing");
  tossable(damage: 1, range: 8, breakage: 100);
  item("Soothing Balm", 1, lightRed,
      use: () => new HealAction(24));
  item("Mending Salve", 7, red,
      use: () => new HealAction(48));
  item("Healing Poultice", 12, darkRed,
      use: () => new HealAction(64, curePoison: true));
  item("Potion of Amelioration", 24, darkPurple,
      use: () => new HealAction(120, curePoison: true));
  item("Potion of Rejuvenation", 65, purple,
      use: () => new HealAction(1000, curePoison: true));

  category("!", "magic/potion/resistance");
  tossable(damage: 1, range: 8, breakage: 100);
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
  category("!", "magic/potion/speed");
  tossable(damage: 1, range: 8, breakage: 100);
  item("Potion of Quickness", 3, lightGreen,
      use: () => new HasteAction(20, 1));
  item("Potion of Alacrity", 18, green,
      use: () => new HasteAction(30, 2));
  item("Potion of Speed", 34, darkGreen,
      use: () => new HasteAction(40, 3));

  // dram, draught, elixir, philter

  // TODO: Make monsters drop these.
  category("?", "magic/potion/bottled");
  tossable(damage: 1, range: 8, breakage: 100);
  bottledElement(String name, int level, appearance, Element element,
      int damage, int range, String noun, String verb) {
    item("Bottled $name", level, appearance, use: () => new RingSelfAction(
        new RangedAttack(noun, verb, damage, element, range)));
  }

  bottledElement("Wind", 4, white, Element.AIR, 8, 6, "the wind", "blasts");
  bottledElement("Ice", 7, lightBlue, Element.COLD, 15, 7, "the ice", "freezes");
  bottledElement("Fire", 11, red, Element.FIRE, 22, 8, "the fire", "burns");
  bottledElement("Water", 12, blue, Element.WATER, 26, 8, "the water", "drowns");
  bottledElement("Earth", 13, brown, Element.EARTH, 28, 9, "the earth", "crushes");
  bottledElement("Lightning", 16, lightPurple, Element.LIGHTNING, 34, 9, "the lightning", "shocks");
  bottledElement("Acid", 18, lightGreen, Element.ACID, 38, 10, "the acid", "corrodes");
  bottledElement("Poison", 22, darkGreen, Element.POISON, 42, 10, "the poison", "infects");
  bottledElement("Shadows", 28, black, Element.DARK, 48, 11, "the darkness", "torments");
  bottledElement("Radiance", 34, white, Element.LIGHT, 52, 11, "the light", "sears");
  bottledElement("Spirits", 40, darkGray, Element.SPIRIT, 58, 12, "the spirit", "haunts");
}

void scrolls() {
  // Teleportation.
  category("?", "magic/scroll/teleportation");
  tossable(damage: 1, range: 4, breakage: 75);
  item("Scroll of Sidestepping", 2, lightPurple,
      use: () => new TeleportAction(6));
  item("Scroll of Phasing", 6, purple,
      use: () => new TeleportAction(12));
  item("Scroll of Teleportation", 15, darkPurple,
      use: () => new TeleportAction(24));
  item("Scroll of Disappearing", 26, darkBlue,
      use: () => new TeleportAction(48));

  // Detection.
  category("?", "magic/scroll/detection");
  tossable(damage: 1, range: 4, breakage: 75);
  item("Scroll of Item Detection", 7, lightOrange,
      use: () => new DetectItemsAction());
}

void weapons() {
  // Bludgeons.
  category(r"\", "equipment/weapon/club", verb: "hit[s]");
  tossable(breakage: 25);
  weapon("Stick",          1, brown,       4,  3, 7);
  weapon("Cudgel",         3, gray,        5,  4, 7);
  weapon("Club",           6, lightBrown,  6,  5, 7);

  // Staves.
  category("_", "equipment/weapon/staff", verb: "hit[s]");
  tossable(breakage: 35);
  weapon("Walking Stick",  2, darkBrown,   5,  3, 6);
  weapon("Staff",          5, lightBrown,  7,  5, 6);
  weapon("Quarterstaff",  11, brown,      12,  8, 6);

  // Hammers.
  category("=", "equipment/weapon/hammer", verb: "bash[es]");
  tossable(breakage: 15);
  weapon("Hammer",        27, brown,      16, 12, 5);
  weapon("Mattock",       39, darkBrown,  20, 16, 5);
  weapon("War Hammer",    45, lightGray,  24, 20, 5);

  category("=", "equipment/weapon/mace", verb: "bash[es]");
  tossable(breakage: 15);
  weapon("Morningstar",   24, gray,       13, 11, 5);
  weapon("Mace",          33, darkGray,   18, 16, 5);

  category("~", "equipment/weapon/whip", verb: "whip[s]");
  tossable(breakage: 25);
  weapon("Whip",           4, lightBrown,  5,  1, 5);
  weapon("Chain Whip",    15, darkGray,    9,  2, 5);
  weapon("Flail",         27, darkGray,   14,  4, 5);

  category("|", "equipment/weapon/sword", verb: "slash[es]");
  tossable(breakage: 20);
  weapon("Rapier",         7, gray,       11,  4, 6);
  weapon("Shortsword",    11, darkGray,   13,  6, 6);
  weapon("Scimitar",      18, lightGray,  17,  9, 6);
  weapon("Cutlass",       24, lightGold,  21, 11, 6);
  weapon("Falchion",      38, white,      25, 15, 6);

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
  tossable(breakage: 2);
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
  tossable(breakage: 3);
  weapon("Pointed Stick",  2, brown,       5,  9, 11);
  weapon("Spear",          7, gray,       10, 15, 11);
  weapon("Angon",         14, lightGray,  16, 20, 11);
  weapon("Lance",         28, white,      24, 28, 11);
  weapon("Partisan",      35, darkGray,   36, 40, 11);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(r"\", "equipment/weapon/axe", verb: "chop[s]");
  tossable(breakage: 4);
  weapon("Hatchet",        6, darkGray,   10, 12, 10);
  weapon("Axe",           12, lightBrown, 16, 18, 9);
  weapon("Valaska",       20, gray,       26, 26, 8);
  weapon("Battleaxe",     30, lightBlue,  32, 32, 7);

  // Sling. In a category itself because many box affixes don't apply to it.
  category("}", "equipment/weapon/sling", verb: "hit[s]");
  tossable(breakage: 15);
  ranged("Sling",          3, darkBrown,  "the stone",  3, 10, 1, 5);

  // Bows.
  category("}", "equipment/weapon/bow", verb: "hit[s]");
  tossable(breakage: 50);
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

void category(glyph, String category, {String equip, String verb}) {
  _glyph = glyph;
  if (category == null) {
    _category = null;
  } else {
    _category = "item/$category";
  }

  _equipSlot = equip;
  _verb = verb;

  // Default to not throwable.
  _tossDamage = null;
  _tossRange = null;
  _breakage = null;
}

/// Makes items in the current category throwable.
///
/// This must be called *after* [category] is called.
void tossable({int damage, Element element, int range, int breakage}) {
  if (element == null) element = Element.NONE;

  _tossDamage = damage;
  _tossElement = element;
  _tossRange = range;
  _breakage = breakage;
}

void treasure(String name, int level, appearance, int price) {
  item(name, level, appearance, treasure: true, price: price);
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
    Attack attack, Attack tossAttack, int armor: 0, int price: 0,
    bool treasure: false}) {
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
        _tossDamage, _tossElement, _tossRange);
  }

  Items.all[name] = new ItemType(name, appearance, level, _sortIndex++,
      categories, equipSlot, use, attack, tossAttack, _breakage, armor, price,
      treasure: treasure);
}

