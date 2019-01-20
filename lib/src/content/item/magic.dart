import 'package:malison/malison.dart';

import '../../hues.dart';
import '../action/detection.dart';
import '../elements.dart';
import 'builder.dart';

void potions() {
  // TODO: Max depths for more of these.
  // TODO: Some potions should perform an effect when thrown.

  // Healing.
  category(CharCode.latinSmallLetterCWithCedilla, stack: 10)
    ..tag("magic/potion/healing")
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  item("Soothing Balm", pink, frequency: 1.0, price: 10)
    ..depth(2, to: 30)
    ..heal(48);
  item("Mending Salve", red, frequency: 1.0, price: 30)
    ..depth(20, to: 40)
    ..heal(100);
  item("Healing Poultice", maroon, frequency: 1.0, price: 80)
    ..depth(30)
    ..heal(200, curePoison: true);
  item("Potion[s] of Amelioration", violet, frequency: 1.0, price: 220)
    ..depth(60)
    ..heal(400, curePoison: true);
  item("Potion[s] of Rejuvenation", purple, frequency: 0.5, price: 1000)
    ..depth(80)
    ..heal(1000, curePoison: true);

  item("Antidote", peaGreen, frequency: 1.0, price: 20)
    ..depth(2)
    ..heal(0, curePoison: true);

  category(CharCode.latinSmallLetterEWithCircumflex, stack: 10)
    ..tag("magic/potion/resistance")
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  // TODO: Don't need to strictly have every single element here.
  // TODO: Have stronger versions that appear at higher depths.
  item("Salve[s] of Heat Resistance", carrot, frequency: 0.5, price: 50)
    ..depth(5)
    ..resistSalve(Elements.fire);
  // TODO: Make not freezable?
  item("Salve[s] of Cold Resistance", lightBlue, frequency: 0.5, price: 55)
    ..depth(6)
    ..resistSalve(Elements.cold);
  item("Salve[s] of Light Resistance", buttermilk, frequency: 0.5, price: 60)
    ..depth(7)
    ..resistSalve(Elements.light);
  item("Salve[s] of Wind Resistance", lightAqua, frequency: 0.5, price: 65)
    ..depth(8)
    ..resistSalve(Elements.air);
  item("Salve[s] of Lightning Resistance", lilac, frequency: 0.5, price: 70)
    ..depth(9)
    ..resistSalve(Elements.lightning);
  item("Salve[s] of Darkness Resistance", coolGray, frequency: 0.5, price: 75)
    ..depth(10)
    ..resistSalve(Elements.dark);
  item("Salve[s] of Earth Resistance", tan, frequency: 0.5, price: 80)
    ..depth(13)
    ..resistSalve(Elements.earth);
  item("Salve[s] of Water Resistance", darkBlue, frequency: 0.5, price: 85)
    ..depth(16)
    ..resistSalve(Elements.water);
  item("Salve[s] of Acid Resistance", sandal, frequency: 0.5, price: 90)
    ..depth(19)
    ..resistSalve(Elements.acid); // TODO: Better color.
  item("Salve[s] of Poison Resistance", lima, frequency: 0.5, price: 95)
    ..depth(23)
    ..resistSalve(Elements.poison);
  item("Salve[s] of Death Resistance", purple, frequency: 0.5, price: 100)
    ..depth(30)
    ..resistSalve(Elements.spirit);

  // TODO: "Insulation", "the Elements" and other multi-element resistances.

  // Speed.
  category(CharCode.latinSmallLetterEWithDiaeresis, stack: 10)
    ..tag("magic/potion/speed")
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  item("Potion[s] of Quickness", lima, frequency: 0.3, price: 25)
    ..depth(3, to: 30)
    ..haste(1, 40);
  item("Potion[s] of Alacrity", peaGreen, frequency: 0.3, price: 60)
    ..depth(18, to: 50)
    ..haste(2, 60);
  item("Potion[s] of Speed", sherwood, frequency: 0.25, price: 150)
    ..depth(34)
    ..haste(3, 100);

  // dram, draught, elixir, philter

  // TODO: Don't need to strictly have every single element here.
  category(CharCode.latinSmallLetterEWithGrave, stack: 10)
    ..tag("magic/potion/bottled")
    ..toss(damage: 1, range: 8, breakage: 100)
    ..destroy(Elements.cold, chance: 15);
  item("Bottled Wind", lightBlue, frequency: 0.5, price: 100)
    ..depth(4)
    ..flow(Elements.air, "the wind", "blasts", 20, fly: true);
  // TODO: Make not freezable?
  item("Bottled Ice", blue, frequency: 0.5, price: 120)
    ..depth(7)
    ..ball(Elements.cold, "the cold", "freezes", 30);
  item("Bottled Fire", red, frequency: 0.5, price: 140)
    ..depth(11)
    ..flow(Elements.fire, "the fire", "burns", 44, fly: true);
  item("Bottled Ocean", darkBlue, frequency: 0.5, price: 160)
    ..depth(12)
    ..flow(Elements.water, "the water", "drowns", 52);
  item("Bottled Earth", tan, frequency: 0.5, price: 180)
    ..depth(13)
    ..ball(Elements.earth, "the dirt", "crushes", 58);
  item("Bottled Lightning", lilac, frequency: 0.5, price: 200)
    ..depth(16)
    ..ball(Elements.lightning, "the lightning", "shocks", 68);
  item("Bottled Acid", lima, frequency: 0.5, price: 220)
    ..depth(18)
    ..flow(Elements.acid, "the acid", "corrodes", 72);
  item("Bottled Poison", sherwood, frequency: 0.5, price: 240)
    ..depth(22)
    ..flow(Elements.poison, "the poison", "infects", 90, fly: true);
  item("Bottled Shadow", darkCoolGray, frequency: 0.5, price: 260)
    ..depth(28)
    ..ball(Elements.dark, "the darkness", "torments", 120);
  item("Bottled Radiance", buttermilk, frequency: 0.5, price: 280)
    ..depth(34)
    ..ball(Elements.light, "light", "sears", 140);
  item("Bottled Spirit", coolGray, frequency: 0.5, price: 300)
    ..depth(40)
    ..flow(Elements.spirit, "the spirit", "haunts", 160, fly: true);
}

