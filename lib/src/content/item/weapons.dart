import 'package:malison/malison.dart';

import '../../hues.dart';
import 'builder.dart';

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
