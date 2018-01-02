import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../elements.dart';
import 'items.dart';

class Affixes {
  static final _prefixes = new ResourceSet<Affix>();
  static final _suffixes = new ResourceSet<Affix>();

  static Iterable<Affix> get prefixes => _prefixes.all;
  static Iterable<Affix> get suffixes => _suffixes.all;

  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType, int droppedDepth) {
    // Untagged items don't have any affixes.
    if (Items.types.getTags(itemType.name).isEmpty) {
      return new Item(itemType, 1);
    }

    // The deeper we go, the greater chance of an affix. However, finding a
    // deeper item at a shallower depth reduces its chance of an affix (since
    // the item is already better than expected). Conversely, a weaker item
    // found deeper in the dungeon has a greater chance of an affix to
    // compensate for its weakness.
    var outOfDepth = itemType.depth - droppedDepth;
    var depth = (droppedDepth - outOfDepth ~/ 2).clamp(1, 100);

    // This generates a curve that starts out at 1% and slowly ramps upwards.
    var chance = 1 + 0.006 * depth * depth + 0.2 * depth;

    if (!rng.percent(chance.ceil())) return new Item(itemType, 1);

    // Give items a chance to boost their effective level when choosing a
    // affixes.
    var affixDepth = math.max(droppedDepth, itemType.depth) + rng.taper(0, 2);

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
    _resistWeak(Elements.air, 10, 0.5);
    _resistWeak(Elements.earth, 11, 0.5);
    _resistWeak(Elements.fire, 12, 0.5);
    _resistWeak(Elements.water, 13, 0.5);
    _resistWeak(Elements.acid, 14, 0.3);
    _resistWeak(Elements.cold, 15, 0.5);
    _resistWeak(Elements.lightning, 16, 0.3);
    _resistWeak(Elements.poison, 17, 0.25);
    _resistWeak(Elements.dark, 18, 0.25);
    _resistWeak(Elements.light, 19, 0.25);
    _resistWeak(Elements.spirit, 20, 0.4);

    _resistStrong(Elements.air, 16, 0.25);
    _resistStrong(Elements.earth, 17, 0.25);
    _resistStrong(Elements.fire, 18, 0.25);
    _resistStrong(Elements.water, 19, 0.25);
    _resistStrong(Elements.acid, 20, 0.2);
    _resistStrong(Elements.cold, 21, 0.25);
    _resistStrong(Elements.lightning, 22, 0.16);
    _resistStrong(Elements.poison, 23, 0.14);
    _resistStrong(Elements.dark, 24, 0.14);
    _resistStrong(Elements.light, 25, 0.14);
    _resistStrong(Elements.spirit, 26, 0.13);
  }

  static void _extraDamage() {
    // TODO: Should these scale damage?
    damage("weapon", "of Harming", 8, 1.0, damage: 1);
    damage("weapon", "of Wounding", 15, 1.0, damage: 2);
    damage("weapon", "of Maiming", 35, 1.0, damage: 3);
    damage("weapon", "of Slaying", 65, 1.0, damage: 5);

    damage("bow", "Ash", 10, 1.0, damage: 3);
    damage("bow", "Yew", 20, 1.0, damage: 5);
  }

  static void _brands() {
    // TODO: Should these grant resistance to their element too?
    brand("Glimmering", 20, 0.3, Elements.light, scale: 1.2);
    brand("Shining", 32, 0.25, Elements.light, scale: 1.4);
    brand("Radiant", 48, 0.2, Elements.light, scale: 1.6);

    brand("Dim", 16, 0.3, Elements.dark, scale: 1.2);
    brand("Dark", 32, 0.25, Elements.dark, scale: 1.4);
    brand("Black", 56, 0.2, Elements.dark, scale: 1.6);

    brand("Freezing", 20, 0.3, Elements.cold, scale: 1.5);

    brand("Burning", 20, 0.3, Elements.fire, scale: 1.3);
    brand("Flaming", 40, 0.25, Elements.fire, scale: 1.6);
    brand("Searing", 60, 0.2, Elements.fire, scale: 1.8);

    brand("Electric", 50, 0.2, Elements.lightning, scale: 1.4);
    brand("Shocking", 70, 0.2, Elements.lightning, scale: 1.8);

    brand("Poisoned", 35, 0.2, Elements.poison, scale: 1.1);
    brand("Venomous", 70, 0.2, Elements.poison, scale: 1.3);

    brand("Ghostly", 45, 0.2, Elements.spirit, scale: 1.4);
    brand("Spiritual", 80, 0.15, Elements.spirit, scale: 1.7);
  }

  static void defineItemTag(String tag) {
    _prefixes.defineTags(tag);
    _suffixes.defineTags(tag);
  }

  static void _resistWeak(Element element, int depth, double frequency) {
    _resist("of Resist ${element.capitalized}", depth, frequency, element, 1);
  }

  static void _resistStrong(Element element, int depth, double frequency) {
    _resist("of Protection from ${element.capitalized}", depth, frequency,
        element, 2);
  }

  static void _resist(
      String name, int depth, double frequency, Element element, int power) {
    // Also boost armor a little.
    var affix = new Affix(name, armor: power);
    affix.resist(element, power);

    // TODO: Don't apply to all armor types?
    _suffixes.add(name, affix, depth, frequency, "armor");
  }

  /// A weapon suffix for adding damage.
  static void damage(String tag, String name, int depth, double frequency,
      {int damage}) {
    var affix = new Affix(name, damageBonus: damage);
    _suffixes.add(name, affix, depth, frequency, tag);
  }

  /// A weapon prefix for giving an elemental brand.
  static void brand(String name, int depth, double frequency, Element element,
      {double scale}) {
    var affix = new Affix(name, damageScale: scale, brand: element);
    _prefixes.add(name, affix, depth, frequency, "weapon");
  }
}
