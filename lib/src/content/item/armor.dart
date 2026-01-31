import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void helms() {
  category(CharCode.latinCapitalLetterEWithAcute)
    ..tag("equipment/armor/helm")
    ..frequency(0.5)
    ..toss(damage: 3, range: 5, breakage: 10);
  item("Leather Cap", tan, price: 50)
    ..depth(4, to: 40)
    ..armor(2, weight: 2)
    ..destroy(Elements.fire, chance: 12, fuel: 2);
  item("Chainmail Coif", darkCoolGray, price: 160)
    ..depth(10, to: 60)
    ..armor(3, weight: 3);
  item("Steel Cap", coolGray, price: 200)
    ..depth(25, to: 80)
    ..armor(4, weight: 3);
  item("Visored Helm", lightCoolGray, price: 350)
    ..depth(40)
    ..armor(5, weight: 6);
  item("Great Helm", ash, price: 550)
    ..depth(50)
    ..armor(6, weight: 8);
}

void bodyArmor() {
  // Robes.
  category(
    CharCode.latinSmallLetterOWithCircumflex,
  ).tag("equipment/armor/body/robe");
  item("Robe", blue, price: 30)
    ..depth(2, to: 40)
    ..frequency(0.5)
    ..armor(4)
    ..destroy(Elements.fire, chance: 15, fuel: 8);
  item("Lined Robe", sherwood, price: 110)
    ..depth(6)
    ..frequency(0.25)
    ..armor(6)
    ..destroy(Elements.fire, chance: 12, fuel: 8);
  // TODO: Better robes that don't add weight and appear later.

  // Soft armor.
  category(CharCode.latinSmallLetterOWithDiaeresis)
    ..tag("equipment/armor/body")
    ..frequency(0.5);
  item("Cloth Shirt", ash, price: 20)
    ..depth(2, to: 30)
    ..armor(3)
    ..destroy(Elements.fire, chance: 15, fuel: 4);
  item("Leather Shirt", tan, price: 90)
    ..depth(5, to: 50)
    ..armor(6, weight: 1)
    ..destroy(Elements.fire, chance: 12, fuel: 4);
  item("Jerkin", lightCoolGray, price: 130)
    ..depth(8, to: 70)
    ..armor(8, weight: 1);
  item("Leather Armor", brown, price: 240)
    ..depth(12, to: 90)
    ..armor(11, weight: 2)
    ..destroy(Elements.fire, chance: 10, fuel: 4);
  item("Padded Armor", darkCoolGray, price: 320)
    ..depth(16)
    ..armor(15, weight: 3)
    ..destroy(Elements.fire, chance: 8, fuel: 4);
  item("Studded Armor", coolGray, price: 400)
    ..depth(20)
    ..armor(22, weight: 4)
    ..destroy(Elements.fire, chance: 6, fuel: 4);

  // Mail armor.
  category(CharCode.latinSmallLetterOWithGrave)
    ..tag("equipment/armor/body")
    ..frequency(0.5);
  item("Mail Hauberk", darkCoolGray, price: 500)
    ..depth(25)
    ..armor(28, weight: 5);
  item("Scale Mail", lightCoolGray, price: 700)
    ..depth(35)
    ..armor(36, weight: 7);

  // Plate armor.
  category(CharCode.latinSmallLetterUWithCircumflex)
    ..tag("equipment/armor/body")
    ..frequency(0.5);
  item("Plated Mail", darkCoolGray, price: 1000)
    ..depth(40)
    ..armor(40, weight: 8);
  item("Brigandine", tan, price: 1300)
    ..depth(50)
    ..armor(46, weight: 10);
  item("Breastplate", coolGray, price: 2000)
    ..depth(60)
    ..armor(52, weight: 14);
  item("Plate Armor", lightCoolGray, price: 3400)
    ..depth(70)
    ..armor(60, weight: 18);
}

