library hauberk.content.affixes;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';

typedef Affix _CreateAffix(String name);
typedef Map _SerializeAffix(Affix affix);
typedef Affix _DeserializeAffix(Map data);

/// A generic "kind" of affix that can create concrete [Affix] instances.
class _AffixFactory {
  final String name;

  /// The names of the categories that this affix can apply to.
  final List<String> categories;

  /// The level of the affix. Higher level affixes tend to only appear on
  /// higher level items.
  final int level;
  final int rarity;
  final _CreateAffix create;

  _AffixFactory(
      this.name, this.categories, this.level, this.rarity, this.create);
}

class Affixes {
  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType, [int levelOffset = 0]) {
    // Uncategorized items don't have any affixes.
    if (itemType.category == null) return new Item(itemType);

    // Give items a chance to boost their effective level when choosing a
    // affixes.
    var level = rng.taper(itemType.level, 2);

    var prefix = _chooseAffix(_prefixes, itemType, level, levelOffset);
    var suffix = _chooseAffix(_suffixes, itemType, level, levelOffset);

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

  static Affix _chooseAffix(List<_AffixFactory> factories, ItemType itemType,
      int level, int chanceOffset) {
    // Get the affixes that can apply to the item.
    factories = factories.where((factory) {
      if (factory.level > level) return false;
      return factory.categories
          .any((category) => itemType.categories.contains(category));
    }).toList();

    // TODO: For high level drops, consider randomly discarding some of the
    // lower-level affixes.

    // Try all of the affixes and see if one sticks.
    // TODO: The way this works means adding more affixes makes them more
    // common. Should probably choose one instead of trying them all.
    factories.shuffle();
    for (var factory in factories) {
      // There's a chance of not selecting the affix at all.
      if (rng.range(100) < 60 + chanceOffset) continue;

      // Take the rarity into account.
      if (rng.range(100) < 100 ~/ factory.rarity) {
        return factory.create(factory.name);
      }
    }

    return null;
  }

  static final _prefixes = <_AffixFactory>[];
  static final _suffixes = <_AffixFactory>[];

  static final _serializers = <String, _SerializeAffix>{};
  static final _deserializers = <String, _DeserializeAffix>{};

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

  /// A weapon suffix for adding damage.
  static void damage(String name, int level, int rarity, int base, int taper) {
    suffix(name, level, rarity, "weapon",
        create: (name) => new DamageAffix(name, rng.taper(base, taper)),
        serialize: DamageAffix.serialize,
        deserialize: DamageAffix.deserialize);
  }

  /// bow prefix for adding damage.
  static void bowDamage(
      String name, int level, int rarity, int base, int taper) {
    prefix(name, level, rarity, "bow",
        create: (name) => new DamageAffix(name, rng.taper(base, taper)),
        serialize: DamageAffix.serialize,
        deserialize: DamageAffix.deserialize);
  }

  /// A weapon prefix for giving an elemental brand.
  static void brand(String name, int level, int rarity, Element element,
      int bonus, num scale) {
    prefix(name, level, rarity, "weapon",
        create: (name) => new BrandAffix(name, element, rng.taper(bonus, 5),
            rng.taper((scale + 10).toInt(), 4) / 10),
        serialize: BrandAffix.serialize,
        deserialize: BrandAffix.deserialize);
  }

  /// Defines a new prefix [Affix].
  static void prefix(String name, int level, int rarity, String groups,
      {_CreateAffix create,
      _SerializeAffix serialize,
      _DeserializeAffix deserialize}) {
    _prefixes
        .add(new _AffixFactory(name, groups.split(" "), level, rarity, create));
    _serializers[name] = serialize;
    _deserializers[name] = deserialize;
  }

  /// Defines a new suffix [Affix].
  static void suffix(String name, int level, int rarity, String groups,
      {_CreateAffix create,
      _SerializeAffix serialize,
      _DeserializeAffix deserialize}) {
    _suffixes
        .add(new _AffixFactory(name, groups.split(" "), level, rarity, create));
    _serializers[name] = serialize;
    _deserializers[name] = deserialize;
  }

  static Map serialize(Affix affix) {
    return _serializers[affix.name](affix);
  }

  static Affix deserialize(Map data) {
    return _deserializers[data["name"]](data);
  }
}

/// An [Affix] that adds to a weapon's damage.
class DamageAffix extends Affix {
  static Map serialize(DamageAffix affix) {
    return {"name": affix.name, "damage": affix._damage};
  }

  static Affix deserialize(Map data) {
    return new DamageAffix(data["name"], data["damage"]);
  }

  final String name;

  final num _damage;

  DamageAffix(this.name, this._damage);

  Attack modifyAttack(Attack attack) => attack.addDamage(_damage);
}

/// An [Affix] that brands a weapon's attack with an element and boosts its
/// damage.
class BrandAffix extends Affix {
  static Map serialize(BrandAffix affix) {
    return {
      "name": affix.name,
      "element": affix._element.name,
      "bonus": affix._bonus,
      "multiplier": affix._multiplier
    };
  }

  static Affix deserialize(Map data) {
    return new BrandAffix(data["name"], Element.fromName(data["element"]),
        data["bonus"], data["multiplier"]);
  }

  final String name;

  final Element _element;
  final num _bonus;
  final num _multiplier;

  BrandAffix(this.name, this._element, this._bonus, this._multiplier);

  Attack modifyAttack(Attack attack) =>
      attack.brand(_element).addDamage(_bonus).multiplyDamage(_multiplier);
}
