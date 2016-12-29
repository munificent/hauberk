import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';

typedef Attack _CreateAttack();

/// A generic "kind" of affix that can create concrete [Affix] instances.
class _AffixType {
  final String name;
  final _CreateAttack attack;

  _AffixType(this.name, this.attack);
}

class Affixes {
  static final _prefixes = new ResourceSet<_AffixType>();
  static final _suffixes = new ResourceSet<_AffixType>();

  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType) {
    // Untagged items don't have any affixes.
    if (itemType.tags.isEmpty) return new Item(itemType);

    // Give items a chance to boost their effective level when choosing a
    // affixes.
    var depth = rng.taper(itemType.depth, 2);

    var prefix = _chooseAffix(_prefixes, itemType, depth);
    var suffix = _chooseAffix(_suffixes, itemType, depth);

    // Decide if the item may have just a prefix, just a suffix, or (rarely)
    // both. This is mainly to make dual-affix items less common since they
    // look a bit funny.
    switch (rng.range(5)) {
      case 0:
      case 1:
        return new Item(itemType, prefix, null);
      case 2:
      case 3:
        return new Item(itemType, null, suffix);
      default:
        return new Item(itemType, prefix, suffix);
    }
  }

  static Affix _chooseAffix(
      ResourceSet<_AffixType> affixes, ItemType itemType, int depth) {
    var type = affixes.tryChooseAny(depth,
        itemType.tags.map((tag) => tag.name));

    if (type == null) return null;

    var attack = type.attack();
    return new Affix(type.name, attack);
  }

  static void initialize() {
    brand("Glimmering", 12, 3, Element.light, 0, 1.0);
    brand("Shining", 24, 4, Element.light, 2, 1.1);
    brand("Radiant", 48, 5, Element.light, 4, 1.2);

    brand("Dim", 16, 3, Element.dark, 0, 1.1);
    brand("Dark", 32, 4, Element.dark, 1, 1.2);
    brand("Black", 56, 5, Element.dark, 3, 1.3);

    brand("Freezing", 20, 3, Element.cold, 2, 1.2);

    brand("Burning", 20, 3, Element.fire, 2, 1.2);
    brand("Flaming", 40, 4, Element.fire, 4, 1.3);
    brand("Searing", 60, 5, Element.fire, 6, 1.4);

    brand("Electric", 50, 5, Element.lightning, 4, 1.6);
    brand("Shocking", 70, 5, Element.lightning, 6, 1.8);

    brand("Poisoned", 35, 5, Element.poison, 5, 1.3);
    brand("Venomous", 70, 5, Element.poison, 6, 1.5);

    brand("Ghostly", 45, 5, Element.spirit, 3, 1.3);

    // TODO: Should these scale damage?
    damage("of Harming", 8, 1, 1, 4);
    damage("of Wounding", 15, 1, 3, 4);
    damage("of Maiming", 35, 1, 6, 3);
    damage("of Slaying", 65, 1, 10, 3);

    bowDamage("Ash", 10, 1, 3, 4);
    bowDamage("Yew", 20, 1, 5, 3);

    // TODO: "of Accuracy" increases range of bows.
  }

  static void defineItemTag(String tag) {
    _prefixes.defineTags(tag);
    _suffixes.defineTags(tag);
  }

  /// A weapon suffix for adding damage.
  static void damage(String name, int level, int rarity, int base, int taper) {
    affixType(_suffixes, name, level, rarity, "weapon",
        () => new Attack.modifier(damageBonus: rng.taper(base, taper)));
  }

  /// bow prefix for adding damage.
  static void bowDamage(
      String name, int level, int rarity, int base, int taper) {
    affixType(_prefixes, name, level, rarity, "bow",
        () => new Attack.modifier(damageBonus: rng.taper(base, taper)));
  }

  /// A weapon prefix for giving an elemental brand.
  static void brand(String name, int level, int rarity, Element element,
      int bonus, num scale) {
    affixType(_prefixes, name, level, rarity, "weapon",
        () => new Attack.modifier(element: element,
            damageBonus: rng.taper(bonus, 5),
            damageScale: rng.taper((scale + 10).toInt(), 4) / 10));
  }

  /// Defines a new [Affix].
  static void affixType(ResourceSet<_AffixType> types, String name,
      int depth, int rarity, String tag, _CreateAttack createAttack) {
    var type = new _AffixType(name, createAttack);

    types.add(name, type, depth, rarity, tag);
  }
}
