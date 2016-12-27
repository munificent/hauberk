import 'package:malison/malison.dart';

import '../engine.dart';
import 'utils.dart';

int _sortIndex = 0;

/// The current glyph. Any items defined will use this. Can be a string or
/// a character code.
var _glyph;

String _tagPath;
String _verb;
List<String> _flags;

int _tossDamage;
int _tossRange;
Element _tossElement;

/// Percent chance of objects in the current category breaking when thrown.
int _breakage;


/// Static class containing all of the [ItemType]s.
class Items {
  static final Map<String, ItemType> all = {};

  static Tag get rootTag => tags["item"];

  static final Map<String, Tag> tags = {
    "item": new Tag("item")
  };

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

    category(",", "item");
    tossable(damage: 4, range: 8, element: Element.earth, breakage: 10);
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
  category("%", null, flags: "flammable");
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
  category("!", "magic/potion/healing", flags: "freezable");
  tossable(damage: 1, range: 8, breakage: 100);
  healing("Soothing Balm",     1,   10, lightRed,     24);
  healing("Mending Salve",     7,   40, red,          48);
  healing("Healing Poultice", 12,   80, darkRed,      64, curePoison: true);
  healing("of Amelioration",  24,  200, darkPurple,  120, curePoison: true);
  healing("of Rejuvenation",  65,  500, purple,     1000, curePoison: true);

  healing("Antidote",         15,   18, green,         0, curePoison: true);

  category("!", "magic/potion/resistance", flags: "freezable");
  tossable(damage: 1, range: 8, breakage: 100);
  resistSalve("Heat",          5, 20, orange, Element.fire);
  resistSalve("Cold",          6, 24, lightBlue, Element.cold, "-freezable");
  resistSalve("Light",         7, 28, lightYellow, Element.light);
  resistSalve("Wind",          8, 32, lightAqua, Element.air);
  resistSalve("Electricity",   9, 36, lightPurple, Element.lightning);
  resistSalve("Darkness",     10, 40, darkGray, Element.dark);
  resistSalve("Earth",        13, 44, brown, Element.earth);
  resistSalve("Water",        16, 48, blue, Element.water);
  resistSalve("Acid",         19, 52, lightOrange, Element.acid);
  resistSalve("Poison",       23, 56, green, Element.poison);
  resistSalve("Death",        30, 60, purple, Element.spirit);

  // TODO: "Insulation", "the Elements" and other multi-element resistances.

  // Speed.
  category("!", "magic/potion/speed", flags: "freezable");
  tossable(damage: 1, range: 8, breakage: 100);
  potion("of Quickness",  3,  20, lightGreen, () => new HasteAction(20, 1));
  potion("of Alacrity",  18,  40, green,      () => new HasteAction(30, 2));
  potion("of Speed",     34, 200, darkGreen,  () => new HasteAction(40, 3));

  // dram, draught, elixir, philter

  // TODO: Make monsters drop these.
  category("?", "magic/potion/bottled", flags: "freezable");
  tossable(damage: 1, range: 8, breakage: 100);
  bottled("Wind",       4,   30, white,       Element.air,         8, "blasts");
  bottled("Ice",        7,   55, lightBlue,   Element.cold,       15, "freezes", flags: "-freezable");
  bottled("Fire",      11,   70, red,         Element.fire,       22, "burns");
  bottled("Ocean",     12,  110, blue,        Element.water,      26, "drowns");
  bottled("Earth",     13,  150, brown,       Element.earth,      28, "crushes");
  bottled("Lightning", 16,  200, lightPurple, Element.lightning,  34, "shocks");
  bottled("Acid",      18,  250, lightGreen,  Element.acid,       38, "corrodes");
  bottled("Poison",    22,  330, darkGreen,   Element.poison,     42, "infects");
  bottled("Shadows",   28,  440, black,       Element.dark,       48, "torments",
      noun: "the darkness");
  bottled("Radiance",  34,  600, white,       Element.light,      52, "sears");
  bottled("Spirits",   40, 1000, darkGray,    Element.spirit,     58, "haunts");

