import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'affixes.dart';

int _sortIndex = 0;

/// The current glyph's character code. Any items defined will use this.
int _glyph;

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

    category(CharCode.latinCapitalLetterCWithCedilla, stack: 10, tag: "item");
    tossable(damage: 3, range: 7, element: Element.earth, breakage: 10);
    item("Rock", 1, 1, persimmon);

    category(CharCode.latinSmallLetterUWithDiaeresis, stack: 4, tag: "item");
    tossable(damage: 2, range: 5, breakage: 30);
    item("Skull", 1, 1, gunsmoke);

//    treasures();
    pelts();
    potions();
    scrolls();
    // TODO: Rings.
    // TODO: Amulets.
    weapons();
    bodyArmor();
    // TODO: Shields.
    // TODO: Helmets.
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
    // CharCode.latinSmallLetterUWithDiaeresis // skull
    // CharCode.latinSmallLetterIWithDiaeresis // ring
    // CharCode.latinSmallLetterIWithCircumflex // wand
    // CharCode.latinCapitalLetterAWithRingAbove // gloves
    // CharCode.latinCapitalLetterEWithAcute // helm
    // CharCode.latinSmallLetterAe // shield
  }
}

void treasures() {
  // TODO: Make monsters and areas drop these.
  // Coins.
  category(CharCode.centSign, tag: "treasure/coin");
  // TODO: Figure out these should be quantified.
  treasure("Copper Coins",    1, copper,          1);
  treasure("Bronze Coins",    7, persimmon,       8);
  treasure("Silver Coins",   11, turquoise,      20);
  treasure("Electrum Coins", 20, buttermilk,     50);
  treasure("Gold Coins",     30, gold,          100);
  treasure("Platinum Coins", 40, gunsmoke,      300);

  // Bars.
  category(CharCode.dollarSign, tag: "treasure/bar");
  treasure("Copper Bar",     35, copper,        150);
  treasure("Bronze Bar",     50, persimmon,     500);
  treasure("Silver Bar",     60, turquoise,     800);
  treasure("Electrum Bar",   70, buttermilk,   1200);
  treasure("Gold Bar",       80, gold,         2000);
  treasure("Platinum Bar",   90, gunsmoke,     3000);

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
  // TODO: Better pictogram than a pelt?
  category(CharCode.latinSmallLetterEWithAcute, stack: 20, flags: "flammable");
  item("Flower",        1, 1, cornflower); // TODO: Use in recipe.
  item("Insect Wing",   1, 1, violet);
  item("Red Feather",   2, 1, brickRed); // TODO: Use in recipe.
  item("Black Feather", 2, 1, steelGray);
  item("Stinger",       2, 1, gold);

  category(CharCode.latinSmallLetterEWithAcute, stack: 4, flags: "flammable");
  item("Fur Pelt",      1, 1, persimmon);
  item("Fox Pelt",      2, 1, copper);
}