void cloaks() {
  category(CharCode.latinCapitalLetterAe).tag("equipment/armor/cloak");
  item("Cloak", darkBlue, price: 70)
    ..depth(10, to: 40)
    ..frequency(0.5)
    ..armor(2, weight: 1)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Fur Cloak", brown, price: 140)
    ..depth(20, to: 60)
    ..frequency(0.3)
    ..armor(4, weight: 2)
    ..destroy(Elements.fire, chance: 16, fuel: 5);
  item("Spidersilk Cloak", darkCoolGray, price: 460)
    ..depth(40)
    ..frequency(0.2)
    ..armor(6)
    ..destroy(Elements.fire, chance: 25, fuel: 3);
  // TODO: Better cloaks that don't add weight and appear later.
}

void gloves() {
  category(CharCode.latinCapitalLetterAWithRingAbove)
    ..tag("equipment/armor/gloves")
    ..frequency(0.5)
    ..toss(damage: 5, range: 4, breakage: 20);
  // TODO: Encumbrance.
  // Here's an idea to get mages wearing light armor and no gloves: Give weapons
  // and usable items the equivalent of heft for agility. (Need a name.) If
  // their agility is too low, the weapon gets a negative strike bonus. But
  // also *affix power is reduced*. Thus, if a mage is too encumbered by gloves,
  // their wand no longer makes spells more powerful.
  //
  // Could probably do the same for heft. A battleaxe of fire doesn't do a lot
  // of fire damage if you can't lift it.
  item("(Pair[s] of )Gloves", sandal, price: 170)
    ..depth(8)
    ..armor(1)
    ..destroy(Elements.fire, chance: 7, fuel: 2);
  item("(Set[s] of )Bracers", brown, price: 480)
    ..depth(17)
    ..armor(2, weight: 1);
  item("(Pair[s] of )Gauntlets", darkCoolGray, price: 800)
    ..depth(34)
    ..armor(4, weight: 2);
}

void shields() {
  category(CharCode.latinSmallLetterAe)
    ..tag("equipment/armor/shield")
    ..frequency(0.5)
    ..toss(damage: 5, range: 8, breakage: 10);
  // TODO: Encumbrance.
  item("Buckler", darkCoolGray, price: 170)
    ..depth(10, to: 40)
    ..armor(0, weight: 2)
    ..defense(3, "The buckler blocks {2}.");
  item("Leather Shield", brown, price: 240)
    ..depth(20, to: 50)
    ..armor(0, weight: 3)
    ..defense(5, "The shield blocks {2}.")
    ..destroy(Elements.fire, chance: 15, fuel: 14);
  item("Targe", sandal, price: 340)
    ..depth(30, to: 60)
    ..armor(0, weight: 4)
    ..defense(8, "The targe blocks {2}.")
    ..destroy(Elements.fire, chance: 10, fuel: 20);
  item("Roundel", coolGray, price: 410)
    ..depth(40, to: 80)
    ..armor(0, weight: 6)
    ..defense(10, "The shield blocks {2}.");
  item("Steel Shield", lightCoolGray, price: 570)
    ..depth(50, to: 90)
    ..armor(0, weight: 7)
    ..defense(12, "The shield blocks {2}.");
  item("Kite Shield", lightWarmGray, price: 650)
    ..depth(60)
    ..armor(0, weight: 8)
    ..defense(15, "The shield blocks {2}.");

  item("Lantern Shield", gold, price: 1200)
    ..depth(30)
    ..armor(0, weight: 8)
    ..defense(11, "The shield blocks {2}.")
    ..lightSource(level: 5);
}

void boots() {
  category(CharCode.latinSmallLetterIWithGrave)
    ..tag("equipment/armor/boots")
    ..frequency(0.3);
  item("(Pair[s] of )Sandals", tan, price: 10)
    ..depth(2, to: 20)
    ..armor(1)
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("(Pair[s] of )Shoes", brown, price: 30)
    ..depth(8, to: 40)
    ..armor(2)
    ..destroy(Elements.fire, chance: 14, fuel: 3);

  category(CharCode.latinCapitalLetterAWithDiaeresis)
    ..tag("equipment/armor/boots")
    ..frequency(0.3);
  item("(Pair[s] of )Boots", tan, price: 70)
    ..depth(14)
    ..armor(6, weight: 1);
  item("(Pair[s] of )Plated Boots", coolGray, price: 250)
    ..depth(22)
    ..armor(8, weight: 2);
  item("(Pair[s] of )Greaves", lightCoolGray, price: 350)
    ..depth(47)
    ..armor(12, weight: 3);
}
