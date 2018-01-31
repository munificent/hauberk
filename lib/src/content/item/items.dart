import '../../engine.dart';
import 'armor.dart';
import 'builder.dart';
import 'magic.dart';
import 'other.dart';
import 'weapons.dart';

/// Static class containing all of the [ItemType]s.
class Items {
  static final types = new ResourceSet<ItemType>();

  static void initialize() {
    types.defineTags("item");

    litter();
    treasure();
    pelts();
    potions();
    scrolls();
    spellBooks();
    // TODO: Rings.
    // TODO: Amulets.
    // TODO: Wands.
    weapons();
    lightSources();
    helmets();
    bodyArmor();
    cloaks();
    gloves();
    shields();
    boots();

    // CharCode.latinSmallLetterIWithDiaeresis // ring
    // CharCode.latinSmallLetterIWithCircumflex // wand

    finishItem();
  }
}