void potions() {
  category(CharCode.latinSmallLetterCWithCedilla, stack: 10, flags: "freezable");

  // TODO: Potions should shatter when thrown. Some should perform an effect.

  // TODO: Make these foods?

  // Healing.
  tagged("magic/potion/healing");
  tossable(damage: 1, range: 6, breakage: 100);
  healing("Soothing Balm",     2, 1,   10, salmon,       48);
  healing("Mending Salve",     7, 1,   40, brickRed,    100);
  healing("Healing Poultice", 12, 1,   80, maroon,      200, curePoison: true);
  healing("of Amelioration",  24, 1,  200, indigo,      400, curePoison: true);
  healing("of Rejuvenation",  65, 2,  500, violet,     1000, curePoison: true);

  healing("Antidote",          4, 2,   40, peaGreen,      0, curePoison: true);

  category(CharCode.latinSmallLetterEWithCircumflex, stack: 10, flags: "freezable");
  tagged("magic/potion/resistance");
  tossable(damage: 1, range: 6, breakage: 100);
  resistSalve("Heat",          5, 20, carrot, Element.fire);
  resistSalve("Cold",          6, 24, cornflower, Element.cold, "-freezable");
  resistSalve("Light",         7, 28, buttermilk, Element.light);
  resistSalve("Wind",          8, 32, turquoise, Element.air);
  resistSalve("Electricity",   9, 36, lilac, Element.lightning);
  resistSalve("Darkness",     10, 40, slate, Element.dark);
  resistSalve("Earth",        13, 44, persimmon, Element.earth);
  resistSalve("Water",        16, 48, ultramarine, Element.water);
  resistSalve("Acid",         19, 52, sandal, Element.acid); // TODO: Better color.
  resistSalve("Poison",       23, 56, lima, Element.poison);
  resistSalve("Death",        30, 60, violet, Element.spirit);

  // TODO: "Insulation", "the Elements" and other multi-element resistances.

  category(CharCode.latinSmallLetterEWithDiaeresis, stack: 10, flags: "freezable");

  // Speed.
  tagged("magic/potion/speed");
  tossable(damage: 1, range: 6, breakage: 100);
  potion("of Quickness",  3, 3,  20, lima,     () => new HasteAction(20, 1));
  potion("of Alacrity",  18, 3,  40, peaGreen, () => new HasteAction(30, 2));
  potion("of Speed",     34, 4, 200, sherwood, () => new HasteAction(40, 3));

  // dram, draught, elixir, philter

  category(CharCode.latinSmallLetterEWithGrave, stack: 10, flags: "freezable");

  // TODO: Make monsters drop these.
  tagged("magic/potion/bottled");
  tossable(damage: 1, range: 8, breakage: 100);
  bottled("Wind",         4,   30, cornflower,  Element.air,        20, "blasts", flow: true, fly: true);
  bottled("Ice",          7,   55, cerulean,    Element.cold,       30, "freezes", flags: "-freezable");
  bottled("Fire",        11,   70, brickRed,    Element.fire,       44, "burns", flow: true, fly: true);
  bottled("Ocean",       12,  110, ultramarine, Element.water,      52, "drowns", flow: true);
  bottled("Earth",       13,  150, persimmon,   Element.earth,      58, "crushes");
  bottled("Lightning",   16,  200, lilac,       Element.lightning,  68, "shocks");
  bottled("Acid",        18,  250, lima,        Element.acid,       72, "corrodes", flow: true);
  bottled("Poison",      22,  330, sherwood,    Element.poison,     90, "infects", flow: true, fly: true);
  bottled("Shadow",      28,  440, steelGray,   Element.dark,      120, "torments",
      noun: "the darkness");
  bottled("Radiance",    34,  600, buttermilk,  Element.light,     140, "sears");
  bottled("Spirit",      40, 1000, slate,       Element.spirit,    160, "haunts", flow: true, fly: true);
}

void scrolls() {
  // Teleportation.
  category(CharCode.latinSmallLetterAWithCircumflex, stack: 20, flags: "flammable");
  tagged("magic/scroll/teleportation");
  tossable(damage: 1, range: 3, breakage: 75);
  scroll("of Sidestepping",   2, 2,  9, lilac,       () => new TeleportAction(6));
  scroll("of Phasing",        6, 3, 17, violet,      () => new TeleportAction(12));
  scroll("of Teleportation", 15, 3, 33, indigo,      () => new TeleportAction(24));
  scroll("of Disappearing",  26, 3, 47, ultramarine, () => new TeleportAction(48));

  // Detection.
  category(CharCode.latinSmallLetterAWithDiaeresis, stack: 20, flags: "flammable");
  tagged("magic/scroll/detection");
  tossable(damage: 1, range: 3, breakage: 75);
  detection("of Find Nearby Escape",  1,  2,   20, buttermilk, [DetectType.exit], range: 20);
  detection("of Find Nearby Items",   2,  2,   20, gold, [DetectType.item], range: 20);
  detection("of Detect Nearby",       3,  4,   20, lima, [DetectType.exit, DetectType.item], range: 20);

  detection("of Locate Escape",       5,  1,   20, sandal, [DetectType.exit]);
  detection("of Item Detection",     20,  2,   27, carrot, [DetectType.item]);
  detection("of Detection",          30,  4,  240, copper, [DetectType.exit, DetectType.item]);

//  CharCode.latinSmallLetterAWithGrave // scroll
//  CharCode.latinSmallLetterAWithRingAbove // scroll
}

