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
  item("Soothing Balm", pink, price: 10)
    ..depth(2, to: 30)
    ..heal(36);
  item("Mending Salve", red, price: 30)
    ..depth(20, to: 40)
    ..heal(64);
  item("Healing Poultice", maroon, price: 80)
    ..depth(30)
    ..heal(120, curePoison: true);
  item("Potion[s] of Amelioration", violet, price: 220)
    ..depth(60)
    ..heal(200, curePoison: true);
  item("Potion[s] of Rejuvenation", purple, price: 1000)
    ..depth(80)
    ..heal(1000, curePoison: true);

  item("Antidote", peaGreen, price: 20)
    ..depth(2)
    ..heal(0, curePoison: true);

  category(CharCode.latinSmallLetterEWithCircumflex, stack: 10)
    ..tag("magic/potion/resistance")
    ..frequency(0.5)
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  // TODO: Don't need to strictly have every single element here.
  // TODO: Have stronger versions that appear at higher depths.
  item("Salve[s] of Heat Resistance", carrot, price: 50)
    ..depth(5)
    ..resistSalve(Elements.fire);
  // TODO: Make not freezable?
  item("Salve[s] of Cold Resistance", lightBlue, price: 55)
    ..depth(6)
    ..resistSalve(Elements.cold);
  item("Salve[s] of Light Resistance", buttermilk, price: 60)
    ..depth(7)
    ..resistSalve(Elements.light);
  item("Salve[s] of Wind Resistance", lightAqua, price: 65)
    ..depth(8)
    ..resistSalve(Elements.air);
  item("Salve[s] of Lightning Resistance", lilac, price: 70)
    ..depth(9)
    ..resistSalve(Elements.lightning);
  item("Salve[s] of Darkness Resistance", coolGray, price: 75)
    ..depth(10)
    ..resistSalve(Elements.dark);
  item("Salve[s] of Earth Resistance", tan, price: 80)
    ..depth(13)
    ..resistSalve(Elements.earth);
  item("Salve[s] of Water Resistance", darkBlue, price: 85)
    ..depth(16)
    ..resistSalve(Elements.water);
  item("Salve[s] of Acid Resistance", sandal, price: 90)
    ..depth(19)
    ..resistSalve(Elements.acid); // TODO: Better color.
  item("Salve[s] of Poison Resistance", lima, price: 95)
    ..depth(23)
    ..resistSalve(Elements.poison);
  item("Salve[s] of Death Resistance", purple, price: 100)
    ..depth(30)
    ..resistSalve(Elements.spirit);

  // TODO: "Insulation", "the Elements" and other multi-element resistances.

  // Speed.
  category(CharCode.latinSmallLetterEWithDiaeresis, stack: 10)
    ..tag("magic/potion/speed")
    ..frequency(0.3)
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  item("Potion[s] of Quickness", lima, price: 25)
    ..depth(3, to: 30)
    ..haste(1, 40);
  item("Potion[s] of Alacrity", peaGreen, price: 60)
    ..depth(18, to: 50)
    ..haste(2, 60);
  item("Potion[s] of Speed", sherwood, price: 150)
    ..depth(34)
    ..frequency(0.25)
    ..haste(3, 100);

  // dram, draught, elixir, philter

  // TODO: Don't need to strictly have every single element here.
  // TODO: Should shatter and take effect when tossed.
  category(CharCode.latinSmallLetterEWithGrave, stack: 10)
    ..tag("magic/potion/bottled")
    ..frequency(0.5)
    ..toss(damage: 1, range: 8, breakage: 100)
    ..destroy(Elements.cold, chance: 15);
  item("Bottled Wind", lightBlue, price: 100)
    ..depth(4)
    ..flow(Elements.air, "the wind", "blasts", 10, fly: true);
  // TODO: Make not freezable?
  item("Bottled Ice", blue, price: 120)
    ..depth(7)
    ..ball(Elements.cold, "the cold", "freezes", 16);
  item("Bottled Fire", red, price: 140)
    ..depth(11)
    ..flow(Elements.fire, "the fire", "burns", 23, fly: true);
  item("Bottled Ocean", darkBlue, price: 160)
    ..depth(12)
    ..flow(Elements.water, "the water", "drowns", 30);
  item("Bottled Poison", sherwood, price: 240)
    ..depth(13)
    ..flow(Elements.poison, "the poison", "infects", 10, fly: true);
  item("Bottled Earth", tan, price: 180)
    ..depth(16)
    ..ball(Elements.earth, "the dirt", "crushes", 58);
  item("Bottled Lightning", lilac, price: 200)
    ..depth(18)
    ..ball(Elements.lightning, "the lightning", "shocks", 68);
  item("Bottled Acid", lima, price: 220)
    ..depth(22)
    ..flow(Elements.acid, "the acid", "corrodes", 72);
  item("Bottled Shadow", darkCoolGray, price: 260)
    ..depth(28)
    ..ball(Elements.dark, "the darkness", "torments", 120);
  item("Bottled Radiance", buttermilk, price: 280)
    ..depth(34)
    ..ball(Elements.light, "light", "sears", 140);
  item("Bottled Spirit", coolGray, price: 300)
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
    ..frequency(0.3)
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Scroll[s] of Sidestepping", lilac, price: 16)
    ..depth(2)
    ..frequency(0.5)
    ..teleport(8);
  item("Scroll[s] of Phasing", purple, price: 28)
    ..depth(6)
    ..teleport(14);
  item("Scroll[s] of Teleportation", violet, price: 52)
    ..depth(15)
    ..teleport(28);
  item("Scroll[s] of Disappearing", darkBlue, price: 74)
    ..depth(26)
    ..teleport(54);

  // Detection.
  category(CharCode.latinSmallLetterAWithDiaeresis, stack: 20)
    ..tag("magic/scroll/detection")
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Scroll[s] of Find Nearby Escape", buttermilk, price: 12)
    ..depth(1, to: 10)
    ..detection([DetectType.exit], range: 20);
  item("Scroll[s] of Locate Escape", sandal, price: 28)
    ..depth(8, to: 30)
    ..detection([DetectType.exit]);

  item("Scroll[s] of Find Nearby Items", gold, price: 24)
    ..depth(2, to: 16)
    ..detection([DetectType.item], range: 20);
  item("Scroll[s] of Item Detection", carrot, price: 64)
    ..depth(12, to: 40)
    ..detection([DetectType.item]);

  item("Scroll[s] of Detect Nearby", lima, price: 36)
    ..depth(12, to: 36)
    ..detection([DetectType.exit, DetectType.item], range: 20);
  item("Scroll[s] of Detection", persimmon, price: 124)
    ..depth(30)
    ..detection([DetectType.exit, DetectType.item]);

  // Perception.
  // TODO: Different scrolls for different kinds of monsters? (Evil, natural,
  // with brain, invisible, etc.)
  item("Scroll[s] of Sense Nearby Monsters", lightBlue, price: 50)
    ..depth(6, to: 19)
    ..perception(distance: 15);
  item("Scroll[s] of Sense Monsters", aqua, price: 70)
    ..depth(20, to: 39)
    ..perception(distance: 20);
  item("Scroll[s] of Perceive Monsters", blue, price: 100)
    ..depth(40, to: 69)
    ..perception(duration: 50, distance: 30);
  item("Scroll[s] of Telepathy", darkBlue, price: 150)
    ..depth(70)
    ..perception(distance: 200);

  // Mapping.
  category(CharCode.latinSmallLetterAWithGrave, stack: 20)
    ..tag("magic/scroll/mapping")
    ..frequency(0.25)
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 15, fuel: 5);
  item("Adventurer's Map", sherwood, price: 70)
    ..depth(10, to: 50)
    ..mapping(16);
  item("Explorer's Map", peaGreen, price: 160)
    ..depth(30, to: 70)
    ..mapping(32);
  item("Cartographer's Map", mint, price: 240)
    ..depth(50, to: 90)
    ..mapping(64);
  item("Wizard's Map", aqua, price: 360)
    ..depth(70)
    ..mapping(200, illuminate: true);

  //  CharCode.latinSmallLetterAWithRingAbove // scroll
}

void spellBooks() {
  category(CharCode.vulgarFractionOneHalf)
    ..tag("magic/book/sorcery")
    ..toss(damage: 1, range: 3, breakage: 25)
    ..destroy(Elements.fire, chance: 5, fuel: 10);
  item("Spellbook[s] \"Elemental Primer\"", maroon, price: 100)
    ..depth(1)
    ..frequency(0.05)
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

void rings() {
  // TODO: Decide whether this reuses all of the same names and effects as the
  // intellect helms or not.
  category(CharCode.latinSmallLetterIWithDiaeresis).tag("magic/ring");
  item("Ring[s] of Wisdom", blue, price: 1000)
    ..depth(20)
    ..frequency(0.05)
    ..instrinsicAffix((affix) => affix..intellect(fixed(2)));
}
