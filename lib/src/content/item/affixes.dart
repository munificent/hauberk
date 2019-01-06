import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../elements.dart';
import 'builder.dart';
import 'items.dart';

class Affixes {
  static final prefixes = ResourceSet<Affix>();
  static final suffixes = ResourceSet<Affix>();

  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType, int droppedDepth,
      [int affixChance]) {
    affixChance ??= 0;

    // Only equipped items have affixes.
    if (itemType.equipSlot == null) return Item(itemType, 1);

    // Calculate the effective depth of the item for generating affixes. This
    // affects both the chances of having an affix at all, and which affixes it
    // gets.
    //
    // The basic idea is that an item's overall value should reflect the depth
    // where it's generated. So if an item for a shallower depth appears deeper
    // in the dungeon it is more likely to have an affix to compensate.
    // Likewise, finding a depth 20 item at depth 10 is already a good find, so
    // it's less likely to also have an affix on it.
    var affixDepth = droppedDepth;
    var outOfDepth = itemType.depth - droppedDepth;

    if (outOfDepth > 0) {
      // Generating a stronger item than expected, so it will have weaker
      // affixes.
      affixDepth -= outOfDepth;
    } else {
      // Generating a weaker item than expected, so boost its affix. Reduce the
      // boost as the hero gets deeper in the dungeon. Otherwise, near 100, the
      // boost ends up pushing almost everything past 100 since most equipment
      // has a lower starting depth.
      var weight = lerpDouble(droppedDepth, 1, 100, 0.5, 0.0);
      affixDepth -= rng.round(outOfDepth * weight);
    }

    affixDepth = affixDepth.clamp(1, 100);

    // This generates a curve that starts around 1% and slowly ramps upwards.
    var chance = 0.008 * affixDepth * affixDepth + 0.05 * affixDepth + 0.1;

    // See how many affixes the item has. The affixChance only boosts one roll
    // because it increases the odds of *an* affix, but not the odds of
    // multiple.
    var affixes = 0;
    if (rng.float(100.0) < chance + affixChance) affixes++;

    // Make dual-affix items rarer since they are more powerful (they only take
    // a single equipment slot) and also look kind of funny.
    if (rng.float(100.0) < chance && rng.oneIn(5)) affixes++;

    if (affixes == 0) return Item(itemType, 1);

    var prefix = _chooseAffix(prefixes, itemType, affixDepth);
    var suffix = _chooseAffix(suffixes, itemType, affixDepth);

    if (affixes == 1 && prefix != null && suffix != null) {
      if (rng.oneIn(2)) {
        prefix = null;
      } else {
        suffix = null;
      }
    }

    return Item(itemType, 1, prefix, suffix);
  }

  static Affix find(String name) {
    var type = prefixes.tryFind(name);
    if (type != null) return type;

    return suffixes.find(name);
  }

  static Affix _chooseAffix(
      ResourceSet<Affix> affixes, ItemType itemType, int depth) {
    return affixes.tryChooseMatching(depth, Items.types.getTags(itemType.name));
  }

  static void initialize() {
    _elven();
    _dwarven();
    _resists();
    _extraDamage();
    _brands();
    // TODO: "of Accuracy" increases range of bows.
    // TODO: "Heavy" and "adamant" increase weight and armor.
    // TODO: More stat bonus affixes.

    affixCategory("helm");
    for (var i = 0; i < 2; i++) {
      affix("_ of Acumen", 1.0)
        ..depth(35, to: 55)
        ..price(300, 2.0)
        ..intellect(1 + i);
      affix("_ of Wisdom", 1.0)
        ..depth(45, to: 75)
        ..price(500, 3.0)
        ..intellect(3 + i);
      affix("_ of Sagacity", 1.0)
        ..depth(75)
        ..price(700, 4.0)
        ..intellect(5 + i);
      affix("_ of Genius", 1.0)
        ..depth(65)
        ..price(1000, 5.0)
        ..intellect(7 + i);
    }

    finishAffix();
  }

  static void _elven() {
    affixCategory("body");
    affix("Elven _", 1.0)
      ..depth(40, to: 80)
      ..price(400, 2.0)
      ..weight(-2)
      ..armor(2)
      ..resist(Elements.light);
    affix("Elven _", 0.3)
      ..depth(60)
      ..price(600, 3.0)
      ..weight(-3)
      ..armor(4)
      ..resist(Elements.light);

    affixCategory("cloak");
    affix("Elven _", 1.0)
      ..depth(40, to: 80)
      ..price(300, 2.0)
      ..weight(-1)
      ..armor(3)
      ..resist(Elements.light);
    affix("Elven _", 0.3)
      ..depth(60)
      ..price(500, 3.0)
      ..weight(-2)
      ..armor(5)
      ..resist(Elements.light);

    affixCategory("boots");
    affix("Elven _", 1.0)
      ..depth(50)
      ..price(400, 2.5)
      ..weight(-2)
      ..armor(2);
    // TODO: Increase dodge.

    affixCategory("helm");
    affix("Elven _", 1.0)
      ..depth(40, to: 80)
      ..price(400, 2.0)
      ..weight(-1)
      ..armor(1)
      ..intellect(1)
      ..resist(Elements.light);
    // TODO: Emanate.
    affix("Elven _", 0.3)
      ..depth(60)
      ..price(600, 3.0)
      ..weight(-1)
      ..armor(2)
      ..intellect(2)
      ..resist(Elements.light);
    // TODO: Emanate.

    affixCategory("shield");
    affix("Elven _", 1.0)
      ..depth(40, to: 80)
      ..price(300, 1.6)
      ..heft(0.8)
      ..damage(scale: 1.3)
      ..resist(Elements.light);
    affix("Elven _", 0.5)
      ..depth(50)
      ..price(500, 2.2)
      ..heft(0.6)
      ..damage(scale: 1.5)
      ..will(1)
      ..resist(Elements.light);
  }

  static void _dwarven() {
    // TODO: These prices need tuning.
    affixCategory("body");
    affix("Dwarven _", 1.0)
      ..depth(30, to: 70)
      ..price(400, 2.0)
      ..weight(2)
      ..armor(4)
      ..resist(Elements.earth)
      ..resist(Elements.dark);
    affix("Dwarven _", 0.5)
      ..depth(40)
      ..price(600, 3.0)
      ..weight(2)
      ..armor(6)
      ..resist(Elements.earth)
      ..resist(Elements.dark);

    affixCategory("helm");
    affix("Dwarven _", 1.0)
      ..depth(50, to: 80)
      ..price(300, 2.0)
      ..weight(1)
      ..armor(3)
      ..resist(Elements.dark);
    affix("Dwarven _", 0.5)
      ..depth(60)
      ..price(500, 3.0)
      ..weight(1)
      ..armor(4)
      ..strength(1)
      ..fortitude(1)
      ..resist(Elements.dark);

    affixCategory("gloves");
    affix("Dwarven _", 1.0)
      ..depth(50)
      ..price(300, 2.0)
      ..weight(1)
      // TODO: Encumbrance.
      ..armor(3)
      ..strength(1)
      ..resist(Elements.earth);

    affixCategory("boots");
    affix("Dwarven _", 1.0)
      ..depth(50, to: 70)
      ..price(300, 2.0)
      ..weight(1)
      ..armor(3)
      ..resist(Elements.earth);
    affix("Dwarven _", 0.3)
      ..depth(60)
      ..price(500, 3.0)
      ..weight(2)
      ..armor(5)
      ..fortitude(1)
      ..resist(Elements.dark)
      ..resist(Elements.earth);

    affixCategory("shield");
    affix("Dwarven _", 1.0)
      ..depth(40, to: 80)
      ..price(200, 2.2)
      ..heft(1.2)
      ..damage(scale: 1.5, bonus: 4)
      ..resist(Elements.earth)
      ..resist(Elements.dark);
    affix("Dwarven _", 1.0)
      ..depth(60)
      ..price(400, 2.4)
      ..heft(1.3)
      ..damage(scale: 1.7, bonus: 5)
      ..fortitude(1)
      ..resist(Elements.earth)
      ..resist(Elements.dark);
  }

  static void _resists() {
    // TODO: Don't apply to all armor types?
    affixCategory("armor");
    affix("_ of Resist Air", 0.5)
      ..depth(10, to: 50)
      ..price(200, 1.2)
      ..resist(Elements.air);
    affix("_ of Resist Earth", 0.5)
      ..depth(11, to: 51)
      ..price(230, 1.2)
      ..resist(Elements.earth);
    affix("_ of Resist Fire", 0.5)
      ..depth(12, to: 52)
      ..price(260, 1.3)
      ..resist(Elements.fire);
    affix("_ of Resist Water", 0.5)
      ..depth(13, to: 53)
      ..price(310, 1.2)
      ..resist(Elements.water);
    affix("_ of Resist Acid", 0.3)
      ..depth(14, to: 54)
      ..price(340, 1.3)
      ..resist(Elements.acid);
    affix("_ of Resist Cold", 0.5)
      ..depth(15, to: 55)
      ..price(400, 1.2)
      ..resist(Elements.cold);
    affix("_ of Resist Lightning", 0.3)
      ..depth(16, to: 56)
      ..price(430, 1.2)
      ..resist(Elements.lightning);
    affix("_ of Resist Poison", 0.25)
      ..depth(17, to: 57)
      ..price(460, 1.5)
      ..resist(Elements.poison);
    affix("_ of Resist Dark", 0.25)
      ..depth(18, to: 58)
      ..price(490, 1.3)
      ..resist(Elements.dark);
    affix("_ of Resist Light", 0.25)
      ..depth(19, to: 59)
      ..price(490, 1.3)
      ..resist(Elements.light);
    affix("_ of Resist Spirit", 0.4)
      ..depth(10, to: 60)
      ..price(520, 1.4)
      ..resist(Elements.spirit);

    affix("_ of Resist Nature", 0.3)
      ..depth(40)
      ..price(3000, 4.0)
      ..resist(Elements.air)
      ..resist(Elements.earth)
      ..resist(Elements.fire)
      ..resist(Elements.water)
      ..resist(Elements.cold)
      ..resist(Elements.lightning);

    affix("_ of Resist Destruction", 0.3)
      ..depth(40)
      ..price(1300, 2.6)
      ..resist(Elements.acid)
      ..resist(Elements.fire)
      ..resist(Elements.lightning)
      ..resist(Elements.poison);

    affix("_ of Resist Evil", 0.3)
      ..depth(60)
      ..price(1500, 3.0)
      ..resist(Elements.acid)
      ..resist(Elements.poison)
      ..resist(Elements.dark)
      ..resist(Elements.spirit);

    affix("_ of Resistance", 0.3)
      ..depth(70)
      ..price(5000, 6.0)
      ..resist(Elements.air)
      ..resist(Elements.earth)
      ..resist(Elements.fire)
      ..resist(Elements.water)
      ..resist(Elements.acid)
      ..resist(Elements.cold)
      ..resist(Elements.lightning)
      ..resist(Elements.poison)
      ..resist(Elements.dark)
      ..resist(Elements.light)
      ..resist(Elements.spirit);

    affix("_ of Protection from Air", 0.25)
      ..depth(36)
      ..price(500, 1.4)
      ..resist(Elements.air, 2);
    affix("_ of Protection from Earth", 0.25)
      ..depth(37)
      ..price(500, 1.4)
      ..resist(Elements.earth, 2);
    affix("_ of Protection from Fire", 0.25)
      ..depth(38)
      ..price(500, 1.5)
      ..resist(Elements.fire, 2);
    affix("_ of Protection from Water", 0.25)
      ..depth(39)
      ..price(500, 1.4)
      ..resist(Elements.water, 2);
    affix("_ of Protection from Acid", 0.2)
      ..depth(40)
      ..price(500, 1.5)
      ..resist(Elements.acid, 2);
    affix("_ of Protection from Cold", 0.25)
      ..depth(41)
      ..price(500, 1.4)
      ..resist(Elements.cold, 2);
    affix("_ of Protection from Lightning", 0.16)
      ..depth(42)
      ..price(500, 1.4)
      ..resist(Elements.lightning, 2);
    affix("_ of Protection from Poison", 0.14)
      ..depth(43)
      ..price(1000, 1.6)
      ..resist(Elements.poison, 2);
    affix("_ of Protection from Dark", 0.14)
      ..depth(44)
      ..price(500, 1.5)
      ..resist(Elements.dark, 2);
    affix("_ of Protection from Light", 0.14)
      ..depth(45)
      ..price(500, 1.5)
      ..resist(Elements.light, 2);
    affix("_ of Protection from Spirit", 0.13)
      ..depth(46)
      ..price(800, 1.6)
      ..resist(Elements.spirit, 2);
  }

  static void _extraDamage() {
    // TODO: Exclude bows?
    affixCategory("weapon");
    affix("_ of Harming", 1.0)
      ..depth(1, to: 30)
      ..price(100, 1.2)
      ..heft(1.05)
      ..damage(bonus: 1);
    affix("_ of Wounding", 1.0)
      ..depth(10, to: 50)
      ..price(140, 1.3)
      ..heft(1.07)
      ..damage(bonus: 3);
    affix("_ of Maiming", 1.0)
      ..depth(25, to: 75)
      ..price(180, 1.5)
      ..heft(1.09)
      ..damage(scale: 1.2, bonus: 3);
    affix("_ of Slaying", 1.0)
      ..depth(45)
      ..price(200, 2.0)
      ..heft(1.11)
      ..damage(scale: 1.4, bonus: 5);

    affixCategory("bow");
    affix("Ash _", 1.0)
      ..depth(10, to: 70)
      ..price(300, 1.3)
      ..heft(0.8)
      ..damage(bonus: 3);
    affix("Yew _", 1.0)
      ..depth(20)
      ..price(500, 1.4)
      ..heft(0.8)
      ..damage(bonus: 5);
  }

  static void _brands() {
    affixCategory("weapon");

    affix("Glimmering _", 0.3)
      ..depth(20, to: 60)
      ..price(300, 1.3)
      ..damage(scale: 1.2)
      ..brand(Elements.light);
    affix("Shining _", 0.25)
      ..depth(32, to: 90)
      ..price(400, 1.6)
      ..damage(scale: 1.4)
      ..brand(Elements.light);
    affix("Radiant _", 0.2)
      ..depth(48)
      ..price(500, 2.0)
      ..damage(scale: 1.6)
      ..brand(Elements.light, resist: 2);

    affix("Dim _", 0.3)
      ..depth(16, to: 60)
      ..price(300, 1.3)
      ..damage(scale: 1.2)
      ..brand(Elements.dark);
    affix("Dark _", 0.25)
      ..depth(32, to: 80)
      ..price(400, 1.6)
      ..damage(scale: 1.4)
      ..brand(Elements.dark);
    affix("Black _", 0.2)
      ..depth(56)
      ..price(500, 2.0)
      ..damage(scale: 1.6)
      ..brand(Elements.dark, resist: 2);

    affix("Chilling _", 0.3)
      ..depth(20, to: 65)
      ..price(300, 1.5)
      ..damage(scale: 1.4)
      ..brand(Elements.cold);
    affix("Freezing _", 0.25)
      ..depth(40)
      ..price(400, 1.7)
      ..damage(scale: 1.6)
      ..brand(Elements.cold, resist: 2);

    affix("Burning _", 0.3)
      ..depth(20, to: 60)
      ..price(300, 1.5)
      ..damage(scale: 1.3)
      ..brand(Elements.fire);
    affix("Flaming _", 0.25)
      ..depth(40, to: 90)
      ..price(360, 1.8)
      ..damage(scale: 1.6)
      ..brand(Elements.fire);
    affix("Searing _", 0.2)
      ..depth(60)
      ..price(500, 2.1)
      ..damage(scale: 1.8)
      ..brand(Elements.fire, resist: 2);

    affix("Electric _", 0.2)
      ..depth(50)
      ..price(300, 1.5)
      ..damage(scale: 1.4)
      ..brand(Elements.lightning);
    affix("Shocking _", 0.2)
      ..depth(70)
      ..price(400, 2.0)
      ..damage(scale: 1.8)
      ..brand(Elements.lightning, resist: 2);

    affix("Poisonous _", 0.2)
      ..depth(35, to: 90)
      ..price(500, 1.5)
      ..damage(scale: 1.1)
      ..brand(Elements.poison);
    affix("Venomous _", 0.2)
      ..depth(70)
      ..price(800, 1.8)
      ..damage(scale: 1.3)
      ..brand(Elements.poison, resist: 2);

    affix("Ghostly _", 0.2)
      ..depth(45, to: 85)
      ..price(300, 1.6)
      ..heft(0.7)
      ..damage(scale: 1.4)
      ..brand(Elements.spirit);
    affix("Spiritual _", 0.15)
      ..depth(80)
      ..price(400, 2.1)
      ..heft(0.7)
      ..damage(scale: 1.7)
      ..brand(Elements.spirit, resist: 2);
  }

  static void defineItemTag(String tag) {
    prefixes.defineTags(tag);
    suffixes.defineTags(tag);
  }
}