void weapons() {
  // Bludgeons.
  category(CharCode.latinSmallLetterAWithAcute, tag: "equipment/weapon/club", verb: "hit[s]");
  tossable(breakage: 25, range: 5);
  weapon("Stick",          1,    0, persimmon,   8,   3, heft: 10);
  weapon("Cudgel",         3,    9, gunsmoke,   10,   4, heft: 11);
  weapon("Club",           6,   21, garnet,     12,   5, heft: 13);

  // Staves.
  category(CharCode.latinSmallLetterIWithAcute, tag: "equipment/weapon/staff", verb: "hit[s]");
  tossable(breakage: 35, range: 4);
  weapon("Walking Stick",        2,    9, persimmon,  10,   3, heft: 12);
  weapon("Sta[ff|aves]",         5,   38, garnet,     14,   5, heft: 14);
  weapon("Quartersta[ff|aves]", 11,  250, gunsmoke,   24,   8, heft: 16);

  // Hammers.
  category(CharCode.latinSmallLetterOWithAcute, tag: "equipment/weapon/hammer", verb: "bash[es]");
  tossable(breakage: 15, range: 5);
  weapon("Hammer",        27,  621, persimmon,  32, 12, heft: 24);
  weapon("Mattock",       39, 1225, garnet,     40, 16, heft: 28);
  weapon("War Hammer",    45, 2106, gunsmoke,   48, 20, heft: 32);

  // Maces.
  category(CharCode.latinSmallLetterUWithAcute, tag: "equipment/weapon/mace", verb: "bash[es]");
  tossable(breakage: 15, range: 4);
  weapon("Morningstar",   24,  324, gunsmoke,   26, 11, heft: 20);
  weapon("Mace",          33,  891, slate,      36, 16, heft: 25);

  // Whips.
  category(CharCode.latinSmallLetterNWithTilde, tag: "equipment/weapon/whip", verb: "whip[s]");
  tossable(breakage: 25, range: 4);
  weapon("Whip",           4,    9, persimmon,  10,  1, heft: 12);
  weapon("Chain Whip",    15,   95, gunsmoke,   18,  2, heft: 18);
  weapon("Flail",         27,  409, slate,      28,  4, heft: 27);

  // Knives.
  category(CharCode.latinCapitalLetterNWithTilde, tag: "equipment/weapon/dagger", verb: "stab[s]");
  tossable(breakage: 2, range: 8);
  weapon("Kni[fe|ves]",    3,    9, steelGray,  10, 10, heft: 10);
  weapon("Dirk",           4,   21, gunsmoke,   12, 12, heft: 10);
  weapon("Dagger",         6,   63, cornflower, 14, 14, heft: 11);
  weapon("Stiletto[es]",  10,  188, slate,      16, 16, heft: 10);
  weapon("Rondel",        20,  409, turquoise,  18, 18, heft: 11);
  weapon("Baselard",      30,  621, gold,       20, 20, heft: 12);
  // Main-guache
  // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

  category(CharCode.feminineOrdinalIndicator, tag: "equipment/weapon/sword", verb: "slash[es]");
  tossable(breakage: 20, range: 5);
  weapon("Rapier",         7,  188, steelGray,  22,  4, heft: 16);
  weapon("Shortsword",    11,  324, slate,      26,  6, heft: 18);
  weapon("Scimitar",      18,  748, gunsmoke,   34,  9, heft: 19);
  weapon("Cutlass[es]",   24, 1417, buttermilk, 42, 11, heft: 22);
  weapon("Falchion",      38, 2374, turquoise,  46, 15, heft: 24);

  /*

  // Two-handed swords.
  Bastard Sword[s]
  Longsword[s]
  Broadsword[s]
  Claymore[s]
  Flamberge[s]

  */

  // Spears.
  category(CharCode.masculineOrdinalIndicator, tag: "equipment/weapon/spear", verb: "stab[s]");
  tossable(breakage: 0, range: 9);
  weapon("Pointed Stick",  2,    0, garnet,     10,  9, heft: 11);
  weapon("Spear",          7,  137, persimmon,  24, 15, heft: 17);
  weapon("Angon",         14,  621, gunsmoke,   30, 20, heft: 19);
  weapon("Lance",         28, 2106, cornflower, 40, 28, heft: 27);
  weapon("Partisan",      35, 6833, slate,      50, 40, heft: 29);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(CharCode.invertedQuestionMark, tag: "equipment/weapon/axe", verb: "chop[s]");
  tossable(breakage: 0, range: 8);
  weapon("Hatchet",    6,  137, slate,      18, 20, heft: 14);
  tossable(breakage: 0, range: 7);
  weapon("Axe",       12,  621, persimmon,  32, 24, heft: 22);
  tossable(breakage: 0, range: 5);
  weapon("Valaska",   24, 2664, gunsmoke,   52, 26, heft: 26);
  tossable(breakage: 0, range: 4);
  weapon("Battleaxe", 40, 4866, steelGray,  64, 28, heft: 30);

  // TODO: Remove? Needs a command to use and "archery" doesn't fit.
  // Sling. In a category itself because many bow affixes don't apply to it.
  category(CharCode.reversedNotSign, tag: "equipment/weapon/sling", verb: "hit[s]");
  tossable(breakage: 15, range: 5);
  ranged("Sling",          3,   20, persimmon,  "the stone",  4, 10, 1);

  // Bows.
  category(CharCode.notSign, tag: "equipment/weapon/bow", verb: "hit[s]");
  tossable(breakage: 50, range: 5);
  ranged("Short Bow",      5,  180, persimmon,  "the arrow",  8, 12, 2);
  ranged("Longbow",       13,  600, garnet,     "the arrow", 16, 14, 3);
  ranged("Crossbow",      28, 2000, gunsmoke,   "the bolt",  24, 16, 4);
}

