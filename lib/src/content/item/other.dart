import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void litter() {
  category(CharCode.latinCapitalLetterCWithCedilla, stack: 10)
    ..tag("item")
    ..toss(damage: 3, range: 7, element: Elements.earth, breakage: 10);
  item("Rock", tan)
    ..depth(1)
    ..frequency(0.5);

  category(CharCode.latinSmallLetterUWithDiaeresis, stack: 4)
    ..tag("item")
    ..toss(damage: 2, range: 5, breakage: 30);
  item("Skull", lightCoolGray)
    ..frequency(0.25)
    ..depth(1);
}

void treasure() {
  // Coins.
  category(CharCode.centSign)
    ..tag("treasure/coin")
    ..treasure();
  item("Copper Coin", persimmon, price: 4).depth(1, to: 11);
  item("Bronze Coin", tan, price: 8).depth(7, to: 20);
  item("Silver Coin", lightAqua, price: 20).depth(11, to: 30);
  item("Electrum Coin", buttermilk, price: 50).depth(20, to: 40);
  item("Gold Coin", gold, price: 100).depth(30, to: 50);
  item("Platinum Coin", lightCoolGray, price: 300).depth(40, to: 70);

  // Bars.
  category(CharCode.dollarSign)
    ..tag("treasure/bar")
    ..treasure();
  item("Copper Bar", persimmon, price: 150).depth(35, to: 60);
  item("Bronze Bar", tan, price: 500).depth(50, to: 70);
  item("Silver Bar", lightAqua, price: 800).depth(60, to: 80);
  item("Electrum Bar", buttermilk, price: 1200).depth(70, to: 90);
  item("Gold Bar", gold, price: 2000).depth(80);
  item("Platinum Bar", lightCoolGray, price: 3000).depth(90);
}

void gems() {
  // TODO: Make a glyph for gems.
  category(CharCode.centSign)
    ..tag("item/gem")
    ..destroy(Elements.acid, chance: 50);
  // TODO: Tune price, depths, and rarity.
  item("Amethyst Shard", lavender, price: 30).depth(7, to: 27);
  item("Uncut Amethyst", lilac, price: 100).depth(27, to: 57);
  item("Faceted Amethyst", purple, price: 400).depth(57);

  item("Sapphire Shard", lightBlue, price: 34).depth(8, to: 28);
  item("Uncut Sapphire", blue, price: 125).depth(28, to: 58);
  item("Faceted Sapphire", darkBlue, price: 440).depth(58);

  item("Emerald Shard", lima, price: 37).depth(9, to: 29);
  item("Uncut Emerald", peaGreen, price: 136).depth(29, to: 59);
  item("Faceted Emerald", sherwood, price: 486).depth(59);

  item("Ruby Shard", pink, price: 41).depth(10, to: 30);
  item("Uncut Ruby", red, price: 142).depth(30, to: 60);
  item("Faceted Ruby", maroon, price: 498).depth(60);

  item("Diamond Shard", coolGray, price: 45).depth(11, to: 31);
  item("Uncut Diamond", lightCoolGray, price: 153).depth(31, to: 61);
  item("Faceted Diamond", ash, price: 507).depth(61);

  // TODO: Turquoise, Onyx, Malachite, Jade, Pearl, Opal, Fire Opal.
}

void pelts() {
  // TODO: Better pictogram than a pelt?
  category(CharCode.latinSmallLetterEWithAcute, stack: 20)
    ..tag("item/pelt")
    ..frequency(0.0)
    ..destroy(Elements.fire, chance: 80, fuel: 1);
  item("Insect Wing", violet).depth(1);
  item("Feather", lightCoolGray).depth(1);

  // category(CharCode.latinSmallLetterEWithAcute, stack: 4)
  //   ..destroy(Elements.fire, chance: 20, fuel: 3);
  // item("Fur Pelt", persimmon, 1, frequency: 1.0);
}

void food() {
  category(CharCode.invertedExclamationMark)
    ..tag("item/food")
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("Stale Biscuit", sandal)
    ..depth(1, to: 10)
    ..stack(6)
    ..food(100);
  item("Loa[f|ves] of Bread", tan, price: 4)
    ..depth(3, to: 40)
    ..stack(6)
    ..food(200);

  category(CharCode.vulgarFractionOneQuarter)
    ..tag("item/food")
    ..destroy(Elements.fire, chance: 15, fuel: 2);
  item("Chunk[s] of Meat", brown, price: 10)
    ..depth(8, to: 60)
    ..stack(4)
    ..food(400);
  // TODO: Chance of poisoning.
  // TODO: Make some monsters drop this.
  item("Piece[s] of Jerky", tan, price: 20)
    ..depth(15)
    ..stack(12)
    ..food(600);
  // TODO: More foods. Some should also cure minor conditions or cause them.
}

void lightSources() {
  category(CharCode.notSign, verb: "hit[s]")
    ..tag("equipment/light")
    ..toss(breakage: 70);

  // TODO: Ball of fire when hits toss target.
  item("Tallow Candle", sandal, price: 6)
    ..depth(1, to: 12)
    ..stack(10)
    ..toss(damage: 2, range: 8, element: Elements.fire)
    ..lightSource(level: 2, range: 5)
    ..destroy(Elements.fire, chance: 40, fuel: 20);

  // TODO: Ball of fire when hits toss target.
  item("Wax Candle", ash, price: 8)
    ..depth(4, to: 20)
    ..stack(10)
    ..toss(damage: 3, range: 8, element: Elements.fire)
    ..lightSource(level: 3, range: 7)
    ..destroy(Elements.fire, chance: 40, fuel: 25);

  // TODO: Larger ball of fire when hits toss target.
  item("Oil Lamp", brown, price: 18)
    ..depth(8, to: 30)
    ..stack(4)
    ..toss(damage: 10, range: 8, element: Elements.fire)
    ..lightSource(level: 4, range: 10)
    ..destroy(Elements.fire, chance: 50, fuel: 40);

  // TODO: Ball of fire when hits toss target.
  item("Torch[es]", tan, price: 16)
    ..depth(11, to: 45)
    ..stack(4)
    ..toss(damage: 6, range: 10, element: Elements.fire)
    ..lightSource(level: 5, range: 14)
    ..destroy(Elements.fire, chance: 60, fuel: 60);

  // TODO: Maybe allow this to be equipped and increase its radius when held?
  item("Lantern", gold, price: 78)
    ..depth(18)
    ..frequency(0.3)
    ..toss(damage: 5, range: 5, element: Elements.fire)
    ..lightSource(level: 6, range: 18);
}
