import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void litter() {
  category(CharCode.latinCapitalLetterCWithCedilla, stack: 10)
    ..tag("item")
    ..toss(damage: 3, range: 7, element: Elements.earth, breakage: 10);
  item("Rock", 1, 1.0, persimmon);

  category(CharCode.latinSmallLetterUWithDiaeresis, stack: 4)
    ..tag("item")
    ..toss(damage: 2, range: 5, breakage: 30);
  item("Skull", 1, 1.0, gunsmoke);
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
  category(CharCode.latinSmallLetterEWithAcute, stack: 20, flags: "flammable");
  item("Flower", 1, 1.0, cornflower); // TODO: Use in recipe.
  item("Insect Wing", 1, 1.0, violet);
  item("Red Feather", 2, 1.0, brickRed); // TODO: Use in recipe.
  item("Black Feather", 2, 1.0, steelGray);

  category(CharCode.latinSmallLetterEWithAcute, stack: 4, flags: "flammable");
  item("Fur Pelt", 1, 1.0, persimmon);
  item("Fox Pelt", 2, 1.0, copper);
}

void lightSources() {
  category(CharCode.notSign, verb: "hit[s]")
    ..tag("item/light")
    ..toss(breakage: 70);

  // TODO: Ball of fire when hits toss target.
  item("Tallow Candle", 1, 1.0, sandal)
    ..stack(10)
    ..toss(damage: 2, range: 8, element: Elements.fire)
    ..light(4)
    ..ball(Elements.light, "light", "sears", 1, range: 7);

  // TODO: Ball of fire when hits toss target.
  item("Wax Candle", 4, 1.0, ash)
    ..stack(10)
    ..toss(damage: 3, range: 8, element: Elements.fire)
    ..light(5)
    ..ball(Elements.light, "light", "sears", 2, range: 9);

  // TODO: Larger ball of fire when hits toss target.
  item("Oil Lamp", 4, 1.0, garnet)
    ..stack(4)
    ..toss(damage: 10, range: 8, element: Elements.fire)
    ..light(6)
    ..ball(Elements.light, "light", "sears", 2, range: 11);

  // TODO: Ball of fire when hits toss target.
  item("Torch[es]", 8, 1.0, persimmon)
    ..stack(4)
    ..toss(damage: 6, range: 10, element: Elements.fire)
    ..light(7)
    ..ball(Elements.light, "light", "sears", 4, range: 15);

  // TODO: Maybe allow this to be equipped and increase its radius when held?
  item("Lantern", 15, 0.3, gold)
    ..toss(damage: 5, range: 5, element: Elements.fire)
    ..light(8);
}
