import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void weapons() {
  // https://en.wikipedia.org/wiki/List_of_mythological_objects#Weapons

  // Bludgeons.
  category(CharCode.latinSmallLetterAWithAcute, verb: "hit[s]")
    ..tag("equipment/weapon/club")
    ..frequency(0.5)
    ..skill("Club Mastery")
    ..toss(breakage: 25, range: 5);
  item("Stick", tan)
    ..depth(1, to: 20)
    ..weapon(4, heft: 6)
    ..toss(damage: 3)
    ..destroy(Elements.fire, chance: 10, fuel: 10);
  item("Cudgel", lightCoolGray, price: 20)
    ..depth(6, to: 60)
    ..weapon(9, heft: 8)
    ..toss(damage: 4)
    ..destroy(Elements.fire, chance: 5, fuel: 10);
  item("Club", brown, price: 40)
    ..depth(14)
    ..weapon(12, heft: 11)
    ..toss(damage: 5)
    ..destroy(Elements.fire, chance: 2, fuel: 10);

  // Staves.
  // TODO: Staff skill. Distance attack + pushback?
  category(CharCode.latinSmallLetterIWithAcute, verb: "hit[s]")
    ..tag("equipment/weapon/staff")
    ..frequency(0.5)
    ..twoHanded()
    ..toss(breakage: 35, range: 4);
  item("Walking Stick", tan, price: 10)
    ..depth(2, to: 40)
    ..weapon(9, heft: 10)
    ..toss(damage: 3)
    ..destroy(Elements.fire, chance: 5, fuel: 15);
  item("Sta[ff|aves]", brown, price: 50)
    ..depth(7)
    ..weapon(13, heft: 14)
    ..toss(damage: 5)
    ..destroy(Elements.fire, chance: 2, fuel: 15);
  item("Quartersta[ff|aves]", lightCoolGray, price: 80)
    ..depth(24)
    ..weapon(20, heft: 22)
    ..toss(damage: 8)
    ..destroy(Elements.fire, chance: 2, fuel: 15);

  // Hammers.
  category(CharCode.latinSmallLetterOWithAcute, verb: "bash[es]")
    ..tag("equipment/weapon/hammer")
    ..frequency(0.5)
    ..toss(breakage: 15, range: 5);
  item("Hammer", tan, price: 120)
    ..depth(40)
    ..weapon(28, heft: 22)
    ..toss(damage: 12);
  item("Mattock", brown, price: 240)
    ..depth(46)
    ..weapon(36, heft: 29)
    ..toss(damage: 16);
  item("War Hammer", lightCoolGray, price: 400)
    ..depth(52)
    ..weapon(44, heft: 38)
    ..toss(damage: 20);

  // Maces.
  category(CharCode.latinSmallLetterUWithAcute, verb: "bash[es]")
    ..tag("equipment/weapon/mace")
    ..frequency(0.5)
    ..toss(breakage: 15, range: 4);
  item("Morningstar", lightCoolGray, price: 130)
    ..depth(24)
    ..weapon(25, heft: 21)
    ..toss(damage: 11);
  item("Mace", coolGray, price: 310)
    ..depth(33)
    ..weapon(36, heft: 32)
    ..toss(damage: 16);

  // Whips.
  category(CharCode.latinSmallLetterNWithTilde, verb: "whip[s]")
    ..tag("equipment/weapon/whip")
    ..frequency(0.5)
    ..toss(breakage: 25, range: 4)
    ..skill("Whip Mastery");
  item("Whip", tan, price: 40)
    ..depth(4)
    ..weapon(9, heft: 7)
    ..toss(damage: 1)
    ..destroy(Elements.fire, chance: 10, fuel: 5);
  item("Chain Whip", lightCoolGray, price: 230)
    ..depth(15)
    ..weapon(18, heft: 17)
    ..toss(damage: 2);
  item("Flail", coolGray, price: 350)
    ..depth(27)
    ..weapon(28, heft: 24)
    ..toss(damage: 4);

  // Knives.
  // TODO: Dagger skill.
  category(CharCode.latinCapitalLetterNWithTilde, verb: "stab[s]")
    ..tag("equipment/weapon/dagger")
    ..frequency(0.5)
    ..toss(breakage: 2, range: 8);
  item("Kni[fe|ves]", lightWarmGray, price: 20)
    ..depth(3, to: 20)
    ..weapon(6, heft: 5)
    ..toss(damage: 6);
  item("Dirk", lightCoolGray, price: 30)
    ..depth(4, to: 40)
    ..weapon(8, heft: 6)
    ..toss(damage: 8);
  item("Dagger", lightBlue, price: 50)
    ..depth(6, to: 70)
    ..weapon(9, heft: 7)
    ..toss(damage: 9);
  item("Stiletto[es]", coolGray, price: 80)
    ..depth(10)
    ..weapon(11, heft: 8)
    ..toss(damage: 11);
  item("Rondel", lightAqua, price: 130)
    ..depth(20)
    ..weapon(13, heft: 9)
    ..toss(damage: 13);
  item("Baselard", gold, price: 200)
    ..depth(30)
    ..weapon(15, heft: 11)
    ..toss(damage: 15);
  // Main-guache
  // Unique dagger: "Mercygiver" (see Misericorde at Wikipedia)

  category(CharCode.feminineOrdinalIndicator, verb: "slash[es]")
    ..tag("equipment/weapon/sword")
    ..frequency(0.5)
    ..toss(breakage: 20, range: 5)
    ..skill("Swordfighting");
  item("Rapier", warmGray, price: 140)
    ..depth(13)
    ..weapon(13, heft: 13)
    ..toss(damage: 4);
  item("Shortsword", coolGray, price: 230)
    ..depth(17)
    ..weapon(15, heft: 15)
    ..toss(damage: 6);
  item("Scimitar", lightCoolGray, price: 370)
    ..depth(18)
    ..weapon(24, heft: 18)
    ..toss(damage: 9);
  item("Cutlass[es]", buttermilk, price: 520)
    ..depth(20)
    ..weapon(26, heft: 22)
    ..toss(damage: 11);
  item("Falchion", lightAqua, price: 750)
    ..depth(34)
    ..weapon(28, heft: 25)
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
    ..frequency(0.5)
    ..toss(range: 9)
    ..skill("Spear Mastery");
  item("Pointed Stick", brown, price: 10)
    ..depth(2, to: 30)
    ..weapon(7, heft: 9)
    ..toss(damage: 6)
    ..destroy(Elements.fire, chance: 7, fuel: 12);
  item("Spear", tan, price: 160)
    ..depth(13, to: 60)
    ..weapon(16, heft: 13)
    ..toss(damage: 15);
  item("Angon", lightCoolGray, price: 340)
    ..depth(21)
    ..weapon(20, heft: 19)
    ..toss(damage: 20);

  category(CharCode.masculineOrdinalIndicator, verb: "stab[s]")
    ..tag("equipment/weapon/polearm")
    ..frequency(0.5)
    ..twoHanded()
    ..toss(range: 4)
    ..skill("Spear Mastery");
  item("Lance", lightBlue, price: 550)
    ..depth(28)
    ..weapon(22, heft: 23)
    ..toss(damage: 20);
  item("Partisan", coolGray, price: 850)
    ..depth(35)
    ..weapon(26, heft: 25)
    ..toss(damage: 26);

  // glaive, voulge, halberd, pole-axe, lucerne hammer,

  category(CharCode.invertedQuestionMark, verb: "chop[s]")
    ..tag("equipment/weapon/axe")
    ..frequency(0.5)
    ..skill("Axe Mastery");
  item("Hatchet", coolGray, price: 90)
    ..depth(6, to: 50)
    ..weapon(12, heft: 10)
    ..toss(damage: 20, range: 8);
  item("Axe", tan, price: 210)
    ..depth(12, to: 70)
    ..weapon(15, heft: 14)
    ..toss(damage: 24, range: 7);
  item("Valaska", lightCoolGray, price: 330)
    ..depth(24)
    ..weapon(19, heft: 19)
    ..toss(damage: 26, range: 5);

  item("Battleaxe", warmGray, price: 550)
    ..depth(40)
    ..twoHanded()
    ..weapon(25, heft: 30)
    ..toss(damage: 28, range: 4);

  // Bows.
  category(CharCode.reversedNotSign, verb: "hit[s]")
    ..tag("equipment/weapon/bow")
    ..frequency(0.3)
    ..twoHanded()
    ..toss(breakage: 50, range: 5)
    ..skill("Archery");
  item("Short Bow", tan, price: 120)
    ..depth(6, to: 60)
    ..ranged("the arrow", heft: 12, damage: 5, range: 8)
    ..toss(damage: 2)
    ..destroy(Elements.fire, chance: 15, fuel: 10);
  item("Longbow", brown, price: 250)
    ..depth(13)
    ..ranged("the arrow", heft: 18, damage: 9, range: 12)
    ..toss(damage: 3)
    ..destroy(Elements.fire, chance: 7, fuel: 13);
  // TODO: Warbow.
  item("Crossbow", lightCoolGray, price: 600)
    ..depth(28)
    ..ranged("the bolt", heft: 24, damage: 14, range: 16)
    ..toss(damage: 4)
    ..destroy(Elements.fire, chance: 4, fuel: 14);
}