  // TODO: Potions that raise fury, sustain it, and that trade health for it.
}

void scrolls() {
  // Teleportation.
  category("?", "magic/scroll/teleportation", flags: "flammable");
  tossable(damage: 1, range: 4, breakage: 75);
  scroll("of Sidestepping",   2,  9, lightPurple, () => new TeleportAction(6));
  scroll("of Phasing",        6, 17, purple,      () => new TeleportAction(12));
  scroll("of Teleportation", 15, 33, darkPurple,  () => new TeleportAction(24));
  scroll("of Disappearing",  26, 47, darkBlue,    () => new TeleportAction(48));

  // Detection.
  category("?", "magic/scroll/detection", flags: "flammable");
  tossable(damage: 1, range: 4, breakage: 75);
  scroll("of Item Detection", 7, 27, lightOrange, () => new DetectItemsAction());
}

void weapons() {
  // Bludgeons.
  category(r"\", "equipment/weapon/club", verb: "hit[s]");
  tossable(breakage: 25, range: 7);
  weapon("Stick",          1,    0, brown,       4,   3);
  weapon("Cudgel",         3,    9, gray,        5,   4);
  weapon("Club",           6,   21, lightBrown,  6,   5);

  // Staves.
  category("_", "equipment/weapon/staff", verb: "hit[s]");
  tossable(breakage: 35, range: 6);
  weapon("Walking Stick",  2,    9, darkBrown,   5,   3);
  weapon("Staff",          5,   38, lightBrown,  7,   5);
  weapon("Quarterstaff",  11,  250, brown,      12,   8);

  // Hammers.
  category("=", "equipment/weapon/hammer", verb: "bash[es]");
  tossable(breakage: 15, range: 5);
  weapon("Hammer",        27,  621, brown,      16, 12);
  weapon("Mattock",       39, 1225, darkBrown,  20, 16);
  weapon("War Hammer",    45, 2106, lightGray,  24, 20);

  category("=", "equipment/weapon/mace", verb: "bash[es]");
  tossable(breakage: 15, range: 5);
  weapon("Morningstar",   24,  324, gray,       13, 11);
  weapon("Mace",          33,  891, darkGray,   18, 16);

  category("~", "equipment/weapon/whip", verb: "whip[s]");
  tossable(breakage: 25, range: 5);
  weapon("Whip",           4,    9, lightBrown,  5,  1);
  weapon("Chain Whip",    15,   95, darkGray,    9,  2);
  weapon("Flail",         27,  409, darkGray,   14,  4);

  category("|", "equipment/weapon/sword", verb: "slash[es]");
  tossable(breakage: 20, range: 6);
  weapon("Rapier",         7,  188, gray,       11,  4);
  weapon("Shortsword",    11,  324, darkGray,   13,  6);
  weapon("Scimitar",      18,  748, lightGray,  17,  9);
  weapon("Cutlass",       24, 1417, lightGold,  21, 11);
  weapon("Falchion",      38, 2374, white,      25, 15);

  /*

  // Two-handed swords.
  Bastard Sword[s]
  Longsword[s]
  Broadsword[s]
  Claymore[s]
  Flamberge[s]

  */

  // Knives.
  category("|", "equipment/weapon/dagger", verb: "stab[s]");
  tossable(breakage: 2, range: 10);
  weapon("Knife",          3,    9, gray,        5,  5);
  weapon("Dirk",           4,   21, lightGray,   6,  6);
  weapon("Dagger",         6,   63, white,       8,  8);
  weapon("Stiletto",      10,  188, darkGray,   11, 11);
  weapon("Rondel",        20,  409, lightAqua,  14, 14);
  weapon("Baselard",      30,  621, lightBlue,  16, 16);
  // Main-guache
  // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

  // Spears.
  category(r"\", "equipment/weapon/spear", verb: "stab[s]");
  tossable(breakage: 3, range: 11);
  weapon("Pointed Stick",  2,    0, brown,       5,  9);
  weapon("Spear",          7,  137, gray,       10, 15);
  weapon("Angon",         14,  621, lightGray,  16, 20);
  weapon("Lance",         28, 2106, white,      24, 28);
  weapon("Partisan",      35, 6833, darkGray,   36, 40);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(r"\", "equipment/weapon/axe", verb: "chop[s]");
  tossable(breakage: 4);
  weapon("Hatchet",        6,  137, darkGray,   10, 12, 10);
  weapon("Axe",           12,  621, lightBrown, 16, 18, 9);
  weapon("Valaska",       24, 2664, gray,       26, 26, 8);
  weapon("Battleaxe",     40, 4866, lightBlue,  32, 32, 7);

  // Sling. In a category itself because many bow affixes don't apply to it.
  category("}", "equipment/weapon/sling", verb: "hit[s]");
  tossable(breakage: 15, range: 5);
  ranged("Sling",          3,   20, darkBrown,  "the stone",  2, 10, 1);

  // Bows.
  category("}", "equipment/weapon/bow", verb: "hit[s]");
  tossable(breakage: 50, range: 5);
  ranged("Short Bow",      5,  180, brown,      "the arrow",  4, 12, 2);
  ranged("Longbow",       13,  600, lightBrown, "the arrow",  8, 14, 3);
  ranged("Crossbow",      28, 2000, gray,       "the bolt",  12, 16, 4);
}

void bodyArmor() {
  // TODO: Make some armor throwable.

  category("(", "equipment/armor/cloak");
  armor("Cloak",                   3,   19, darkBlue,    2);
  armor("Fur Cloak",               9,   42, lightBrown,  3);

  category("(", "equipment/armor/body");
  armor("Cloth Shirt",             2,   19, lightGray,   2);
  armor("Leather Shirt",           5,  126, lightBrown,  5);
  armor("Jerkin",                  7,  191, orange,      6);
  armor("Leather Armor",          10,  377, brown,       8);
  armor("Padded Armor",           14,  819, darkBrown,  11);
  armor("Studded Leather Armor",  17, 1782, gray,       15);
  armor("Mail Hauberk",           20, 2835, darkGray,   18);
  armor("Scale Mail",             23, 4212, lightGray,  21);

  category("(", "equipment/armor/body/robe");
  armor("Robe",                    2,   77, aqua,        4);
  armor("Fur-lined Robe",          9,  191, darkAqua,    6);

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
  category("]", "equipment/armor/boots");
  armor("Leather Sandals",       2,    6, lightBrown,  1);
  armor("Leather Shoes",         8,   19, brown,       2);
  armor("Leather Boots",        14,   77, darkBrown,   4);
  armor("Metal Shod Boots",     22,  274, gray,        7);
  armor("Greaves",              47, 1017, lightGray,  12);
}

void category(glyph, String tag, {String verb, String flags}) {
  _glyph = glyph;
  _tagPath = tag;
  _verb = verb;
  if (flags != null) {
    _flags = flags.split(" ");
  } else {
    _flags = const [];
  }

  // Default to not throwable.
  _tossDamage = null;
  _tossRange = null;
  _breakage = null;
}

/// Makes items in the current category throwable.
///
/// This must be called *after* [category] is called.
void tossable({int damage, Element element, int range, int breakage}) {
  if (element == null) element = Element.none;

  _tossDamage = damage;
  _tossElement = element;
  _tossRange = range;
  _breakage = breakage;
}

void treasure(String name, int depth, appearance, int price) {
  item(name, depth, appearance, treasure: true, price: price);
}

void potion(String name, int depth, int price, appearance, ItemUse use) {
  if (name.startsWith("of")) name = "Potion $name";

  item(name, depth, appearance, price: price, use: use);
}

void healing(String name, int depth, int price, appearance, int amount,
    {bool curePoison: false}) {
  potion(name, depth, price, appearance,
      () => new HealAction(amount, curePoison: curePoison));
}

void resistSalve(String name, int depth, int price, appearance,
    Element element, [String flags]) {
  item("Salve of $name Resistance", depth, appearance,
      price: price, use: () => new ResistAction(40, element),
      flags: flags);
}

void bottled(String name, int depth, int price, appearance, Element element,
    int damage, String verb, {String noun, String flags}) {
  if (noun == null) noun = "the ${name.toLowerCase()}";

  item("Bottled $name", depth, appearance, price: price,
      use: () => new RingSelfAction(
          new RangedAttack(noun, verb, damage, element, 6)),
      flags: flags);
}

void scroll(String name, int depth, int price, appearance, ItemUse use) {
  if (name.startsWith("of")) name = "Scroll $name";

  item(name, depth, appearance, price: price, use: use);
}

void weapon(String name, int depth, int price, appearance, int damage,
      int tossDamage,
      [int tossRange]) {
  var toss = new RangedAttack("the ${name.toLowerCase()}",
      Log.makeVerbsAgree(_verb, Pronoun.it), tossDamage, Element.none,
      tossRange != null ? tossRange : _tossRange);
  item(name, depth, appearance,
      attack: attack(_verb, damage, Element.none),
      tossAttack: toss,
      price: price);
}

void ranged(String name, int depth, int price, appearance, String noun,
    int damage, int range, int tossDamage) {
  var toss = new RangedAttack("the ${name.toLowerCase()}",
      Log.makeVerbsAgree(_verb, Pronoun.it), tossDamage, Element.none,
      _tossRange);
  item(name, depth, appearance,
      attack: new RangedAttack(noun, "pierce[s]", damage, Element.none, range),
      tossAttack: toss,
      price: price);
}

void armor(String name, int depth, int price, appearance, int armor) {
  item(name, depth, appearance, armor: armor, price: price);
}

void item(String name, int depth, appearance, {ItemUse use,
    Attack attack, Attack tossAttack, int armor: 0, int price: 0,
    bool treasure: false, String flags}) {
  // If the appearance isn't an actual glyph, it should be a color function
  // that will be applied to the current glyph.
  if (appearance is! Glyph) {
    appearance = appearance(_glyph);
  }

  List<String> tags;
  if (_tagPath == "item") {
    tags = ["item"];
  } else if (_tagPath != null) {
    tags = ["item"];
    tags.addAll(_tagPath.split("/"));
  }

  Tag tag;
  if (tags != null) {
    Tag parent;
    for (var tagName in tags) {
      tag = Items.tags.putIfAbsent(tagName, () => new Tag(tagName));
      if (parent != null) tag.parents.add(parent);
      parent = tag;
    }
  }

  // Use the tags (if any) to figure out which slot it can be equipped in.
  String equipSlot;
  if (tag != null) {
    // TODO: Copied from equipment.dart. Unify?
    var equipSlots = [
      'weapon',
      'ring',
      'necklace',
      'body',
      'cloak',
      'shield',
      'helm',
      'gloves',
      'boots'
    ];

    for (var slot in equipSlots) {
      if (tag.hasTag(slot)) {
        equipSlot = slot;
        break;
      }
    }
  }

  if (tossAttack == null && _tossDamage != null) {
    tossAttack = new RangedAttack("the ${name.toLowerCase()}", "hits",
        _tossDamage, _tossElement, _tossRange);
  }

  var itemType = new ItemType(name, appearance, depth, _sortIndex++, equipSlot,
      use, attack, tossAttack, _breakage, armor, price,
      treasure: treasure);

  if (tag != null) itemType.tags.add(tag);

  itemType.flags.addAll(_flags);
  if (flags != null) {
    for (var flag in flags.split(" ")) {
      if (flag.startsWith("-")) {
        itemType.flags.remove(flag.substring(1));
      } else {
        itemType.flags.add(flag);
      }
    }
  }

  Items.all[name] = itemType;
}

