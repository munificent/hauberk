import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void weapons() {
  // https://en.wikipedia.org/wiki/List_of_mythological_objects#Weapons

  // Bludgeons.
  category(CharCode.latinSmallLetterAWithAcute, verb: "hit[s]")
    ..tag("equipment/weapon/club")
    ..skill("Club Mastery")
    ..toss(breakage: 25, range: 5);
  item("Stick", persimmon, frequency: 0.5)
    ..depth(1, to: 20)
    ..weapon(7, heft: 6)
    ..toss(damage: 3)
    ..destroy(Elements.fire, chance: 10, fuel: 10);
  item("Cudgel", gunsmoke, frequency: 0.5, price: 20)
    ..depth(6, to: 60)
    ..weapon(9, heft: 8)
    ..toss(damage: 4)
    ..destroy(Elements.fire, chance: 5, fuel: 10);
  item("Club", garnet, frequency: 0.5, price: 40)
    ..depth(14)
    ..weapon(12, heft: 11)
    ..toss(damage: 5)
    ..destroy(Elements.fire, chance: 2, fuel: 10);

  // Staves.
  // TODO: Staff skill. Distance attack + pushback?
  category(CharCode.latinSmallLetterIWithAcute, verb: "hit[s]")
    ..tag("equipment/weapon/staff")
    ..toss(breakage: 35, range: 4);
  item("Walking Stick", persimmon, frequency: 0.5, price: 10)
    ..depth(2, to: 40)
    ..weapon(10, heft: 9)
    ..toss(damage: 3)
    ..destroy(Elements.fire, chance: 5, fuel: 15);
  item("Sta[ff|aves]", garnet, frequency: 0.5, price: 50)
    ..depth(7)
    ..weapon(14, heft: 11)
    ..toss(damage: 5)
    ..destroy(Elements.fire, chance: 2, fuel: 15);
  item("Quartersta[ff|aves]", gunsmoke, frequency: 0.5, price: 80)
    ..depth(24)
    ..weapon(20, heft: 13)
    ..toss(damage: 8)
    ..destroy(Elements.fire, chance: 2, fuel: 15);

  // Hammers.
  category(CharCode.latinSmallLetterOWithAcute, verb: "bash[es]")
    ..tag("equipment/weapon/hammer")
    ..toss(breakage: 15, range: 5);
  item("Hammer", persimmon, frequency: 0.5, price: 120)
    ..depth(40)
    ..weapon(32, heft: 22)
    ..toss(damage: 12);
  item("Mattock", garnet, frequency: 0.5, price: 240)
    ..depth(46)
    ..weapon(40, heft: 26)
    ..toss(damage: 16);
  item("War Hammer", gunsmoke, frequency: 0.5, price: 400)
    ..depth(52)
    ..weapon(48, heft: 30)
    ..toss(damage: 20);

  // Maces.
  category(CharCode.latinSmallLetterUWithAcute, verb: "bash[es]")
    ..tag("equipment/weapon/mace")
    ..toss(breakage: 15, range: 4);
  item("Morningstar", gunsmoke, frequency: 0.5, price: 130)
    ..depth(24)
    ..weapon(26, heft: 17)
    ..toss(damage: 11);
  item("Mace", slate, frequency: 0.5, price: 310)
    ..depth(33)
    ..weapon(36, heft: 23)
    ..toss(damage: 16);

  // Whips.
  category(CharCode.latinSmallLetterNWithTilde, verb: "whip[s]")
    ..tag("equipment/weapon/whip")
    ..toss(breakage: 25, range: 4)
    ..skill("Whip Mastery");
  item("Whip", persimmon, frequency: 0.5, price: 40)
    ..depth(4)
    ..weapon(10, heft: 7)
    ..toss(damage: 1)
    ..destroy(Elements.fire, chance: 10, fuel: 5);
  item("Chain Whip", gunsmoke, frequency: 0.5, price: 230)
    ..depth(15)
    ..weapon(18, heft: 15)
    ..toss(damage: 2);
  item("Flail", slate, frequency: 0.5, price: 350)
    ..depth(27)
    ..weapon(28, heft: 24)
    ..toss(damage: 4);

  // Knives.
  // TODO: Dagger skill.
  category(CharCode.latinCapitalLetterNWithTilde, verb: "stab[s]")
    ..tag("equipment/weapon/dagger")
    ..toss(breakage: 2, range: 8);
  item("Kni[fe|ves]", steelGray, frequency: 0.5, price: 20)
    ..depth(3, to: 20)
    ..weapon(8, heft: 5)
    ..toss(damage: 8);
  item("Dirk", gunsmoke, frequency: 0.5, price: 30)
    ..depth(4, to: 40)
    ..weapon(10, heft: 6)
    ..toss(damage: 10);
  item("Dagger", cornflower, frequency: 0.5, price: 50)
    ..depth(6, to: 70)
    ..weapon(12, heft: 7)
    ..toss(damage: 12);
  item("Stiletto[es]", slate, frequency: 0.5, price: 80)
    ..depth(10)
    ..weapon(14, heft: 6)
    ..toss(damage: 14);
  item("Rondel", turquoise, frequency: 0.5, price: 130)
    ..depth(20)
    ..weapon(16, heft: 9)
    ..toss(damage: 16);
  item("Baselard", gold, frequency: 0.5, price: 200)
    ..depth(30)
    ..weapon(18, heft: 11)
    ..toss(damage: 18);
  // Main-guache
  // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

  category(CharCode.feminineOrdinalIndicator, verb: "slash[es]")
    ..tag("equipment/weapon/sword")
    ..toss(breakage: 20, range: 5)
    ..skill("Swordfighting");
  item("Rapier", steelGray, frequency: 0.5, price: 140)
    ..depth(13)
    ..weapon(20, heft: 12)
    ..toss(damage: 4);
  item("Shortsword", slate, frequency: 0.5, price: 230)
    ..depth(17)
    ..weapon(22, heft: 13)
    ..toss(damage: 6);
  item("Scimitar", gunsmoke, frequency: 0.5, price: 370)
    ..depth(21)
    ..weapon(24, heft: 16)
    ..toss(damage: 9);
  item("Cutlass[es]", buttermilk, frequency: 0.5, price: 520)
    ..depth(24)
    ..weapon(26, heft: 17)
    ..toss(damage: 11);
  item("Falchion", turquoise, frequency: 0.5, price: 750)
    ..depth(38)
    ..weapon(28, heft: 18)
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
    ..toss(range: 9)
    ..skill("Spear Mastery");
  item("Pointed Stick", garnet, frequency: 0.5, price: 10)
    ..depth(2, to: 30)
    ..weapon(10, heft: 9)
    ..toss(damage: 9)
    ..destroy(Elements.fire, chance: 7, fuel: 12);
  item("Spear", persimmon, frequency: 0.5, price: 160)
    ..depth(13)
    ..weapon(16, heft: 13)
    ..toss(damage: 15);
  item("Angon", gunsmoke, frequency: 0.5, price: 340)
    ..depth(21)
    ..weapon(20, heft: 19)
    ..toss(damage: 20);

  category(CharCode.masculineOrdinalIndicator, verb: "stab[s]")
    ..tag("equipment/weapon/polearm")
    ..toss(range: 4)
    ..skill("Spear Mastery");
  item("Lance", cornflower, frequency: 0.5, price: 550)
    ..depth(28)
    ..weapon(24, heft: 27)
    ..toss(damage: 20);
  item("Partisan", slate, frequency: 0.5, price: 850)
    ..depth(35)
    ..weapon(30, heft: 29)
    ..toss(damage: 26);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(CharCode.invertedQuestionMark, verb: "chop[s]")
    ..tag("equipment/weapon/axe")
    ..skill("Axe Mastery");
  item("Hatchet", slate, frequency: 0.5, price: 90)
    ..depth(6)
    ..weapon(12, heft: 10)
    ..toss(damage: 20, range: 8);
  item("Axe", persimmon, frequency: 0.5, price: 210)
    ..depth(12)
    ..weapon(15, heft: 14)
    ..toss(damage: 24, range: 7);
  item("Valaska", gunsmoke, frequency: 0.5, price: 330)
    ..depth(24)
    ..weapon(19, heft: 19)
    ..toss(damage: 26, range: 5);
  item("Battleaxe", steelGray, frequency: 0.5, price: 550)
    ..depth(40)
    ..weapon(25, heft: 30)
    ..toss(damage: 28, range: 4);

  // Bows.
  category(CharCode.reversedNotSign, verb: "hit[s]")
    ..tag("equipment/weapon/bow")
    ..toss(breakage: 50, range: 5)
    ..skill("Archery");
  item("Short Bow", persimmon, frequency: 0.3, price: 120)
    ..depth(6)
    ..ranged("the arrow", heft: 12, damage: 4, range: 8)
    ..toss(damage: 2)
    ..destroy(Elements.fire, chance: 15, fuel: 10);
  item("Longbow", garnet, frequency: 0.3, price: 250)
    ..depth(13)
    ..ranged("the arrow", heft: 18, damage: 8, range: 12)
    ..toss(damage: 3)
    ..destroy(Elements.fire, chance: 7, fuel: 13);
  item("Crossbow", gunsmoke, frequency: 0.3, price: 600)
    ..depth(28)
    ..ranged("the bolt", heft: 24, damage: 12, range: 16)
    ..toss(damage: 4)
    ..destroy(Elements.fire, chance: 4, fuel: 14);
}
