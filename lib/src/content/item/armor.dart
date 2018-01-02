import 'package:malison/malison.dart';

import '../../hues.dart';
import 'builder.dart';

void helmets() {
  // TODO.
  // CharCode.latinCapitalLetterEWithAcute // helm
//  Leather Cap[s]
//  Chainmail Coif[s]
//  Steel Cap[s]
//  Visored Helm[s]
//  Great Helm[s]
}

void bodyArmor() {
  // TODO: Make some armor throwable.
  // Robes.
  category(CharCode.latinSmallLetterOWithCircumflex)
    ..tag("equipment/armor/body/robe");
  item("Robe", 2, 0.5, cerulean)..armor(4);
  item("Fur-lined Robe", 6, 0.25, sherwood)..armor(6);

  // Soft armor.
  category(CharCode.latinSmallLetterOWithDiaeresis)
    ..tag("equipment/armor/body");
  item("Cloth Shirt", 2, 0.5, sandal)..armor(3);
  item("Leather Shirt", 5, 0.5, persimmon)..armor(6, weight: 1);
  item("Jerkin", 7, 0.5, gunsmoke)..armor(8, weight: 1);
  item("Leather Armor", 10, 0.5, garnet)..armor(11, weight: 2);
  item("Padded Armor", 14, 0.5, steelGray)..armor(15, weight: 3);
  item("Studded Leather Armor", 17, 0.5, slate)..armor(22, weight: 4);

  // Mail armor.
  category(CharCode.latinSmallLetterOWithGrave)..tag("equipment/armor/body");
  item("Mail Hauberk", 20, 0.5, steelGray)..armor(28, weight: 5);
  item("Scale Mail", 23, 0.5, gunsmoke)..armor(36, weight: 7);

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
  item("Cloak", 3, 0.5, ultramarine)..armor(2);
  item("Fur Cloak", 5, 0.2, garnet)..armor(3);
}

void gloves() {
  // CharCode.latinCapitalLetterAWithRingAbove // gloves
  // TODO.
//  Pair[s] of Leather Gloves
//  Set[s] of Bracers
//  Pair[s] of Gauntlets
}

void shields() {
  // CharCode.latinSmallLetterAe // shield
  // TODO.
//  Small Leather Shield[s]
//  Wooden Targe[s]
//  Large Leather Shield[s]
//  Steel Buckler[s]
//  Kite Shield[s]
}

void boots() {
  category(CharCode.latinSmallLetterIWithGrave)..tag("equipment/armor/boots");
  item("Pair[s] of Leather Sandals", 2, 0.24, persimmon)..armor(1);
  item("Pair[s] of Leather Shoes", 8, 0.3, garnet)..armor(2);

  category(CharCode.latinCapitalLetterAWithDiaeresis)
    ..tag("equipment/armor/boots");
  item("Pair[s] of Leather Boots", 14, 0.3, persimmon)..armor(6, weight: 1);
  item("Pair[s] of Metal Shod Boots", 22, 0.3, slate)..armor(8, weight: 2);
  item("Pair[s] of Greaves", 47, 0.25, gunsmoke)..armor(12, weight: 3);
}
