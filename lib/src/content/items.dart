import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'affixes.dart';
import 'action/condition.dart';
import 'action/detection.dart';
import 'action/flow.dart';
import 'action/heal.dart';
import 'action/ray.dart';
import 'action/teleport.dart';
import 'elements.dart';

int _sortIndex = 0;
_CategoryBuilder _category;
_ItemBuilder _builder;

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

    category(CharCode.latinCapitalLetterCWithCedilla, stack: 10)
      ..tag("item")
      ..toss(damage: 3, range: 7, element: Elements.earth, breakage: 10);
    item("Rock", 1, 1.0, persimmon);

    category(CharCode.latinSmallLetterUWithDiaeresis, stack: 4)
      ..tag("item")
      ..toss(damage: 2, range: 5, breakage: 30);
    item("Skull", 1, 1.0, gunsmoke);

//    treasures();
    pelts();
    potions();
    scrolls();
    // TODO: Rings.
    // TODO: Amulets.
    weapons();
    lightSources();
    bodyArmor();
    cloaks();
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
    // CharCode.latinSmallLetterIWithDiaeresis // ring
    // CharCode.latinSmallLetterIWithCircumflex // wand
    // CharCode.latinCapitalLetterAWithRingAbove // gloves
    // CharCode.latinCapitalLetterEWithAcute // helm
    // CharCode.latinSmallLetterAe // shield

    buildItem();
  }
}

