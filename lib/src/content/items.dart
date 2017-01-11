import 'package:malison/malison.dart';

import '../engine.dart';
import 'affixes.dart';
import 'utils.dart';

int _sortIndex = 0;

/// The current glyph. Any items defined will use this. Can be a string or
/// a character code.
var _glyph;

String _tag;
String _equipSlot;
String _weaponType;
String _verb;
List<String> _flags;
int _maxStack;
int _tossDamage;
int _tossRange;
Element _tossElement;

/// Percent chance of objects in the current category breaking when thrown.
int _breakage;

TossItemUse _tossUse;

/// Static class containing all of the [ItemType]s.
class Items {
  static final types = new ResourceSet<ItemType>();

  static void initialize() {
    types.defineTags("item");

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

    category(",", stack: 10, tag: "item");
    tossable(damage: 3, range: 8, element: Element.earth, breakage: 10);
    item("Rock", 1, 1, lightBrown);

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
  category("¢", tag: "treasure/coin");
  // TODO: Figure out these should be quantified.
  treasure("Copper Coins",    1, brown,           1);
  treasure("Bronze Coins",    7, darkGold,        8);
  treasure("Silver Coins",   11, gray,           20);
  treasure("Electrum Coins", 20, lightGold,      50);
  treasure("Gold Coins",     30, gold,           100);
  treasure("Platinum Coins", 40, lightGray,      300);

  // Bars.
  category(r"$", tag: "treasure/bar");
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
  // TODO: Should these appear on the floor?
  category("%", stack: 20, flags: "flammable");
  item("Flower",        1, 1, lightAqua); // TODO: Use in recipe.
  item("Insect Wing",   1, 1, purple);
  item("Red Feather",   2, 1, red); // TODO: Use in recipe.
  item("Black Feather", 2, 1, darkGray);
  item("Stinger",       2, 1, gold);

  category("%", stack: 4, flags: "flammable");
  item("Fur Pelt",      1, 1, lightBrown);
  item("Fox Pelt",      2, 1, orange);
}

void potions() {
  category("!", stack: 10, flags: "freezable");

  // TODO: Make these foods?

  // TODO: Potions should shatter when thrown. Some should perform an effect.

  // Healing.
  tagged("magic/potion/healing");
  tossable(damage: 1, range: 8, breakage: 100);
  healing("Soothing Balm",     2, 1,   10, lightRed,     24);
  healing("Mending Salve",     7, 1,   40, red,          48);
  healing("Healing Poultice", 12, 1,   80, darkRed,      64, curePoison: true);
  healing("of Amelioration",  24, 1,  200, darkPurple,  120, curePoison: true);
  healing("of Rejuvenation",  65, 2,  500, purple,     1000, curePoison: true);

  healing("Antidote",          4, 2,   40, green,         0, curePoison: true);

  tagged("magic/potion/resistance");
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
  tagged("magic/potion/speed");
  tossable(damage: 1, range: 8, breakage: 100);
  potion("of Quickness",  3, 3,  20, lightGreen, () => new HasteAction(20, 1));
  potion("of Alacrity",  18, 3,  40, green,      () => new HasteAction(30, 2));
  potion("of Speed",     34, 4, 200, darkGreen,  () => new HasteAction(40, 3));

  // dram, draught, elixir, philter

  // TODO: Make monsters drop these.
  // TODO: These should do their ball attack when thrown too.
  tagged("magic/potion/bottled");
  tossable(damage: 1, range: 12, breakage: 100);
  bottled("Wind",         4,   30, white,       Element.air,         8, "blasts");
  bottled("Ice",          7,   55, lightBlue,   Element.cold,       15, "freezes", flags: "-freezable");
  bottled("Fire",        11,   70, red,         Element.fire,       22, "burns");
  bottled("Ocean",       12,  110, blue,        Element.water,      26, "drowns");
  bottled("Earth",       13,  150, brown,       Element.earth,      28, "crushes");
  bottled("Lightning",   16,  200, lightPurple, Element.lightning,  34, "shocks");
  bottled("Acid",        18,  250, lightGreen,  Element.acid,       38, "corrodes");
  bottled("Poison",      22,  330, darkGreen,   Element.poison,     42, "infects");
  bottled("Shadow",      28,  440, black,       Element.dark,       48, "torments",
      noun: "the darkness");
  bottled("Radiance",    34,  600, white,       Element.light,      52, "sears");
  bottled("Spirit",      40, 1000, darkGray,    Element.spirit,     58, "haunts");
  // TODO: Potions that raise fury, sustain it, and that trade health for it.
}

void scrolls() {
  category("?", stack: 20, flags: "flammable");

  // Teleportation.
  tagged("magic/scroll/teleportation");
  tossable(damage: 1, range: 4, breakage: 75);
  scroll("of Sidestepping",   2, 2,  9, lightPurple, () => new TeleportAction(6));
  scroll("of Phasing",        6, 3, 17, purple,      () => new TeleportAction(12));
  scroll("of Teleportation", 15, 3, 33, darkPurple,  () => new TeleportAction(24));
  scroll("of Disappearing",  26, 3, 47, darkBlue,    () => new TeleportAction(48));

  // Detection.
  tagged("magic/scroll/detection");
  tossable(damage: 1, range: 4, breakage: 75);
  detection("of Find Nearby Escape",  1,  2,   20, lightYellow, [DetectType.exit], range: 20);
  detection("of Find Nearby Items",   2,  2,   20, yellow, [DetectType.item], range: 20);
  detection("of Detect Nearby",       3,  4,   20, darkYellow, [DetectType.exit, DetectType.item], range: 20);

  detection("of Locate Escape",       5,  1,   20, lightOrange, [DetectType.exit]);
  detection("of Item Detection",     20,  2,   27, orange, [DetectType.item]);
  detection("of Detection",          30,  4,  240, darkOrange, [DetectType.exit, DetectType.item]);
}

void weapons() {
  // Bludgeons.
  category(r"\", tag: "equipment/weapon/club", verb: "hit[s]");
  tossable(breakage: 25, range: 7);
  weapon("Stick",          1,    0, brown,       4,   3);
  weapon("Cudgel",         3,    9, gray,        5,   4);
  weapon("Club",           6,   21, lightBrown,  6,   5);

  // Staves.
  category("_", tag: "equipment/weapon/staff", verb: "hit[s]");
  tossable(breakage: 35, range: 6);
  weapon("Walking Stick",        2,    9, darkBrown,   5,   3);
  weapon("Sta[ff|aves]",         5,   38, lightBrown,  7,   5);
  weapon("Quartersta[ff|aves]", 11,  250, brown,      12,   8);

  // Hammers.
  category("=", tag: "equipment/weapon/hammer", verb: "bash[es]");
  tossable(breakage: 15, range: 5);
  weapon("Hammer",        27,  621, brown,      16, 12);
  weapon("Mattock",       39, 1225, darkBrown,  20, 16);
  weapon("War Hammer",    45, 2106, lightGray,  24, 20);

  category("=", tag: "equipment/weapon/mace", verb: "bash[es]");
  tossable(breakage: 15, range: 5);
  weapon("Morningstar",   24,  324, gray,       13, 11);
  weapon("Mace",          33,  891, darkGray,   18, 16);

  category("~", tag: "equipment/weapon/whip", verb: "whip[s]");
  tossable(breakage: 25, range: 5);
  weapon("Whip",           4,    9, lightBrown,  5,  1);
  weapon("Chain Whip",    15,   95, darkGray,    9,  2);
  weapon("Flail",         27,  409, darkGray,   14,  4);

  category("|", tag: "equipment/weapon/sword", verb: "slash[es]");
  tossable(breakage: 20, range: 6);
  weapon("Rapier",         7,  188, gray,       11,  4);
  weapon("Shortsword",    11,  324, darkGray,   13,  6);
  weapon("Scimitar",      18,  748, lightGray,  17,  9);
  weapon("Cutlass[es]",   24, 1417, lightGold,  21, 11);
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
  category("|", tag: "equipment/weapon/dagger", verb: "stab[s]");
  tossable(breakage: 2, range: 10);
  weapon("Kni[fe|ves]",    3,    9, gray,        5,  5);
  weapon("Dirk",           4,   21, lightGray,   6,  6);
  weapon("Dagger",         6,   63, white,       8,  8);
  weapon("Stiletto[es]",  10,  188, darkGray,   11, 11);
  weapon("Rondel",        20,  409, lightAqua,  14, 14);
  weapon("Baselard",      30,  621, lightBlue,  16, 16);
  // Main-guache
  // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

  // Spears.
  category("/", tag: "equipment/weapon/spear", verb: "stab[s]");
  tossable(breakage: 3, range: 11);
  weapon("Pointed Stick",  2,    0, brown,       5,  9);
  weapon("Spear",          7,  137, gray,       10, 15);
  weapon("Angon",         14,  621, lightGray,  16, 20);
  weapon("Lance",         28, 2106, white,      24, 28);
  weapon("Partisan",      35, 6833, darkGray,   36, 40);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(CharCode.rightAngle, tag: "equipment/weapon/axe", verb: "chop[s]");
  tossable(breakage: 4);
  weapon("Hatchet",    6,  137, darkGray,   10, 12, 10);
  weapon("Axe",       12,  621, lightBrown, 16, 18, 9);
  weapon("Valaska",   24, 2664, gray,       26, 26, 8);
  weapon("Battleaxe", 40, 4866, lightBlue,  32, 32, 7);

  // Sling. In a category itself because many bow affixes don't apply to it.
  category("}", tag: "equipment/weapon/sling", verb: "hit[s]");
  tossable(breakage: 15, range: 5);
  ranged("Sling",          3,   20, darkBrown,  "the stone",  2, 10, 1);

  // Bows.
  category("}", tag: "equipment/weapon/bow", verb: "hit[s]");
  tossable(breakage: 50, range: 5);
  ranged("Short Bow",      5,  180, brown,      "the arrow",  4, 12, 2);
  ranged("Longbow",       13,  600, lightBrown, "the arrow",  8, 14, 3);
  ranged("Crossbow",      28, 2000, gray,       "the bolt",  12, 16, 4);
}

void bodyArmor() {
  // TODO: Make some armor throwable.

  category("(", tag: "equipment/armor/cloak");
  armor("Cloak",                   3,   2, 19, darkBlue,    2);
  armor("Fur Cloak",               5,   5, 42, lightBrown,  3);

  category("(", tag: "equipment/armor/body");
  armor("Cloth Shirt",             2,   2,   19, lightGray,   2);
  armor("Leather Shirt",           5,   2,  126, lightBrown,  5);
  armor("Jerkin",                  7,   2,  191, orange,      6);
  armor("Leather Armor",          10,   2,  377, brown,       8);
  armor("Padded Armor",           14,   2,  819, darkBrown,  11);
  armor("Studded Leather Armor",  17,   2, 1782, gray,       15);
  armor("Mail Hauberk",           20,   2, 2835, darkGray,   18);
  armor("Scale Mail",             23,   2, 4212, lightGray,  21);

  category("(", tag: "equipment/armor/body/robe");
  armor("Robe",                    2,   2,   77, aqua,        4);
  armor("Fur-lined Robe",          6,   4,  191, darkAqua,    6);

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
  category("]", tag: "equipment/armor/boots");
  armor("Pair[s] of Leather Sandals",       2, 4,    6, lightBrown,  1);
  armor("Pair[s] of Leather Shoes",         8, 3,   19, brown,       2);
  armor("Pair[s] of Leather Boots",        14, 3,   77, darkBrown,   4);
  armor("Pair[s] of Metal Shod Boots",     22, 3,  274, gray,        7);
  armor("Pair[s] of Greaves",              47, 4, 1017, lightGray,  12);
}

void category(glyph, {String tag, String verb, String flags, int stack: 1}) {
  _glyph = glyph;

  _verb = verb;
  if (flags != null) {
    _flags = flags.split(" ");
  } else {
    _flags = const [];
  }

  tagged(tag);

  _maxStack = stack;

  // Default to not throwable.
  _tossDamage = null;
  _tossRange = null;
  _breakage = null;
}

void tagged(String tagPath) {
  _equipSlot = null;
  _weaponType = null;
  if (tagPath != null) {
    // Define the tag path and store the leaf tag which is what gets used by
    // the item types.
    Items.types.defineTags("item/$tagPath");
    var tags = tagPath.split("/");
    _tag = tags.last;

    const tagEquipSlots = const [
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

    for (var equipSlot in tagEquipSlots) {
      if (tags.contains(equipSlot)) {
        _equipSlot = equipSlot;
        break;
      }
    }

    if (tags.contains("weapon")) {
      _weaponType = tags[tags.indexOf("weapon") + 1];
    }

    // TODO: Hacky. We need a matching tag hiearchy for affixes so that, for
    // example, a "sword" item will match a "weapon" affix.
    Affixes.defineItemTag(tagPath);
  } else {
    _tag = null;
  }
}

/// Makes items in the current category throwable.
///
/// This must be called *after* [category] is called.
void tossable({int damage, Element element, int range, int breakage,
    TossItemUse use}) {
  element ??= Element.none;

  _tossDamage = damage;
  _tossElement = element;
  _tossRange = range;
  _breakage = breakage;
  _tossUse = use;
}

void treasure(String name, int depth, appearance, int price) {
  item(name, depth, 1, appearance, treasure: true, price: price);
}

void potion(String name, int depth, int rarity, int price, appearance, ItemUse use) {
  if (name.startsWith("of")) name = "Potion[s] $name";

  item(name, depth, rarity, appearance, price: price, use: use);
}

void healing(String name, int depth, int rarity, int price, appearance, int amount,
    {bool curePoison: false}) {
  potion(name, depth, rarity, price, appearance,
      () => new HealAction(amount, curePoison: curePoison));
}

void resistSalve(String name, int depth, int price, appearance,
    Element element, [String flags]) {
  item("Salve[s] of $name Resistance", depth, 2, appearance,
      price: price, use: () => new ResistAction(40, element),
      flags: flags);
}

void bottled(String name, int depth, int price, appearance, Element element,
    int damage, String verb, {String noun, String flags}) {
  noun ??= "the ${name.toLowerCase()}";

  var attack = new Attack(new Noun(noun), verb, damage, 3, element);
  item("Bottled $name", depth, 2, appearance, price: price,
      use: () => new RingSelfAction(attack),
      tossUse: (pos) => new RingAtAction(attack, pos),
      flags: flags);
}

void detection(String name, int depth, int rarity, int price, appearance,
    List<DetectType> types, {int range}) {
  scroll(name, depth, rarity, price, appearance, () => new DetectAction(types, range));
}

void scroll(String name, int depth, int rarity, int price, appearance, ItemUse use) {
  if (name.startsWith("of")) name = "Scroll[s] $name";

  item(name, depth, rarity, appearance, price: price, use: use);
}

void weapon(String name, int depth, int price, appearance, int damage,
      int tossDamage,
      [int tossRange]) {
  var noun = new Noun("the ${name.toLowerCase()}");
  var verb = Log.conjugate(_verb, Pronoun.it);
  var toss = new Attack(noun, verb, tossDamage, tossRange ?? _tossRange);
  // TODO: Individual rarities.
  item(name, depth, 2, appearance,
      attack: new Attack(null, _verb, damage),
      tossAttack: toss,
      price: price);
}

void ranged(String name, int depth, int price, appearance, String noun,
    int damage, int range, int tossDamage) {
  var tossNoun = new Noun("the ${name.toLowerCase()}");
  var verb = Log.conjugate(_verb, Pronoun.it);
  var toss = new Attack(tossNoun, verb, tossDamage, _tossRange);
  // TODO: Individual rarities.
  item(name, depth, 3, appearance,
      attack: new Attack(new Noun(noun), "pierce[s]", damage, range),
      tossAttack: toss,
      price: price);
}

void armor(String name, int depth, int rarity, int price, appearance, int armor) {
  item(name, depth, rarity, appearance, armor: armor, price: price);
}

void item(String name, int depth, int rarity, appearance, {ItemUse use,
    TossItemUse tossUse,
    Attack attack, Attack tossAttack, int armor: 0, int price: 0,
    bool treasure: false, String flags}) {
  // If the appearance isn't an actual glyph, it should be a color function
  // that will be applied to the current glyph.
  if (appearance is! Glyph) {
    appearance = appearance(_glyph);
  }

  if (tossAttack == null && _tossDamage != null) {
    var noun = new Noun("the ${name.toLowerCase()}");
    tossAttack = new Attack(
        noun, "hits", _tossDamage, _tossRange, _tossElement);
  }

  Toss toss;
  if (tossAttack != null) {
    toss = new Toss(_breakage, tossAttack, tossUse ?? _tossUse);
  }

  var itemType = new ItemType(name, appearance, depth, _sortIndex++, _equipSlot,
      _weaponType, use, attack, toss, armor, price, _maxStack,
      treasure: treasure);

  // Use the tags (if any) to figure out which slot it can be equipped in.
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

  Items.types.add(itemType.name, itemType, itemType.depth, rarity, _tag);
}

