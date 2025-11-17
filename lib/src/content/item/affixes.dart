import '../../engine.dart';
import '../elements.dart';
import 'builder.dart';
import 'items.dart';

class Affixes {
  static final prefixes = ResourceSet<AffixType>();
  static final suffixes = ResourceSet<AffixType>();

  static Iterable<AffixType> get all => [...prefixes.all, ...suffixes.all];

  static AffixType find(String name) {
    for (var affixSet in [prefixes, suffixes]) {
      var affix = affixSet.tryFind(name);
      if (affix != null) return affix;
    }

    throw ArgumentError("Unknown affix '$name'.");
  }

  static AffixType? tryChoose(
    ResourceSet<AffixType> affixes,
    ItemType itemType,
    int depth,
  ) {
    return affixes.tryChooseMatching(depth, Items.types.getTags(itemType.name));
  }

  static void initialize() {
    // TODO: Other races.
    _elven();
    _dwarven();
    _resists();
    _extraDamage();
    _brands();

    // TODO: "of Accuracy" increases range of bows.
    // TODO: "Heavy" and "adamant" increase weight and armor.
    // TODO: More stat bonus affixes.

    affixCategory("helm");
    affix("_ of Acumen")
      ..depth(35, to: 55)
      ..parameter(1, boostOneIn: 4)
      ..price(300, 2.0)
      ..intellect(equalsParam);
    affix("_ of Wisdom")
      ..depth(45, to: 75)
      ..parameter(2, max: 3, boostOneIn: 4)
      ..price(500, 3.0)
      ..intellect(equalsParam);
    affix("_ of Sagacity")
      ..depth(75)
      ..parameter(4, max: 5, boostOneIn: 4)
      ..price(700, 4.0)
      ..intellect(equalsParam);
    affix("_ of Genius")
      ..depth(85)
      ..parameter(6, max: 7, boostOneIn: 4)
      ..price(1000, 5.0)
      ..intellect(equalsParam);

    finishAffix();
  }

  static void _elven() {
    affixCategory("body");
    affix("Elven _")
      ..depth(40)
      ..parameter(2, max: 3, boostOneIn: 4)
      ..price(400, 2.0)
      ..weight(-2)
      ..armor(equalsParam)
      ..resist(Elements.light);
    affix("High Elven _", frequency: 0.3)
      ..depth(60)
      ..parameter(4, max: 6, boostOneIn: 4)
      ..price(600, 3.0)
      ..weight(-3)
      ..armor(equalsParam)
      ..agility(fixed(1))
      ..resist(Elements.air)
      ..resist(Elements.light);

    affixCategory("cloak");
    affix("Elven _")
      ..depth(40, to: 80)
      ..parameter(4, max: 6, boostOneIn: 4)
      ..price(300, 2.0)
      ..weight(-1)
      ..armor(equalsParam)
      ..resist(Elements.light);
    affix("High Elven _", frequency: 0.3)
      ..depth(60)
      ..parameter(5, max: 8, boostOneIn: 4)
      ..price(500, 3.0)
      ..weight(-2)
      ..armor(equalsParam)
      ..agility(fixed(2))
      ..resist(Elements.air)
      ..resist(Elements.light);

    affixCategory("boots");
    affix("Elven _")
      ..depth(50)
      ..parameter(2, max: 5, boostOneIn: 4)
      ..price(400, 2.5)
      ..weight(-2)
      ..armor(equalsParam);
    // TODO: Increase dodge.

    affixCategory("helm");
    affix("Elven _")
      ..depth(40, to: 80)
      ..parameter(1, max: 3, boostOneIn: 4)
      ..price(400, 2.0)
      ..weight(-1)
      ..armor(equalsParam)
      ..intellect(fixed(1))
      ..resist(Elements.light);
    // TODO: Emanate.
    affix("High Elven _", frequency: 0.3)
      ..depth(60)
      ..parameter(2, boostOneIn: 4)
      ..price(600, 3.0)
      ..weight(-1)
      ..armor(equalsParam)
      ..intellect(equalsParam)
      ..resist(Elements.air)
      ..resist(Elements.light);
    // TODO: Emanate.

    affixCategory("shield");
    affix("Elven _")
      ..depth(40, to: 80)
      ..parameter(3, max: 5, boostOneIn: 4)
      ..price(300, 1.6)
      ..heft(0.8)
      ..damage(scale: scaleParam())
      ..resist(Elements.light);
    affix("High Elven _", frequency: 0.5)
      ..depth(50)
      ..parameter(1, boostOneIn: 4)
      ..price(500, 2.2)
      ..heft(0.6)
      ..damage(scale: fixed(1.5))
      ..will(equalsParam)
      ..resist(Elements.air)
      ..resist(Elements.light);
  }