void treasures() {
  /*
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
  // TODO: These currently have no use. Either remove them, or add crafting
  // back in.
  category(CharCode.latinSmallLetterEWithAcute, stack: 20, flags: "flammable");
  item("Flower", 1, 1.0, cornflower); // TODO: Use in recipe.
  item("Insect Wing", 1, 1.0, violet);
  item("Red Feather", 2, 1.0, brickRed); // TODO: Use in recipe.
  item("Black Feather", 2, 1.0, steelGray);
  item("Stinger", 2, 1.0, gold);

  category(CharCode.latinSmallLetterEWithAcute, stack: 4, flags: "flammable");
  item("Fur Pelt", 1, 1.0, persimmon);
  item("Fox Pelt", 2, 1.0, copper);
}

void potions() {
  // TODO: Some potions should perform an effect when thrown.

  // TODO: Make these foods?

  // Healing.
  category(CharCode.latinSmallLetterCWithCedilla, stack: 10, flags: "freezable")
    ..tag("magic/potion/healing")
    ..toss(damage: 1, range: 6, breakage: 100);
  item("Soothing Balm", 2, 1.0, salmon)..heal(48);
  item("Mending Salve", 7, 1.0, brickRed)..heal(100);
  item("Healing Poultice", 12, 1.0, maroon)..heal(200, curePoison: true);
  item("Potion[s] of Amelioration", 24, 1.0, indigo)
    ..heal(400, curePoison: true);
  item("Potion[s] of Rejuvenation", 65, 0.5, violet)
    ..heal(1000, curePoison: true);

  item("Antidote", 4, 0.5, peaGreen)..heal(0, curePoison: true);

  category(CharCode.latinSmallLetterEWithCircumflex,
      stack: 10, flags: "freezable")
    ..tag("magic/potion/resistance")
    ..toss(damage: 1, range: 6, breakage: 100);
  // TODO: Don't need to strictly have every single element here.
  item("Salve[s] of Heat Resistance", 5, 0.5, carrot)
    ..resistSalve(Elements.fire);
  item("Salve[s] of Cold Resistance", 6, 0.5, cornflower)
    ..resistSalve(Elements.cold)
    ..flags("-freezable");
  item("Salve[s] of Light Resistance", 7, 0.5, buttermilk)
    ..resistSalve(Elements.light);
  item("Salve[s] of Wind Resistance", 8, 0.5, turquoise)
    ..resistSalve(Elements.air);
  item("Salve[s] of Lightning Resistance", 9, 0.5, lilac)
    ..resistSalve(Elements.lightning);
  item("Salve[s] of Darkness Resistance", 10, 0.5, slate)
    ..resistSalve(Elements.dark);
  item("Salve[s] of Earth Resistance", 13, 0.5, persimmon)
    ..resistSalve(Elements.earth);
  item("Salve[s] of Water Resistance", 16, 0.5, ultramarine)
    ..resistSalve(Elements.water);
  item("Salve[s] of Acid Resistance", 19, 0.5, sandal)
    ..resistSalve(Elements.acid); // TODO: Better color.
  item("Salve[s] of Poison Resistance", 23, 0.5, lima)
    ..resistSalve(Elements.poison);
  item("Salve[s] of Death Resistance", 30, 0.5, violet)
    ..resistSalve(Elements.spirit);

  // TODO: "Insulation", "the Elements" and other multi-element resistances.

  // Speed.
  category(CharCode.latinSmallLetterEWithDiaeresis,
      stack: 10, flags: "freezable")
    ..tag("magic/potion/speed")
    ..toss(damage: 1, range: 6, breakage: 100);
  item("Potion[s] of Quickness", 3, 0.3, lima)
    ..use(() => new HasteAction(20, 1));
  item("Potion[s] of Alacrity", 18, 0.3, peaGreen)
    ..use(() => new HasteAction(30, 2));
  item("Potion[s] of Speed", 34, 0.25, sherwood)
    ..use(() => new HasteAction(40, 3));

  // dram, draught, elixir, philter

  // TODO: Make monsters drop these.
  // TODO: Don't need to strictly have every single element here.
  category(CharCode.latinSmallLetterEWithGrave, stack: 10, flags: "freezable")
    ..tag("magic/potion/bottled")
    ..toss(damage: 1, range: 8, breakage: 100);
  item("Bottled Wind", 4, 0.5, cornflower)
    ..flow(Elements.air, "the wind", "blasts", 20, fly: true);
  item("Bottled Ice", 7, 0.5, cerulean)
    ..ball(Elements.cold, "the cold", "freezes", 30)
    ..flags("-freezable");
  item("Bottled Fire", 11, 0.5, brickRed)
    ..flow(Elements.fire, "the fire", "burns", 44, fly: true);
  item("Bottled Ocean", 12, 0.5, ultramarine)
    ..flow(Elements.water, "the water", "drowns", 52);
  item("Bottled Earth", 13, 0.5, persimmon)
    ..ball(Elements.earth, "the dirt", "crushes", 58);
  item("Bottled Lightning", 16, 0.5, lilac)
    ..ball(Elements.lightning, "the lightning", "shocks", 68);
  item("Bottled Acid", 18, 0.5, lima)
    ..flow(Elements.acid, "the acid", "corrodes", 72);
  item("Bottled Poison", 22, 0.5, sherwood)
    ..flow(Elements.poison, "the poison", "infects", 90, fly: true);
  item("Bottled Shadow", 28, 0.5, steelGray)
    ..ball(Elements.dark, "the darkness", "torments", 120);
  item("Bottled Radiance", 34, 0.5, buttermilk)
    ..ball(Elements.light, "light", "sears", 140);
  item("Bottled Spirit", 40, 0.5, slate)
    ..flow(Elements.spirit, "the spirit", "haunts", 160, fly: true);
}

void scrolls() {
  // Teleportation.
  category(CharCode.latinSmallLetterAWithCircumflex,
      stack: 20, flags: "flammable")
    ..tag("magic/scroll/teleportation")
    ..toss(damage: 1, range: 3, breakage: 75);
  item("Scroll[s] of Sidestepping", 2, 0.5, lilac)
    ..use(() => new TeleportAction(6));
  item("Scroll[s] of Phasing", 6, 0.3, violet)
    ..use(() => new TeleportAction(12));
  item("Scroll[s] of Teleportation", 15, 0.3, indigo)
    ..use(() => new TeleportAction(24));
  item("Scroll[s] of Disappearing", 26, 0.3, ultramarine)
    ..use(() => new TeleportAction(48));

  // Detection.
  category(CharCode.latinSmallLetterAWithDiaeresis,
      stack: 20, flags: "flammable")
    ..tag("magic/scroll/detection")
    ..toss(damage: 1, range: 3, breakage: 75);
  item("Scroll[s] of Find Nearby Escape", 1, 0.5, buttermilk)
    ..detection([DetectType.exit], range: 20);
  item("Scroll[s] of Find Nearby Items", 2, 0.5, gold)
    ..detection([DetectType.item], range: 20);
  item("Scroll[s] of Detect Nearby", 3, 0.25, lima)
    ..detection([DetectType.exit, DetectType.item], range: 20);

  item("Scroll[s] of Locate Escape", 5, 1.0, sandal)
    ..detection([DetectType.exit]);
  item("Scroll[s] of Item Detection", 20, 0.5, carrot)
    ..detection([DetectType.item]);
  item("Scroll[s] of Detection", 30, 0.25, copper)
    ..detection([DetectType.exit, DetectType.item]);

//  CharCode.latinSmallLetterAWithGrave // scroll
//  CharCode.latinSmallLetterAWithRingAbove // scroll
}

void weapons() {
  // https://en.wikipedia.org/wiki/List_of_mythological_objects#Weapons

  // Bludgeons.
  category(CharCode.latinSmallLetterAWithAcute, verb: "hit[s]")
    ..tag("equipment/weapon/club")
    ..toss(breakage: 25, range: 5);
  item("Stick", 1, 0.5, persimmon)
    ..weapon(8, heft: 10)
    ..toss(damage: 3);
  item("Cudgel", 3, 0.5, gunsmoke)
    ..weapon(10, heft: 11)
    ..toss(damage: 4);
  item("Club", 6, 0.5, garnet)
    ..weapon(12, heft: 13)
    ..toss(damage: 5);

  // Staves.
  category(CharCode.latinSmallLetterIWithAcute, verb: "hit[s]")
    ..tag("equipment/weapon/staff")
    ..toss(breakage: 35, range: 4);
  item("Walking Stick", 2, 0.5, persimmon)
    ..weapon(10, heft: 12)
    ..toss(damage: 3);
  item("Sta[ff|aves]", 5, 0.5, garnet)
    ..weapon(14, heft: 14)
    ..toss(damage: 5);
  item("Quartersta[ff|aves]", 11, 0.5, gunsmoke)
    ..weapon(24, heft: 16)
    ..toss(damage: 8);

  // Hammers.
  category(CharCode.latinSmallLetterOWithAcute, verb: "bash[es]")
    ..tag("equipment/weapon/hammer")
    ..toss(breakage: 15, range: 5);
  item("Hammer", 27, 0.5, persimmon)
    ..weapon(32, heft: 24)
    ..toss(damage: 12);
  item("Mattock", 39, 0.5, garnet)
    ..weapon(40, heft: 28)
    ..toss(damage: 16);
  item("War Hammer", 45, 0.5, gunsmoke)
    ..weapon(48, heft: 32)
    ..toss(damage: 20);

  // Maces.
  category(CharCode.latinSmallLetterUWithAcute, verb: "bash[es]")
    ..tag("equipment/weapon/mace")
    ..toss(breakage: 15, range: 4);
  item("Morningstar", 24, 0.5, gunsmoke)
    ..weapon(26, heft: 20)
    ..toss(damage: 11);
  item("Mace", 33, 0.5, slate)
    ..weapon(36, heft: 25)
    ..toss(damage: 16);

  // Whips.
  category(CharCode.latinSmallLetterNWithTilde, verb: "whip[s]")
    ..tag("equipment/weapon/whip")
    ..toss(breakage: 25, range: 4);
  item("Whip", 4, 0.5, persimmon)
    ..weapon(10, heft: 12)
    ..toss(damage: 1);
  item("Chain Whip", 15, 0.5, gunsmoke)
    ..weapon(18, heft: 18)
    ..toss(damage: 2);
  item("Flail", 27, 0.5, slate)
    ..weapon(28, heft: 27)
    ..toss(damage: 4);

  // Knives.
  category(CharCode.latinCapitalLetterNWithTilde, verb: "stab[s]")
    ..tag("equipment/weapon/dagger")
    ..toss(breakage: 2, range: 8);
  item("Kni[fe|ves]", 3, 0.5, steelGray)
    ..weapon(8, heft: 10)
    ..toss(damage: 8);
  item("Dirk", 4, 0.5, gunsmoke)
    ..weapon(10, heft: 10)
    ..toss(damage: 10);
  item("Dagger", 6, 0.5, cornflower)
    ..weapon(12, heft: 11)
    ..toss(damage: 12);
  item("Stiletto[es]", 10, 0.5, slate)
    ..weapon(14, heft: 10)
    ..toss(damage: 14);
  item("Rondel", 20, 0.5, turquoise)
    ..weapon(16, heft: 11)
    ..toss(damage: 16);
  item("Baselard", 30, 0.5, gold)
    ..weapon(18, heft: 12)
    ..toss(damage: 18);
  // Main-guache
  // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

  category(CharCode.feminineOrdinalIndicator, verb: "slash[es]")
    ..tag("equipment/weapon/sword")
    ..toss(breakage: 20, range: 5);
  item("Rapier", 7, 0.5, steelGray)
    ..weapon(20, heft: 16)
    ..toss(damage: 4);
  item("Shortsword", 11, 0.5, slate)
    ..weapon(22, heft: 17)
    ..toss(damage: 6);
  item("Scimitar", 18, 0.5, gunsmoke)
    ..weapon(24, heft: 18)
    ..toss(damage: 9);
  item("Cutlass[es]", 24, 0.5, buttermilk)
    ..weapon(26, heft: 19)
    ..toss(damage: 11);
  item("Falchion", 38, 0.5, turquoise)
    ..weapon(28, heft: 20)
    ..toss(damage: 15);

  /*

  // Two-handed swords.
  Bastard Sword[s]
  Longsword[s]
  Broadsword[s]
  Claymore[s]
  Flamberge[s]

  */

  // Spears.
  category(CharCode.masculineOrdinalIndicator, verb: "stab[s]")
    ..tag("equipment/weapon/spear")
    ..toss(range: 9);
  item("Pointed Stick", 2, 0.5, garnet)
    ..weapon(10, heft: 11)
    ..toss(damage: 9);
  item("Spear", 7, 0.5, persimmon)
    ..weapon(16, heft: 17)
    ..toss(damage: 15);
  item("Angon", 14, 0.5, gunsmoke)
    ..weapon(20, heft: 19)
    ..toss(damage: 20);

  category(CharCode.masculineOrdinalIndicator, verb: "stab[s]")
    ..tag("equipment/weapon/polearm")
    ..toss(range: 4);
  item("Lance", 28, 0.5, cornflower)
    ..weapon(24, heft: 27)
    ..toss(damage: 20);
  item("Partisan", 35, 0.5, slate)
    ..weapon(30, heft: 29)
    ..toss(damage: 26);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(CharCode.invertedQuestionMark, verb: "chop[s]")
    ..tag("equipment/weapon/axe");
  item("Hatchet", 6, 0.5, slate)
    ..weapon(18, heft: 14)
    ..toss(damage: 20, range: 8);
  item("Axe", 12, 0.5, persimmon)
    ..weapon(25, heft: 22)
    ..toss(damage: 24, range: 7);
  item("Valaska", 24, 0.5, gunsmoke)
    ..weapon(32, heft: 26)
    ..toss(damage: 26, range: 5);
  item("Battleaxe", 40, 0.5, steelGray)
    ..weapon(39, heft: 30)
    ..toss(damage: 28, range: 4);

  // Bows.
  category(CharCode.reversedNotSign, verb: "hit[s]")
    ..tag("equipment/weapon/bow")
    ..toss(breakage: 50, range: 5);
  item("Short Bow", 5, 0.3, persimmon)
    ..ranged("the arrow", damage: 8, range: 12)
    ..toss(damage: 2);
  item("Longbow", 13, 0.3, garnet)
    ..ranged("the arrow", damage: 16, range: 14)
    ..toss(damage: 3);
  item("Crossbow", 28, 0.3, gunsmoke)
    ..ranged("the bolt", damage: 24, range: 16)
    ..toss(damage: 4);
}

