import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void litter() {
  category(CharCode.latinCapitalLetterCWithCedilla, stack: 10)
    ..tag("item")
    ..toss(damage: 3, range: 7, element: Elements.earth, breakage: 10);
  item("Rock", persimmon, frequency: 0.5)..depth(1);

  category(CharCode.latinSmallLetterUWithDiaeresis, stack: 4)
    ..tag("item")
    ..toss(damage: 2, range: 5, breakage: 30);
  item("Skull", gunsmoke, frequency: 0.5)..depth(1);
}

void treasure() {
  // Coins.
  category(CharCode.centSign)
    ..tag("treasure/coin")
    ..treasure();
  item("Copper Coins", copper, price: 4)..depth(1, to: 11);
  item("Bronze Coins", persimmon, price: 8)..depth(7, to: 20);
  item("Silver Coins", turquoise, price: 20)..depth(11, to: 30);
  item("Electrum Coins", buttermilk, price: 50)..depth(20, to: 40);
  item("Gold Coins", gold, price: 100)..depth(30, to: 50);
  item("Platinum Coins", gunsmoke, price: 300)..depth(40, to: 70);

  // Bars.
  category(CharCode.dollarSign)
    ..tag("treasure/bar")
    ..treasure();
  item("Copper Bar", copper, price: 150)..depth(35, to: 60);
  item("Bronze Bar", persimmon, price: 500)..depth(50, to: 70);
  item("Silver Bar", turquoise, price: 800)..depth(60, to: 80);
  item("Electrum Bar", buttermilk, price: 1200)..depth(70, to: 90);
  item("Gold Bar", gold, price: 2000)..depth(80);
  item("Platinum Bar", gunsmoke, price: 3000)..depth(90);

/*
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
  /*
  category(CharCode.latinSmallLetterEWithAcute, stack: 20)
    ..destroy(Elements.fire, chance: 40, fuel: 1);
  item("Flower", cornflower, 1, frequency: 1.0); // TODO: Use in recipe.
  item("Insect Wing", violet, 1, frequency: 1.0);
  item("Red Feather", brickRed, 2, frequency: 1.0); // TODO: Use in recipe.
  item("Black Feather", steelGray, 2, frequency: 1.0);

  category(CharCode.latinSmallLetterEWithAcute, stack: 4)
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("Fur Pelt", persimmon, 1, frequency: 1.0);
  */
}

void food() {
  category(CharCode.invertedExclamationMark)
    ..tag("item/food")
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("Stale Biscuit", sandal, frequency: 1.0)
    ..depth(1, to: 10)
    ..stack(6)
    ..food(100);
  item("Loa[f|ves] of Bread", persimmon, frequency: 1.0, price: 4)
    ..depth(3, to: 40)
    ..stack(6)
    ..food(200);

  category(CharCode.vulgarFractionOneQuarter)
    ..tag("item/food")
    ..destroy(Elements.fire, chance: 15, fuel: 2);
  item("Chunk[s] of Meat", garnet, frequency: 1.0, price: 10)
    ..depth(8)
    ..stack(4)
    ..food(400);
  // TODO: Chance of poisoning.
  // TODO: Make some monsters drop this.
  item("Piece[s] of Jerky", persimmon, frequency: 1.0, price: 20)
    ..depth(10)
    ..stack(12)
    ..food(600);
  // TODO: More foods. Some should also cure minor conditions or cause them.
}

void lightSources() {
  category(CharCode.notSign, verb: "hit[s]")
    ..tag("item/light")
    ..toss(breakage: 70);

  // TODO: Ball of fire when hits toss target.
  item("Tallow Candle", sandal, frequency: 1.0, price: 6)
    ..depth(1, to: 12)
    ..stack(10)
    ..toss(damage: 2, range: 8, element: Elements.fire)
    ..lightSource(level: 2, range: 8)
    ..destroy(Elements.fire, chance: 40, fuel: 20);

  // TODO: Ball of fire when hits toss target.
  item("Wax Candle", ash, frequency: 1.0, price: 8)
    ..depth(4, to: 20)
    ..stack(10)
    ..toss(damage: 3, range: 8, element: Elements.fire)
    ..lightSource(level: 3, range: 10)
    ..destroy(Elements.fire, chance: 40, fuel: 25);

  // TODO: Larger ball of fire when hits toss target.
  item("Oil Lamp", garnet, frequency: 1.0, price: 18)
    ..depth(8, to: 30)
    ..stack(4)
    ..toss(damage: 10, range: 8, element: Elements.fire)
    ..lightSource(level: 4, range: 13)
    ..destroy(Elements.fire, chance: 50, fuel: 40);

  // TODO: Ball of fire when hits toss target.
  item("Torch[es]", persimmon, frequency: 1.0, price: 16)
    ..depth(11, to: 45)
    ..stack(4)
    ..toss(damage: 6, range: 10, element: Elements.fire)
    ..lightSource(level: 5, range: 18)
    ..destroy(Elements.fire, chance: 60, fuel: 60);

  // TODO: Maybe allow this to be equipped and increase its radius when held?
  item("Lantern", gold, frequency: 0.3, price: 78)
    ..depth(18)
    ..toss(damage: 5, range: 5, element: Elements.fire)
    ..lightSource(level: 6, range: 24);
}
