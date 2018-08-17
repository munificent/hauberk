import 'package:malison/malison.dart';

import '../../hues.dart';
import '../action/condition.dart';
import '../action/detection.dart';
import '../action/teleport.dart';
import '../elements.dart';
import 'builder.dart';

void potions() {
  // TODO: Some potions should perform an effect when thrown.

  // Healing.
  category(CharCode.latinSmallLetterCWithCedilla, stack: 10)
    ..tag("magic/potion/healing")
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  item("Soothing Balm", 2, salmon, frequency: 1.0, price: 10)..heal(48);
  item("Mending Salve", 7, brickRed, frequency: 1.0, price: 30)..heal(100);
  item("Healing Poultice", 12, maroon, frequency: 1.0, price: 80)
    ..heal(200, curePoison: true);
  item("Potion[s] of Amelioration", 24, indigo, frequency: 1.0, price: 220)
    ..heal(400, curePoison: true);
  item("Potion[s] of Rejuvenation", 65, violet, frequency: 0.5, price: 1000)
    ..heal(1000, curePoison: true);

  item("Antidote", 2, peaGreen, frequency: 1.0, price: 20)
    ..heal(0, curePoison: true);

  category(CharCode.latinSmallLetterEWithCircumflex, stack: 10)
    ..tag("magic/potion/resistance")
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  // TODO: Don't need to strictly have every single element here.
  item("Salve[s] of Heat Resistance", 5, carrot, frequency: 0.5, price: 50)
    ..resistSalve(Elements.fire);
  // TODO: Make not freezable?
  item("Salve[s] of Cold Resistance", 6, cornflower, frequency: 0.5, price: 55)
    ..resistSalve(Elements.cold);
  item("Salve[s] of Light Resistance", 7, buttermilk, frequency: 0.5, price: 60)
    ..resistSalve(Elements.light);
  item("Salve[s] of Wind Resistance", 8, turquoise, frequency: 0.5, price: 65)
    ..resistSalve(Elements.air);
  item("Salve[s] of Lightning Resistance", 9, lilac, frequency: 0.5, price: 70)
    ..resistSalve(Elements.lightning);
  item("Salve[s] of Darkness Resistance", 10, slate, frequency: 0.5, price: 75)
    ..resistSalve(Elements.dark);
  item("Salve[s] of Earth Resistance", 13, persimmon, frequency: 0.5, price: 80)
    ..resistSalve(Elements.earth);
  item("Salve[s] of Water Resistance", 16, ultramarine,
      frequency: 0.5, price: 85)
    ..resistSalve(Elements.water);
  item("Salve[s] of Acid Resistance", 19, sandal, frequency: 0.5, price: 90)
    ..resistSalve(Elements.acid); // TODO: Better color.
  item("Salve[s] of Poison Resistance", 23, lima, frequency: 0.5, price: 95)
    ..resistSalve(Elements.poison);
  item("Salve[s] of Death Resistance", 30, violet, frequency: 0.5, price: 100)
    ..resistSalve(Elements.spirit);

  // TODO: "Insulation", "the Elements" and other multi-element resistances.

  // Speed.
  category(CharCode.latinSmallLetterEWithDiaeresis, stack: 10)
    ..tag("magic/potion/speed")
    ..toss(damage: 1, range: 6, breakage: 100)
    ..destroy(Elements.cold, chance: 20);
  item("Potion[s] of Quickness", 3, lima, frequency: 0.3, price: 25)
    ..use(() => HasteAction(20, 1));
  item("Potion[s] of Alacrity", 18, peaGreen, frequency: 0.3, price: 60)
    ..use(() => HasteAction(30, 2));
  item("Potion[s] of Speed", 34, sherwood, frequency: 0.25, price: 150)
    ..use(() => HasteAction(40, 3));

  // dram, draught, elixir, philter

  // TODO: Don't need to strictly have every single element here.
  category(CharCode.latinSmallLetterEWithGrave, stack: 10)
    ..tag("magic/potion/bottled")
    ..toss(damage: 1, range: 8, breakage: 100)
    ..destroy(Elements.cold, chance: 15);
  item("Bottled Wind", 4, cornflower, frequency: 0.5, price: 100)
    ..flow(Elements.air, "the wind", "blasts", 20, fly: true);
  // TODO: Make not freezable?
  item("Bottled Ice", 7, cerulean, frequency: 0.5, price: 120)
    ..ball(Elements.cold, "the cold", "freezes", 30);
  item("Bottled Fire", 11, brickRed, frequency: 0.5, price: 140)
    ..flow(Elements.fire, "the fire", "burns", 44, fly: true);
  item("Bottled Ocean", 12, ultramarine, frequency: 0.5, price: 160)
    ..flow(Elements.water, "the water", "drowns", 52);
  item("Bottled Earth", 13, persimmon, frequency: 0.5, price: 180)
    ..ball(Elements.earth, "the dirt", "crushes", 58);
  item("Bottled Lightning", 16, lilac, frequency: 0.5, price: 200)
    ..ball(Elements.lightning, "the lightning", "shocks", 68);
  item("Bottled Acid", 18, lima, frequency: 0.5, price: 220)
    ..flow(Elements.acid, "the acid", "corrodes", 72);
  item("Bottled Poison", 22, sherwood, frequency: 0.5, price: 240)
    ..flow(Elements.poison, "the poison", "infects", 90, fly: true);
  item("Bottled Shadow", 28, steelGray, frequency: 0.5, price: 260)
    ..ball(Elements.dark, "the darkness", "torments", 120);
  item("Bottled Radiance", 34, buttermilk, frequency: 0.5, price: 280)
    ..ball(Elements.light, "light", "sears", 140);
  item("Bottled Spirit", 40, slate, frequency: 0.5, price: 300)
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
  item("Scroll[s] of Sidestepping", 2, lilac, frequency: 0.5, price: 16)
    ..use(() => TeleportAction(6));
  item("Scroll[s] of Phasing", 6, violet, frequency: 0.3, price: 28)
    ..use(() => TeleportAction(12));
  item("Scroll[s] of Teleportation", 15, indigo, frequency: 0.3, price: 52)
    ..use(() => TeleportAction(24));
  item("Scroll[s] of Disappearing", 26, ultramarine, frequency: 0.3, price: 74)
    ..use(() => TeleportAction(48));

  // Detection.
  category(CharCode.latinSmallLetterAWithDiaeresis, stack: 20)
    ..tag("magic/scroll/detection")
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Scroll[s] of Find Nearby Escape", 1, buttermilk,
      frequency: 0.5, price: 12)
    ..detection([DetectType.exit], range: 20);
  item("Scroll[s] of Find Nearby Items", 2, gold, frequency: 0.5, price: 24)
    ..detection([DetectType.item], range: 20);
  item("Scroll[s] of Detect Nearby", 3, lima, frequency: 0.25, price: 36)
    ..detection([DetectType.exit, DetectType.item], range: 20);

  item("Scroll[s] of Locate Escape", 5, sandal, frequency: 1.0, price: 28)
    ..detection([DetectType.exit]);
  item("Scroll[s] of Item Detection", 20, carrot, frequency: 0.5, price: 64)
    ..detection([DetectType.item]);
  item("Scroll[s] of Detection", 30, copper, frequency: 0.25, price: 124)
    ..detection([DetectType.exit, DetectType.item]);

  // Mapping.
  category(CharCode.latinSmallLetterAWithGrave, stack: 20)
    ..tag("magic/scroll/mapping")
    ..toss(damage: 1, range: 3, breakage: 75)
    ..destroy(Elements.fire, chance: 15, fuel: 5);
  item("Adventurer's Map", 10, sherwood, frequency: 0.25, price: 70)
    ..mapping(16);
  item("Explorer's Map", 30, peaGreen, frequency: 0.25, price: 160)
    ..mapping(32);
  item("Cartographer's Map", 50, mint, frequency: 0.25, price: 240)
    ..mapping(64);
  item("Wizard's Map", 70, seaGreen, frequency: 0.25, price: 360)
    ..mapping(200, illuminate: true);

//  CharCode.latinSmallLetterAWithRingAbove // scroll
}

void spellBooks() {
  category(CharCode.vulgarFractionOneHalf, stack: 3)
    ..tag("magic/book/sorcery")
    ..toss(damage: 1, range: 3, breakage: 25)
    ..destroy(Elements.fire, chance: 5, fuel: 10);
  item('Spellbook "Elemental Primer"', 1, maroon, frequency: 0.05, price: 100)
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