void scrolls() {
  // TODO: Consider adding "complexity" to items. Like heft but for intellect,
  // it's a required intellect level needed to use the item successfully. An
  // item too complex for the user is likely to fail.

  // Teleportation.
  category(CharCode.latinSmallLetterAWithCircumflex, stack: 20)
    ..tag("magic/scroll/teleportation")
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Scroll[s] of Sidestepping", lilac, frequency: 0.5, price: 16)
    ..depth(2)
    ..teleport(8);
  item("Scroll[s] of Phasing", purple, frequency: 0.3, price: 28)
    ..depth(6)
    ..teleport(14);
  item("Scroll[s] of Teleportation", violet, frequency: 0.3, price: 52)
    ..depth(15)
    ..teleport(28);
  item("Scroll[s] of Disappearing", darkBlue, frequency: 0.3, price: 74)
    ..depth(26)
    ..teleport(54);

  // Detection.
  category(CharCode.latinSmallLetterAWithDiaeresis, stack: 20)
    ..tag("magic/scroll/detection")
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Scroll[s] of Find Nearby Escape", buttermilk, frequency: 0.5, price: 12)
    ..depth(1, to: 10)
    ..detection([DetectType.exit], range: 20);
  item("Scroll[s] of Find Nearby Items", gold, frequency: 0.5, price: 24)
    ..depth(2, to: 16)
    ..detection([DetectType.item], range: 20);
  item("Scroll[s] of Detect Nearby", lima, frequency: 0.25, price: 36)
    ..depth(3, to: 24)
    ..detection([DetectType.exit, DetectType.item], range: 20);

  item("Scroll[s] of Locate Escape", sandal, frequency: 1.0, price: 28)
    ..depth(6)
    ..detection([DetectType.exit]);
  item("Scroll[s] of Item Detection", carrot, frequency: 0.5, price: 64)
    ..depth(12)
    ..detection([DetectType.item]);
  item("Scroll[s] of Detection", persimmon, frequency: 0.25, price: 124)
    ..depth(18)
    ..detection([DetectType.exit, DetectType.item]);

  // Mapping.
  category(CharCode.latinSmallLetterAWithGrave, stack: 20)
    ..tag("magic/scroll/mapping")
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 15, fuel: 5);
  item("Adventurer's Map", sherwood, frequency: 0.25, price: 70)
    ..depth(10, to: 50)
    ..mapping(16);
  item("Explorer's Map", peaGreen, frequency: 0.25, price: 160)
    ..depth(30, to: 70)
    ..mapping(32);
  item("Cartographer's Map", mint, frequency: 0.25, price: 240)
    ..depth(50, to: 90)
    ..mapping(64);
  item("Wizard's Map", aqua, frequency: 0.25, price: 360)
    ..depth(70)
    ..mapping(200, illuminate: true);

//  CharCode.latinSmallLetterAWithRingAbove // scroll
}

void spellBooks() {
  category(CharCode.vulgarFractionOneHalf, stack: 3)
    ..tag("magic/book/sorcery")
    ..toss(damage: 1, range: 3, breakage: 25)
    ..destroy(Elements.fire, chance: 5, fuel: 10);
  item('Spellbook "Elemental Primer"', maroon, frequency: 0.05, price: 100)
    ..depth(1)
    ..skills([
      "Sense Items",
      "Flee",
      "Escape",
      "Disappear",
      "Icicle",
      "Brilliant Beam",
      "Windstorm",
      "Fire Barrier",
      "Tidal Wave"
    ]);

  // TODO: More spell books and reorganize spells.
}