  static void _dwarven() {
    // TODO: These prices need tuning.
    affixCategory("body");
    affix("Dwarven _")
      ..depth(30)
      ..parameter(4, max: 6, boostOneIn: 3)
      ..price(400, 2.0)
      ..weight(2)
      ..armor(equalsParam)
      ..resist(Elements.earth)
      ..resist(Elements.dark);

    affixCategory("helm");
    affix("Dwarven _")
      ..depth(50)
      ..parameter(3, max: 5, boostOneIn: 4)
      ..price(300, 2.0)
      ..weight(1)
      ..armor(equalsParam)
      ..resist(Elements.earth)
      ..resist(Elements.dark);

    affixCategory("gloves");
    affix("Dwarven _")
      ..depth(50)
      ..price(300, 2.0)
      ..parameter(2, max: 4, boostOneIn: 4)
      ..weight(1)
      // TODO: Encumbrance.
      ..armor(equalsParam)
      ..strength(fixed(1))
      ..resist(Elements.earth)
      ..resist(Elements.dark);

    affixCategory("boots");
    affix("Dwarven _")
      ..depth(50)
      ..parameter(3, max: 5, boostOneIn: 4)
      ..price(300, 2.0)
      ..weight(1)
      ..armor(equalsParam)
      ..resist(Elements.earth)
      ..resist(Elements.dark);

    affixCategory("shield");
    affix("Dwarven _")
      ..depth(40)
      ..parameter(4, max: 8, boostOneIn: 3)
      ..price(200, 2.2)
      ..heft(1.2)
      ..damage(scale: scaleParam(), bonus: equalsParam)
      ..resist(Elements.earth)
      ..resist(Elements.dark);
  }

