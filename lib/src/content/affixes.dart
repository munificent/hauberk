import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'items.dart';

class Affixes {
  static final _prefixes = new ResourceSet<Affix>();
  static final _suffixes = new ResourceSet<Affix>();

  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType, int depth) {
    // Untagged items don't have any affixes.
    if (Items.types.getTags(itemType.name).isEmpty) return new Item(itemType, 1);

    // There's a chance of no affixes at all, based on the depth.
    // TODO: Allow some drops to modify this.
    if (rng.range(100) >= depth) return new Item(itemType, 1);

    // Give items a chance to boost their effective level when choosing a
    // affixes.
    var affixDepth = math.max(depth, itemType.depth) + rng.taper(0, 2);

    var prefix = _chooseAffix(_prefixes, itemType, affixDepth);
    var suffix = _chooseAffix(_suffixes, itemType, affixDepth);

    // Decide if the item may have just a prefix, just a suffix, or (rarely)
    // both. This is mainly to make dual-affix items less common since they
    // look a bit funny.
    switch (rng.range(5)) {
      case 0:
      case 1:
        return new Item(itemType, 1, prefix, null);
      case 2:
      case 3:
        return new Item(itemType, 1, null, suffix);
      default:
        return new Item(itemType, 1, prefix, suffix);
    }
  }

  static Affix find(String name) {
    var type = _prefixes.tryFind(name);
    if (type != null) return type;

    return _suffixes.find(name);
  }

  static Affix _chooseAffix(
      ResourceSet<Affix> affixes, ItemType itemType, int depth) {
    return affixes.tryChooseMatching(depth, Items.types.getTags(itemType.name));
  }

  static void initialize() {
    _resists();
    _extraDamage();
    _brands();

    // TODO: "of Accuracy" increases range of bows.
  }

  static void _resists() {
    _resistWeak(Element.air, 10, 2);
    _resistWeak(Element.earth, 11, 2);
    _resistWeak(Element.fire, 12, 2);
    _resistWeak(Element.water, 13, 2);
    _resistWeak(Element.acid, 14, 3);
    _resistWeak(Element.cold, 15, 2);
    _resistWeak(Element.lightning, 16, 3);
    _resistWeak(Element.poison, 17, 4);
    _resistWeak(Element.dark, 18, 4);
    _resistWeak(Element.light, 19, 4);
    _resistWeak(Element.spirit, 20, 5);

    _resistStrong(Element.air, 16, 4);
    _resistStrong(Element.earth, 17, 4);
    _resistStrong(Element.fire, 18, 4);
    _resistStrong(Element.water, 19, 4);
    _resistStrong(Element.acid, 20, 5);
    _resistStrong(Element.cold, 21, 4);
    _resistStrong(Element.lightning, 22, 6);
    _resistStrong(Element.poison, 23, 7);
    _resistStrong(Element.dark, 24, 7);
    _resistStrong(Element.light, 25, 7);
    _resistStrong(Element.spirit, 26, 8);
  }

  static void _extraDamage() {
    // TODO: Should these scale damage?
    damage("weapon", "of Harming", 8, 1, damage: 1);
    damage("weapon", "of Wounding", 15, 1, damage: 2);
    damage("weapon", "of Maiming", 35, 1, damage: 3);
    damage("weapon", "of Slaying", 65, 1, damage: 5);

    damage("bow", "Ash", 10, 1, damage: 3);
    damage("bow", "Yew", 20, 1, damage: 5);
  }

  static void _brands() {
    // TODO: Should these grant resistance to their element too?
    brand("Glimmering", 20, 3, Element.light, scale: 1.5);
    brand("Shining", 32, 4, Element.light, scale: 2.0);
    brand("Radiant", 48, 5, Element.light, scale: 2.5);

    brand("Dim", 16, 3, Element.dark, scale: 1.5);
    brand("Dark", 32, 4, Element.dark, scale: 2.0);
    brand("Black", 56, 5, Element.dark, scale: 2.5);

    brand("Freezing", 20, 3, Element.cold, scale: 2.0);

    brand("Burning", 20, 3, Element.fire, scale: 1.5);
    brand("Flaming", 40, 4, Element.fire, scale: 2.0);
    brand("Searing", 60, 5, Element.fire, scale: 2.5);

    brand("Electric", 50, 5, Element.lightning, scale: 2.0);
    brand("Shocking", 70, 5, Element.lightning, scale: 3.0);

    brand("Poisoned", 35, 5, Element.poison, scale: 1.5);
    brand("Venomous", 70, 5, Element.poison, scale: 2.0);

    brand("Ghostly", 45, 5, Element.spirit, scale: 2.0);
    brand("Spiritual", 80, 8, Element.spirit, scale: 3.0);
  }

  static void defineItemTag(String tag) {
    _prefixes.defineTags(tag);
    _suffixes.defineTags(tag);
  }

  static void _resistWeak(Element element, int depth, int rarity) {
    _resist("of Resist ${element.capitalized}", depth, rarity, element, 1);
  }

  static void _resistStrong(Element element, int depth, int rarity) {
    _resist("of Protection from ${element.capitalized}", depth, rarity, element, 2);
  }

  static void _resist(String name, int depth, int rarity, Element element, int power) {
    // Also boost armor a little.
    var affix = new Affix(name, armor: power);
    affix.resists[element] = power;

    // TODO: Don't apply to all armor types?
    _suffixes.add(name, affix, depth, rarity, "armor");
  }

  /// A weapon suffix for adding damage.
  static void damage(String tag, String name, int depth, int rarity, {int damage}) {
    var affix = new Affix(name, damageBonus: damage);
    _suffixes.add(name, affix, depth, rarity, tag);
  }

  /// A weapon prefix for giving an elemental brand.
  static void brand(String name, int depth, int rarity, Element element,
      {double scale}) {
    var affix = new Affix(name, damageScale: scale, brand: element);
    _prefixes.add(name, affix, depth, rarity, "weapon");
  }
}