void lightSources() {
  category(CharCode.notSign, verb: "hit[s]")
    ..tag("item/light")
    ..toss(breakage: 70);

  // TODO: Ball of fire when hits toss target.
  item("Candle", 1, 1.0, sandal)
    ..stack(10)
    ..toss(damage: 2, range: 4, element: Elements.fire)
    ..light(2)
    ..ball(Elements.light, "light", "sears", 1, range: 4);

  item("Torch[es]", 3, 1.0, persimmon)
    ..stack(4)
    ..toss(damage: 6, range: 6, element: Elements.fire)
    ..light(4)
    ..ball(Elements.light, "light", "sears", 4, range: 8);

  // TODO: Maybe allow this to be equipped and increase its radius when held?
  item("Lantern", 10, 0.3, persimmon)
    ..toss(damage: 5, range: 4, element: Elements.fire)
    ..light(6);
}

void bodyArmor() {
  // TODO: Make some armor throwable.
  // Robes.
  category(CharCode.latinSmallLetterOWithCircumflex)
    ..tag("equipment/armor/body/robe");
  item("Robe", 2, 0.5, cerulean)..armor(4);
  item("Fur-lined Robe", 6, 0.25, sherwood)..armor(6);

  // Soft armor.
  category(CharCode.latinSmallLetterOWithDiaeresis)
    ..tag("equipment/armor/body");
  item("Cloth Shirt", 2, 0.5, sandal)..armor(3);
  item("Leather Shirt", 5, 0.5, persimmon)..armor(6, weight: 1);
  item("Jerkin", 7, 0.5, gunsmoke)..armor(8, weight: 1);
  item("Leather Armor", 10, 0.5, garnet)..armor(11, weight: 2);
  item("Padded Armor", 14, 0.5, steelGray)..armor(15, weight: 3);
  item("Studded Leather Armor", 17, 0.5, slate)..armor(22, weight: 4);

  // Mail armor.
  category(CharCode.latinSmallLetterOWithGrave)..tag("equipment/armor/body");
  item("Mail Hauberk", 20, 0.5, steelGray)..armor(28, weight: 5);
  item("Scale Mail", 23, 0.5, gunsmoke)..armor(36, weight: 7);

//  CharCode.latinSmallLetterUWithCircumflex // armor

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

void cloaks() {
  category(CharCode.latinCapitalLetterAe)..tag("equipment/armor/cloak");
  item("Cloak", 3, 0.5, ultramarine)..armor(2);
  item("Fur Cloak", 5, 0.2, garnet)..armor(3);
}

void boots() {
  category(CharCode.latinSmallLetterIWithGrave)..tag("equipment/armor/boots");
  item("Pair[s] of Leather Sandals", 2, 0.24, persimmon)..armor(1);
  item("Pair[s] of Leather Shoes", 8, 0.3, garnet)..armor(2);

  category(CharCode.latinCapitalLetterAWithDiaeresis)
    ..tag("equipment/armor/boots");
  item("Pair[s] of Leather Boots", 14, 0.3, persimmon)..armor(6, weight: 1);
  item("Pair[s] of Metal Shod Boots", 22, 0.3, slate)..armor(8, weight: 2);
  item("Pair[s] of Greaves", 47, 0.25, gunsmoke)..armor(12, weight: 3);
}

_CategoryBuilder category(int glyph, {String verb, String flags, int stack}) {
  buildItem();

  _category = new _CategoryBuilder();

  _category._glyph = glyph;
  _category._verb = verb;
  if (flags != null) {
    _category.flags(flags);
  }

  _category._maxStack = stack;

  return _category;
}

_ItemBuilder item(String name, int depth, double frequency, appearance) {
  buildItem();

  _builder = new _ItemBuilder();
  _builder._name = name;
  _builder._depth = depth;
  _builder._frequency = frequency;
  _builder._appearance = appearance;

  return _builder;
}

class _BaseBuilder {
  final List<String> _flags = [];

  int _maxStack;
  Element _tossElement;
  int _tossDamage;
  int _tossRange;
  TossItemUse _tossUse;
  int _emanation;

  /// Percent chance of objects in the current category breaking when thrown.
  int _breakage;

  void stack(int stack) {
    _maxStack = stack;
  }

  void flags(String flags) {
    if (flags == null) return;
    _flags.addAll(flags.split(" "));
  }

  /// Makes items in the category throwable.
  void toss({int damage, Element element, int range, int breakage}) {
    _tossDamage = damage;
    _tossElement = element;
    _tossRange = range;
    _breakage = breakage;
  }

  void tossUse(TossItemUse use) {
    _tossUse = use;
  }

  void light(int level) {
    _emanation = level;
  }
}

class _CategoryBuilder extends _BaseBuilder {
  /// The current glyph's character code. Any items defined will use this.
  int _glyph;

  String _equipSlot;

  String _weaponType;
  String _tag;
  String _verb;

  void tag(String tagPath) {
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
  }
}

class _ItemBuilder extends _BaseBuilder {
  // category too.
  Object _appearance;
  double _frequency;
  ItemUse _use;
  Attack _attack;
  int _weight;
  int _heft;
  int _armor;

  String _name;
  int _depth;

  void armor(int armor, {int weight}) {
    _armor = armor;
    _weight = weight;
  }

  void weapon(int damage, {int heft, Element element}) {
    _attack = new Attack(null, _category._verb, damage, null, element);
    _heft = heft;
  }

  void ranged(String noun, {int damage, int range}) {
    _attack = new Attack(new Noun(noun), "pierce[s]", damage, range);
    // TODO: Make this per-item once it does something.
    _heft = 1;
  }

  void use(ItemUse use) {
    _use = use;
  }

  void detection(List<DetectType> types, {int range}) {
    use(() => new DetectAction(types, range));
  }

  void resistSalve(Element element) {
    use(() => new ResistAction(40, element));
  }

  // TODO: Take list of conditions to cure?
  void heal(int amount, {bool curePoison: false}) {
    use(() => new HealAction(amount, curePoison: curePoison));
  }

  /// Sets a use and toss use that creates an expanding ring of elemental
  /// damage.
  void ball(Element element, String noun, String verb, int damage,
      {int range}) {
    var attack = new Attack(new Noun(noun), verb, damage, range ?? 3, element);

    use(() => new RingSelfAction(attack));
    tossUse((pos) => new RingFromAction(attack, pos));
  }

  /// Sets a use and toss use that creates an flow of elemental damage.
  void flow(Element element, String noun, String verb, int damage,
      {int range = 3, bool fly = false}) {
    var attack = new Attack(new Noun(noun), verb, damage, range, element);

    var motilities = new MotilitySet([Motility.walk]);
    if (fly) motilities.add(Motility.fly);

    use(() => new FlowSelfAction(attack, motilities));
    tossUse((pos) => new FlowFromAction(attack, pos, motilities));
  }
}

void buildItem() {
  if (_builder == null) return;

  // If the appearance isn't an actual glyph, it should be a color function
  // that will be applied to the current glyph.
  var appearance = _builder._appearance;
  if (appearance is Color) {
    appearance = new Glyph.fromCharCode(_category._glyph, appearance, midnight);
  } else if (appearance is! Glyph) {
    appearance = appearance(_category._glyph);
  }

  Toss toss;
  var tossDamage = _builder._tossDamage ?? _category._tossDamage;
  if (tossDamage != null) {
    var noun = new Noun("the ${_builder._name.toLowerCase()}");
    var verb = "hits";
    if (_category._verb != null) {
      verb = Log.conjugate(_category._verb, Pronoun.it);
    }

    var range = _builder._tossRange ?? _category._tossRange;
    assert(range != null);
    var element =
        _builder._tossElement ?? _category._tossElement ?? Element.none;
    var use = _builder._tossUse ?? _category._tossUse;
    var breakage = _category._breakage ?? _builder._breakage ?? 0;

    var tossAttack = new Attack(noun, verb, tossDamage, range, element);
    toss = new Toss(breakage, tossAttack, use);
  }

  var itemType = new ItemType(
      _builder._name,
      appearance,
      _builder._depth,
      _sortIndex++,
      _category._equipSlot,
      _category._weaponType,
      _builder._use,
      _builder._attack,
      toss,
      _builder._armor ?? 0,
      0,
      _builder._maxStack ?? _category._maxStack ?? 1,
      weight: _builder._weight ?? 0,
      heft: _builder._heft ?? 0,
      emanation: _builder._emanation ?? _category._emanation);

  // Use the tags (if any) to figure out which slot it can be equipped in.
  itemType.flags.addAll(_category._flags);
  if (_builder._flags != null) {
    for (var flag in _builder._flags) {
      if (flag.startsWith("-")) {
        itemType.flags.remove(flag.substring(1));
      } else {
        itemType.flags.add(flag);
      }
    }
  }

  Items.types.add(itemType.name, itemType, itemType.depth, _builder._frequency,
      _category._tag);

  _builder = null;
}