  static void _resists() {
    // TODO: Don't apply to all armor types?
    affixCategory("armor");
    affix("_ of Resist Air", frequency: 0.5)
      ..depth(10, to: 50)
      ..price(200, 1.2)
      ..resist(Elements.air);
    affix("_ of Resist Earth", frequency: 0.5)
      ..depth(11, to: 51)
      ..price(230, 1.2)
      ..resist(Elements.earth);
    affix("_ of Resist Fire", frequency: 0.5)
      ..depth(12, to: 52)
      ..price(260, 1.3)
      ..resist(Elements.fire);
    affix("_ of Resist Water", frequency: 0.5)
      ..depth(13, to: 53)
      ..price(310, 1.2)
      ..resist(Elements.water);
    affix("_ of Resist Acid", frequency: 0.3)
      ..depth(14, to: 54)
      ..price(340, 1.3)
      ..resist(Elements.acid);
    affix("_ of Resist Cold", frequency: 0.5)
      ..depth(15, to: 55)
      ..price(400, 1.2)
      ..resist(Elements.cold);
    affix("_ of Resist Lightning", frequency: 0.3)
      ..depth(16, to: 56)
      ..price(430, 1.2)
      ..resist(Elements.lightning);
    affix("_ of Resist Poison", frequency: 0.25)
      ..depth(17, to: 57)
      ..price(460, 1.5)
      ..resist(Elements.poison);
    affix("_ of Resist Dark", frequency: 0.25)
      ..depth(18, to: 58)
      ..price(490, 1.3)
      ..resist(Elements.dark);
    affix("_ of Resist Light", frequency: 0.25)
      ..depth(19, to: 59)
      ..price(490, 1.3)
      ..resist(Elements.light);
    affix("_ of Resist Spirit", frequency: 0.4)
      ..depth(10, to: 60)
      ..price(520, 1.4)
      ..resist(Elements.spirit);

    affix("_ of Resist Nature", frequency: 0.3)
      ..depth(40)
      ..price(3000, 4.0)
      ..resist(Elements.air)
      ..resist(Elements.earth)
      ..resist(Elements.fire)
      ..resist(Elements.water)
      ..resist(Elements.cold)
      ..resist(Elements.lightning);

    affix("_ of Resist Destruction", frequency: 0.3)
      ..depth(40)
      ..price(1300, 2.6)
      ..resist(Elements.acid)
      ..resist(Elements.fire)
      ..resist(Elements.lightning)
      ..resist(Elements.poison);

    affix("_ of Resist Evil", frequency: 0.3)
      ..depth(60)
      ..price(1500, 3.0)
      ..resist(Elements.acid)
      ..resist(Elements.poison)
      ..resist(Elements.dark)
      ..resist(Elements.spirit);

    affix("_ of Resistance", frequency: 0.3)
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

    affix("_ of Protection from Air", frequency: 0.25)
      ..depth(36)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.4)
      ..resist(Elements.air, equalsParam);
    affix("_ of Protection from Earth", frequency: 0.25)
      ..depth(37)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.4)
      ..resist(Elements.earth, equalsParam);
    affix("_ of Protection from Fire", frequency: 0.25)
      ..depth(38)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.5)
      ..resist(Elements.fire, equalsParam);
    affix("_ of Protection from Water", frequency: 0.25)
      ..depth(39)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.4)
      ..resist(Elements.water, equalsParam);
    affix("_ of Protection from Acid", frequency: 0.2)
      ..depth(40)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.5)
      ..resist(Elements.acid, equalsParam);
    affix("_ of Protection from Cold", frequency: 0.25)
      ..depth(41)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.4)
      ..resist(Elements.cold, equalsParam);
    affix("_ of Protection from Lightning", frequency: 0.16)
      ..depth(42)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.4)
      ..resist(Elements.lightning, equalsParam);
    affix("_ of Protection from Poison", frequency: 0.14)
      ..depth(43)
      ..parameter(2, boostOneIn: 5)
      ..price(1000, 1.6)
      ..resist(Elements.poison, equalsParam);
    affix("_ of Protection from Dark", frequency: 0.14)
      ..depth(44)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.5)
      ..resist(Elements.dark, equalsParam);
    affix("_ of Protection from Light", frequency: 0.14)
      ..depth(45)
      ..parameter(2, boostOneIn: 5)
      ..price(500, 1.5)
      ..resist(Elements.light, equalsParam);
    affix("_ of Protection from Spirit", frequency: 0.13)
      ..depth(46)
      ..parameter(2, boostOneIn: 5)
      ..price(800, 1.6)
      ..resist(Elements.spirit, equalsParam);
  }

  static void _extraDamage() {
    // TODO: Exclude bows?
    affixCategory("weapon");
    affix("_ of Harming")
      ..depth(1, to: 30)
      ..parameter(1, max: 2, boostOneIn: 3)
      ..price(100, 1.2)
      ..heft(1.05)
      ..damage(bonus: equalsParam);
    affix("_ of Wounding")
      ..depth(10, to: 50)
      ..parameter(3, max: 5, boostOneIn: 3)
      ..price(140, 1.3)
      ..heft(1.07)
      ..damage(bonus: equalsParam);
    affix("_ of Maiming")
      ..depth(25, to: 75)
      ..parameter(2, max: 4, boostOneIn: 3)
      ..price(180, 1.5)
      ..heft(1.09)
      ..damage(scale: scaleParam(), bonus: equalsParam);
    affix("_ of Slaying")
      ..depth(45)
      ..parameter(4, max: 8, boostOneIn: 2)
      ..price(200, 2.0)
      ..heft(1.11)
      ..damage(scale: scaleParam(), bonus: equalsParam);

    affixCategory("bow");
    affix("Ash _")
      ..depth(10, to: 70)
      ..parameter(2, max: 4, boostOneIn: 4)
      ..price(300, 1.3)
      ..heft(0.8)
      ..damage(bonus: equalsParam);
    affix("Yew _")
      ..depth(20)
      ..parameter(5, max: 8, boostOneIn: 3)
      ..price(500, 1.4)
      ..heft(0.8)
      ..damage(bonus: equalsParam);
  }

  static void _brands() {
    affixCategory("weapon");

    affix("Glimmering _", frequency: 0.3)
      ..depth(20, to: 60)
      ..parameter(2, max: 3, boostOneIn: 3)
      ..price(300, 1.3)
      ..damage(scale: scaleParam())
      ..brand(Elements.light);
    affix("Shining _", frequency: 0.25)
      ..depth(32, to: 90)
      ..parameter(4, max: 5, boostOneIn: 3)
      ..price(400, 1.6)
      ..damage(scale: scaleParam())
      ..brand(Elements.light);
    affix("Radiant _", frequency: 0.2)
      ..depth(48)
      ..parameter(6, max: 8, boostOneIn: 3)
      ..price(500, 2.0)
      ..damage(scale: scaleParam())
      ..brand(Elements.light, resist: 2);

    affix("Dim _", frequency: 0.3)
      ..depth(16, to: 60)
      ..parameter(2, max: 3, boostOneIn: 3)
      ..price(300, 1.3)
      ..damage(scale: scaleParam())
      ..brand(Elements.dark);
    affix("Dark _", frequency: 0.25)
      ..depth(32, to: 80)
      ..parameter(4, max: 5, boostOneIn: 3)
      ..price(400, 1.6)
      ..damage(scale: scaleParam())
      ..brand(Elements.dark);
    affix("Black _", frequency: 0.2)
      ..depth(56)
      ..parameter(6, max: 8, boostOneIn: 3)
      ..price(500, 2.0)
      ..damage(scale: scaleParam())
      ..brand(Elements.dark, resist: 2);

    affix("Chilling _", frequency: 0.3)
      ..depth(20, to: 65)
      ..parameter(4, max: 6, boostOneIn: 3)
      ..price(300, 1.5)
      ..damage(scale: scaleParam())
      ..brand(Elements.cold);
    affix("Freezing _", frequency: 0.25)
      ..depth(40)
      ..parameter(6, max: 9, boostOneIn: 3)
      ..price(400, 1.7)
      ..damage(scale: scaleParam())
      ..brand(Elements.cold, resist: 2);

    affix("Burning _", frequency: 0.3)
      ..depth(20, to: 60)
      ..parameter(3, max: 5, boostOneIn: 3)
      ..price(300, 1.5)
      ..damage(scale: scaleParam())
      ..brand(Elements.fire);
    affix("Flaming _", frequency: 0.25)
      ..depth(40, to: 90)
      ..parameter(6, max: 7, boostOneIn: 3)
      ..price(360, 1.8)
      ..damage(scale: scaleParam())
      ..brand(Elements.fire);
    affix("Searing _", frequency: 0.2)
      ..depth(60)
      ..parameter(8, max: 11, boostOneIn: 3)
      ..price(500, 2.1)
      ..damage(scale: scaleParam())
      ..brand(Elements.fire, resist: 2);

    affix("Electric _", frequency: 0.2)
      ..depth(50)
      ..parameter(4, max: 7, boostOneIn: 3)
      ..price(300, 1.5)
      ..damage(scale: scaleParam())
      ..brand(Elements.lightning);
    affix("Shocking _", frequency: 0.2)
      ..depth(70)
      ..parameter(8, max: 11, boostOneIn: 3)
      ..price(400, 2.0)
      ..damage(scale: scaleParam())
      ..brand(Elements.lightning, resist: 2);

    affix("Poisonous _", frequency: 0.2)
      ..depth(35, to: 90)
      ..parameter(1, max: 2, boostOneIn: 4)
      ..price(500, 1.5)
      ..damage(scale: scaleParam())
      ..brand(Elements.poison);
    affix("Venomous _", frequency: 0.2)
      ..depth(70)
      ..parameter(3, max: 5, boostOneIn: 4)
      ..price(800, 1.8)
      ..damage(scale: scaleParam())
      ..brand(Elements.poison, resist: 2);

    affix("Ghostly _", frequency: 0.2)
      ..depth(45, to: 85)
      ..parameter(4, max: 6, boostOneIn: 3)
      ..price(300, 1.6)
      ..heft(0.7)
      ..damage(scale: scaleParam())
      ..brand(Elements.spirit);
    affix("Spiritual _", frequency: 0.15)
      ..depth(80)
      ..parameter(7, max: 10, boostOneIn: 3)
      ..price(400, 2.1)
      ..heft(0.7)
      ..damage(scale: scaleParam())
      ..brand(Elements.spirit, resist: 2);
  }

  static void defineItemTag(String tag) {
    prefixes.defineTags(tag);
    suffixes.defineTags(tag);
  }
}
