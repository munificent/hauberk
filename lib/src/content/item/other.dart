import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void litter() {
  category(CharCode.latinCapitalLetterCWithCedilla, stack: 10)
    ..tag("item")
    ..toss(damage: 3, range: 7, element: Elements.earth, breakage: 10);
  item("Rock", 1, persimmon, frequency: 1.0);

  category(CharCode.latinSmallLetterUWithDiaeresis, stack: 4)
    ..tag("item")
    ..toss(damage: 2, range: 5, breakage: 30);
  item("Skull", 1, gunsmoke, frequency: 1.0);
}

void treasure() {
// TODO: Figure out what to do with these now that there is no money. Use them
// as runes for enchanting equipment?
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
  category(CharCode.latinSmallLetterEWithAcute, stack: 20)
    ..destroy(Elements.fire, chance: 40, fuel: 1);
  item("Flower", 1, cornflower, frequency: 1.0); // TODO: Use in recipe.
  item("Insect Wing", 1, violet, frequency: 1.0);
  item("Red Feather", 2, brickRed, frequency: 1.0); // TODO: Use in recipe.
  item("Black Feather", 2, steelGray, frequency: 1.0);

  category(CharCode.latinSmallLetterEWithAcute, stack: 4)
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("Fur Pelt", 1, persimmon, frequency: 1.0);
  item("Fox Pelt", 2, copper, frequency: 1.0);
}

void food() {
  category(CharCode.invertedExclamationMark)
    ..tag("item/food")
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("Loa[f|ves] of Bread", 1, sandal, frequency: 1.0, price: 4)
    ..stack(6)
    ..food(200);
  // TODO: More foods. Some should also cure minor conditions or cause them.
  // Meat glyph: CharCode.vulgarFractionOneQuarter
}

void lightSources() {
  category(CharCode.notSign, verb: "hit[s]")
    ..tag("item/light")
    ..toss(breakage: 70);

  // TODO: Ball of fire when hits toss target.
  item("Tallow Candle", 1, sandal, frequency: 1.0, price: 6)
    ..stack(10)
    ..toss(damage: 2, range: 8, element: Elements.fire)
    ..lightSource(level: 2, range: 8)
    ..destroy(Elements.fire, chance: 40, fuel: 20);

  // TODO: Ball of fire when hits toss target.
  item("Wax Candle", 4, ash, frequency: 1.0, price: 8)
    ..stack(10)
    ..toss(damage: 3, range: 8, element: Elements.fire)
    ..lightSource(level: 3, range: 10)
    ..destroy(Elements.fire, chance: 40, fuel: 25);

  // TODO: Larger ball of fire when hits toss target.
  item("Oil Lamp", 4, garnet, frequency: 1.0, price: 18)
    ..stack(4)
    ..toss(damage: 10, range: 8, element: Elements.fire)
    ..lightSource(level: 4, range: 13)
    ..destroy(Elements.fire, chance: 50, fuel: 40);

  // TODO: Ball of fire when hits toss target.
  item("Torch[es]", 8, persimmon, frequency: 1.0, price: 16)
    ..stack(4)
    ..toss(damage: 6, range: 10, element: Elements.fire)
    ..lightSource(level: 5, range: 18)
    ..destroy(Elements.fire, chance: 60, fuel: 60);

  // TODO: Maybe allow this to be equipped and increase its radius when held?
  item("Lantern", 15, gold, frequency: 0.3, price: 78)
    ..toss(damage: 5, range: 5, element: Elements.fire)
    ..lightSource(level: 6);
}
