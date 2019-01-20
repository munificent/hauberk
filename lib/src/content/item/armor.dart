import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void helms() {
  category(CharCode.latinCapitalLetterEWithAcute)
    ..tag("equipment/armor/helm")
    ..toss(damage: 3, range: 5, breakage: 10);
  item("Leather Cap", tan, frequency: 0.5, price: 50)
    ..depth(4, to: 40)
    ..armor(2, weight: 2)
    ..destroy(Elements.fire, chance: 12, fuel: 2);
  item("Chainmail Coif", darkCoolGray, frequency: 0.5, price: 160)
    ..depth(10, to: 60)
    ..armor(3, weight: 3);
  item("Steel Cap", coolGray, frequency: 0.5, price: 200)
    ..depth(25, to: 80)
    ..armor(4, weight: 3);
  item("Visored Helm", lightCoolGray, frequency: 0.5, price: 350)
    ..depth(40)
    ..armor(5, weight: 6);
  item("Great Helm", ash, frequency: 0.5, price: 550)
    ..depth(50)
    ..armor(6, weight: 8);
}

void bodyArmor() {
  // Robes.
  category(CharCode.latinSmallLetterOWithCircumflex)
    ..tag("equipment/armor/body/robe");
  item("Robe", blue, frequency: 0.5, price: 20)
    ..depth(2, to: 40)
    ..armor(4)
    ..destroy(Elements.fire, chance: 15, fuel: 8);
  item("Fur-lined Robe", sherwood, frequency: 0.25, price: 110)
    ..depth(6)
    ..armor(6)
    ..destroy(Elements.fire, chance: 12, fuel: 8);
  // TODO: Better robes that don't add weight and appear later.

  // Soft armor.
  category(CharCode.latinSmallLetterOWithDiaeresis)
    ..tag("equipment/armor/body");
  item("Cloth Shirt", ash, frequency: 0.5, price: 40)
    ..depth(2, to: 30)
    ..armor(3)
    ..destroy(Elements.fire, chance: 15, fuel: 4);
  item("Leather Shirt", tan, frequency: 0.5, price: 90)
    ..depth(5, to: 50)
    ..armor(6, weight: 1)
    ..destroy(Elements.fire, chance: 12, fuel: 4);
  item("Jerkin", lightCoolGray, frequency: 0.5, price: 130)
    ..depth(8, to: 70)
    ..armor(8, weight: 1);
  item("Leather Armor", brown, frequency: 0.5, price: 240)
    ..depth(12, to: 90)
    ..armor(11, weight: 2)
    ..destroy(Elements.fire, chance: 10, fuel: 4);
  item("Padded Armor", darkCoolGray, frequency: 0.5, price: 320)
    ..depth(16)
    ..armor(15, weight: 3)
    ..destroy(Elements.fire, chance: 8, fuel: 4);
  item("Studded Armor", coolGray, frequency: 0.5, price: 400)
    ..depth(20)
    ..armor(22, weight: 4)
    ..destroy(Elements.fire, chance: 6, fuel: 4);

  // Mail armor.
  category(CharCode.latinSmallLetterOWithGrave)..tag("equipment/armor/body");
  item("Mail Hauberk", darkCoolGray, frequency: 0.5, price: 500)
    ..depth(25)
    ..armor(28, weight: 5);
  item("Scale Mail", lightCoolGray, frequency: 0.5, price: 700)
    ..depth(35)
    ..armor(36, weight: 7);

//  CharCode.latinSmallLetterUWithCircumflex // armor

  /*
  Metal Lamellar Armor[s]
  Chain Mail Armor[s]
  Metal Scale Mail[s]
  Plated Mail[s]
  Brigandine[s]
  Steel Breastplate[s]
  Partial Plate Armor[s]
  Full Plate Armor[s]
  */
}

void cloaks() {
  category(CharCode.latinCapitalLetterAe)..tag("equipment/armor/cloak");
  item("Cloak", darkBlue, frequency: 0.5, price: 70)
    ..depth(10, to: 40)
    ..armor(2, weight: 1)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Fur Cloak", brown, frequency: 0.2, price: 140)
    ..depth(20, to: 60)
    ..armor(4, weight: 2)
    ..destroy(Elements.fire, chance: 16, fuel: 5);
  item("Spidersilk Cloak", darkCoolGray, frequency: 0.2, price: 460)
    ..depth(40)
    ..armor(6)
    ..destroy(Elements.fire, chance: 25, fuel: 3);
  // TODO: Better cloaks that don't add weight and appear later.
}

void gloves() {
  category(CharCode.latinCapitalLetterAWithRingAbove)
    ..tag("equipment/armor/gloves")
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
  item("Pair[s] of Gloves", sandal, frequency: 0.5, price: 170)
    ..depth(8)
    ..armor(1)
    ..destroy(Elements.fire, chance: 7, fuel: 2);
  item("Set[s] of Bracers", brown, frequency: 0.5, price: 480)
    ..depth(17)
    ..armor(2, weight: 1);
  item("Pair[s] of Gauntlets", darkCoolGray, frequency: 0.5, price: 800)
    ..depth(34)
    ..armor(4, weight: 2);
}

void shields() {
  category(CharCode.latinSmallLetterAe)
    ..tag("equipment/armor/shield")
    ..toss(damage: 5, range: 8, breakage: 10);
  // TODO: Encumbrance.
  item("Small Leather Shield", brown, frequency: 0.5, price: 170)
    ..depth(12, to: 50)
    ..armor(0, weight: 2)
    ..defense(4, "The shield blocks {2}.")
    ..destroy(Elements.fire, chance: 7, fuel: 14);
  item("Wooden Targe", sandal, frequency: 0.5, price: 250)
    ..depth(25)
    ..armor(0, weight: 4)
    ..defense(6, "The targe blocks {2}.")
    ..destroy(Elements.fire, chance: 14, fuel: 20);
  item("Large Leather Shield", tan, frequency: 0.5, price: 320)
    ..depth(35)
    ..armor(0, weight: 5)
    ..defense(8, "The shield blocks {2}.")
    ..destroy(Elements.fire, chance: 7, fuel: 17);
  item("Steel Buckler", darkCoolGray, frequency: 0.5, price: 450)
    ..depth(50)
    ..armor(0, weight: 4)
    ..defense(10, "The buckler blocks {2}.");
  item("Kite Shield", lightCoolGray, frequency: 0.5, price: 650)
    ..depth(65)
    ..armor(0, weight: 7)
    ..defense(12, "The shield blocks {2}.");
}

void boots() {
  category(CharCode.latinSmallLetterIWithGrave)..tag("equipment/armor/boots");
  item("Pair[s] of Sandals", tan, frequency: 0.24, price: 10)
    ..depth(2, to: 20)
    ..armor(1)
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("Pair[s] of Shoes", brown, frequency: 0.3, price: 30)
    ..depth(8, to: 40)
    ..armor(2)
    ..destroy(Elements.fire, chance: 14, fuel: 3);

  category(CharCode.latinCapitalLetterAWithDiaeresis)
    ..tag("equipment/armor/boots");
  item("Pair[s] of Boots", tan, frequency: 0.3, price: 70)
    ..depth(14)
    ..armor(6, weight: 1);
  item("Pair[s] of Plated Boots", coolGray, frequency: 0.3, price: 250)
    ..depth(22)
    ..armor(8, weight: 2);
  item("Pair[s] of Greaves", lightCoolGray, frequency: 0.25, price: 350)
    ..depth(47)
    ..armor(12, weight: 3);
}