void bodyArmor() {
  // TODO: Make some armor throwable.
  category(CharCode.latinCapitalLetterAe, tag: "equipment/armor/cloak");
  armor("Cloak",                   3,   2, 19, ultramarine, 2);
  armor("Fur Cloak",               5,   5, 42, garnet, 3);

  category(CharCode.latinSmallLetterOWithDiaeresis, tag: "equipment/armor/body");
  armor("Cloth Shirt",             2,   2,   19, sandal,      3);
  armor("Leather Shirt",           5,   2,  126, persimmon,   6, encumbrance: 1);
  armor("Jerkin",                  7,   2,  191, gunsmoke,    8, encumbrance: 1);
  armor("Leather Armor",          10,   2,  377, garnet,     11, encumbrance: 2);
  armor("Padded Armor",           14,   2,  819, steelGray,  15, encumbrance: 3);
  armor("Studded Leather Armor",  17,   2, 1782, slate,      22, encumbrance: 4);

  category(CharCode.latinSmallLetterOWithGrave, tag: "equipment/armor/body");
  armor("Mail Hauberk",           20,   2, 2835, steelGray,  28, encumbrance: 5);
  armor("Scale Mail",             23,   2, 4212, gunsmoke,   36, encumbrance: 7);

//  CharCode.latinSmallLetterUWithCircumflex // armor

  category(CharCode.latinSmallLetterOWithCircumflex, tag: "equipment/armor/body/robe");
  armor("Robe",                    2,   2,   77, cerulean,    4);
  armor("Fur-lined Robe",          6,   4,  191, sherwood,    6);

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
  category(CharCode.latinSmallLetterIWithGrave, tag: "equipment/armor/boots");
  armor("Pair[s] of Leather Sandals",       2, 4,    6, persimmon,   1);
  armor("Pair[s] of Leather Shoes",         8, 3,   19, garnet,      2);

  category(CharCode.latinCapitalLetterAWithDiaeresis, tag: "equipment/armor/boots");
  armor("Pair[s] of Leather Boots",        14, 3,   77, persimmon,  6, encumbrance: 1);
  armor("Pair[s] of Metal Shod Boots",     22, 3,  274, slate,      8, encumbrance: 2);
  armor("Pair[s] of Greaves",              47, 4, 1017, gunsmoke,  12, encumbrance: 3);
}

void category(int glyph, {String tag, String verb, String flags, int stack: 1}) {
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
    int damage, String verb, {String noun, String flags, bool flow = false,
      bool fly = false}) {
  noun ??= "the ${name.toLowerCase()}";
  var attack = new Attack(new Noun(noun), verb, damage, 3, element);

  if (flow) {
    item("Bottled $name", depth, 2, appearance, price: price,
        use: () => new FlowSelfAction(attack, fly: fly),
        tossUse: (pos) => new FlowFromAction(attack, pos, fly: fly),
        flags: flags);

  } else {
    item("Bottled $name", depth, 2, appearance, price: price,
        use: () => new RingSelfAction(attack),
        tossUse: (pos) => new RingFromAction(attack, pos),
        flags: flags);
  }
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
      int tossDamage, {int heft}) {
  var noun = new Noun("the ${name.toLowerCase()}");
  var verb = Log.conjugate(_verb, Pronoun.it);
  var toss = new Attack(noun, verb, tossDamage, _tossRange);
  // TODO: Individual rarities.
  item(name, depth, 2, appearance,
      attack: new Attack(null, _verb, damage),
      tossAttack: toss,
      heft: heft,
      price: price);
}

void ranged(String name, int depth, int price, appearance, String noun,
    int damage, int range, int tossDamage) {
  // TODO: Figure out how heft affects this.
  var tossNoun = new Noun("the ${name.toLowerCase()}");
  var verb = Log.conjugate(_verb, Pronoun.it);
  var toss = new Attack(tossNoun, verb, tossDamage, _tossRange);
  // TODO: Individual rarities.
  item(name, depth, 3, appearance,
      attack: new Attack(new Noun(noun), "pierce[s]", damage, range),
      tossAttack: toss,
      price: price);
}

void armor(String name, int depth, int rarity, int price, appearance, int armor,
    {int encumbrance = 0}) {
  item(name, depth, rarity, appearance, armor: armor, price: price,
      encumbrance: encumbrance);
}

void item(String name, int depth, int rarity, appearance, {ItemUse use,
    TossItemUse tossUse,
    Attack attack, Attack tossAttack, int armor = 0, int price = 0,
    bool treasure = false, String flags, int encumbrance = 0, int heft = 1}) {
  // If the appearance isn't an actual glyph, it should be a color function
  // that will be applied to the current glyph.
  if (appearance is Color) {
    appearance = new Glyph.fromCharCode(_glyph, appearance, midnight);
  } else if (appearance is! Glyph) {
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
      encumbrance: encumbrance, heft: heft,
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

