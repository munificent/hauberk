import 'package:malison/malison.dart';

import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void helms() {
  category(CharCode.latinCapitalLetterEWithAcute)
    ..tag("equipment/armor/helm")
    ..toss(damage: 3, range: 5, breakage: 10);
  item("Leather Cap", 4, persimmon, frequency: 0.5, price: 50)
    ..armor(2, weight: 2)
    ..destroy(Elements.fire, chance: 12, fuel: 2);
  item("Chainmail Coif", 7, steelGray, frequency: 0.5, price: 160)
    ..armor(3, weight: 3);
  item("Steel Cap", 12, slate, frequency: 0.5, price: 200)..armor(4, weight: 3);
  item("Visored Helm", 20, gunsmoke, frequency: 0.5, price: 350)
    ..armor(5, weight: 6);
  item("Great Helm", 30, ash, frequency: 0.5, price: 550)..armor(6, weight: 8);
}

void bodyArmor() {
  // Robes.
  category(CharCode.latinSmallLetterOWithCircumflex)
    ..tag("equipment/armor/body/robe");
  item("Robe", 2, cerulean, frequency: 0.5, price: 20)
    ..armor(4)
    ..destroy(Elements.fire, chance: 15, fuel: 8);
  item("Fur-lined Robe", 6, sherwood, frequency: 0.25, price: 80)
    ..armor(6)
    ..destroy(Elements.fire, chance: 12, fuel: 8);

  // Soft armor.
  category(CharCode.latinSmallLetterOWithDiaeresis)
    ..tag("equipment/armor/body");
  item("Cloth Shirt", 2, sandal, frequency: 0.5, price: 40)
    ..armor(3)
    ..destroy(Elements.fire, chance: 15, fuel: 4);
  item("Leather Shirt", 5, persimmon, frequency: 0.5, price: 90)
    ..armor(6, weight: 1)
    ..destroy(Elements.fire, chance: 12, fuel: 4);
  item("Jerkin", 7, gunsmoke, frequency: 0.5, price: 130)..armor(8, weight: 1);
  item("Leather Armor", 10, garnet, frequency: 0.5, price: 240)
    ..armor(11, weight: 2)
    ..destroy(Elements.fire, chance: 10, fuel: 4);
  item("Padded Armor", 14, steelGray, frequency: 0.5, price: 320)
    ..armor(15, weight: 3)
    ..destroy(Elements.fire, chance: 8, fuel: 4);
  item("Studded Armor", 17, slate, frequency: 0.5, price: 400)
    ..armor(22, weight: 4)
    ..destroy(Elements.fire, chance: 6, fuel: 4);

  // Mail armor.
  category(CharCode.latinSmallLetterOWithGrave)..tag("equipment/armor/body");
  item("Mail Hauberk", 20, steelGray, frequency: 0.5, price: 500)
    ..armor(28, weight: 5);
  item("Scale Mail", 23, gunsmoke, frequency: 0.5, price: 700)
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
  item("Cloak", 3, ultramarine, frequency: 0.5, price: 70)
    ..armor(2, weight: 1)
    ..destroy(Elements.fire, chance: 20, fuel: 5);
  item("Fur Cloak", 5, garnet, frequency: 0.2, price: 140)
    ..armor(3, weight: 1)
    ..destroy(Elements.fire, chance: 16, fuel: 5);
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
  item("Pair[s] of Gloves", 4, sandal, frequency: 0.5, price: 170)
    ..armor(2)
    ..destroy(Elements.fire, chance: 7, fuel: 2);
  item("Set[s] of Bracers", 17, garnet, frequency: 0.5, price: 480)
    ..armor(3, weight: 1);
  item("Pair[s] of Gauntlets", 23, steelGray, frequency: 0.5, price: 800)
    ..armor(4, weight: 2);
}

void shields() {
  category(CharCode.latinSmallLetterAe)
    ..tag("equipment/armor/shield")
    ..toss(damage: 5, range: 8, breakage: 10);
  // TODO: Encumbrance.
  item("Small Leather Shield", 3, garnet, frequency: 0.5, price: 170)
    ..armor(3, weight: 2)
    ..destroy(Elements.fire, chance: 7, fuel: 14);
  item("Wooden Targe", 8, sandal, frequency: 0.5, price: 250)
    ..armor(4, weight: 4)
    ..destroy(Elements.fire, chance: 14, fuel: 20);
  item("Large Leather Shield", 17, persimmon, frequency: 0.5, price: 320)
    ..armor(5, weight: 5)
    ..destroy(Elements.fire, chance: 7, fuel: 17);
  item("Steel Buckler", 27, steelGray, frequency: 0.5, price: 450)
    ..armor(6, weight: 6);
  item("Kite Shield", 35, gunsmoke, frequency: 0.5, price: 650)
    ..armor(7, weight: 9);
}

void boots() {
  category(CharCode.latinSmallLetterIWithGrave)..tag("equipment/armor/boots");
  item("Pair[s] of Sandals", 2, persimmon, frequency: 0.24, price: 10)
    ..armor(1)
    ..destroy(Elements.fire, chance: 20, fuel: 3);
  item("Pair[s] of Shoes", 8, garnet, frequency: 0.3, price: 30)
    ..armor(2)
    ..destroy(Elements.fire, chance: 14, fuel: 3);

  category(CharCode.latinCapitalLetterAWithDiaeresis)
    ..tag("equipment/armor/boots");
  item("Pair[s] of Boots", 14, persimmon, frequency: 0.3, price: 70)
    ..armor(6, weight: 1);
  item("Pair[s] of Plated Boots", 22, slate, frequency: 0.3, price: 250)
    ..armor(8, weight: 2);
  item("Pair[s] of Greaves", 47, gunsmoke, frequency: 0.25, price: 350)
    ..armor(12, weight: 3);
}
