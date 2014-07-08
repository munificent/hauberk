library hauberk.content.affixes;

import '../engine.dart';
import '../util.dart';
import 'item_group.dart';

typedef Affix _CreateAffix(String name);
typedef Map _SerializeAffix(Affix affix);
typedef Affix _DeserializeAffix(Map data);

/// A generic "kind" of affix that can create concrete [Affix] instances.
class _AffixFactory {
  final String name;

  /// The names of the [ItemGroup]s that this affix can apply to.
  final List<String> groups;

  /// The level of the affix. Higher level affixes tend to only appear on
  /// higher level items.
  final int level;
  final int rarity;
  final _CreateAffix create;

  _AffixFactory(this.name, this.groups, this.level, this.rarity, this.create);
}

class Affixes {
  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType) {
    var group = ItemGroup.find(itemType);

    // Ungrouped items don't have any affixes.
    if (group == null) return new Item(itemType);

    // Give items a chance to boost their effective level when choosing a
    // affixes.
    var level = rng.taper(ItemGroup.findLevel(itemType), 2);

    var prefix = _chooseAffix(_prefixes, itemType, group, level);
    var suffix = _chooseAffix(_suffixes, itemType, group, level);

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
    ItemGroup group, int level) {
    // Get the affixes that can apply to the item.
    factories = factories.where((factory) {
      if (factory.level > level) return false;
      return factory.groups.any((factoryGroup) => group.isWithin(factoryGroup));
    }).toList();

    // TODO: For high level drops, consider randomly discarding some of the
    // lower-level affixes.

    // Try all of the affixes and see if one sticks.
    factories.shuffle();
    for (var factory in factories) {
      // Take the rarity into account and also have a chance of not
      // selecting the affix at all.
      if (rng.range(1000) < 100 ~/ factory.rarity) {
        return factory.create(factory.name);
      }
    }

    return null;
  }

  static final _prefixes = <_AffixFactory>[];
  static final _suffixes = <_AffixFactory>[];

  static final _serializers = <String, _SerializeAffix>{};
  static final _deserializers = <String, _DeserializeAffix>{};

  static void build() {
    brand("Glimmering", 12, 3, Element.LIGHT, 0, 1.0);
    brand("Shining", 24, 4, Element.LIGHT, 2, 1.1);
    brand("Radiant", 48, 5, Element.LIGHT, 4, 1.2);

    brand("Dim", 16, 3, Element.DARK, 0, 1.1);
    brand("Dark", 32, 4, Element.DARK, 1, 1.2);
    brand("Black", 56, 5, Element.DARK, 3, 1.3);

    brand("Freezing", 20, 3, Element.COLD, 2, 1.2);

    brand("Burning", 20, 3, Element.FIRE, 2, 1.2);
    brand("Flaming", 40, 4, Element.FIRE, 4, 1.3);
    brand("Searing", 60, 5, Element.FIRE, 6, 1.4);

    brand("Electric", 50, 5, Element.LIGHTNING, 4, 1.6);
    brand("Shocking", 70, 5, Element.LIGHTNING, 6, 1.8);

    brand("Poisoned", 35, 5, Element.POISON, 5, 1.3);
    brand("Venomous", 70, 5, Element.POISON, 6, 1.5);

    brand("Ghostly", 45, 5, Element.SPIRIT, 3, 1.3);

    // TODO: Should these scale damage?
    damage("of Harming", 8, 1, 1, 4);
    damage("of Wounding", 15, 1, 3, 4);
    damage("of Maiming", 35, 1, 6, 3);
    damage("of Slaying", 65, 1, 10, 3);

    // TODO: "of Accuracy" increases range of bows.
  }

  /// Defines a weapon suffix for adding damage.
  static void damage(String name, int level, int rarity, int base, int taper) {
    suffix(name, level, rarity, "weapon", create: (name) {
      return new DamageAffix(name, rng.taper(base, taper));
    }, serialize: DamageAffix.serialize, deserialize: DamageAffix.deserialize);
  }

  /// Defines a weapon prefix for giving an elemental brand.
  static void brand(String name, int level, int rarity, Element element,
      int bonus, num scale) {
    prefix(name, level, rarity, "weapon", create: (name) {
      return new BrandAffix(name, element, rng.taper(bonus, 5),
      rng.taper((scale + 10).toInt(), 4) / 10);
    }, serialize: BrandAffix.serialize, deserialize: BrandAffix.deserialize);
  }

  /// Defines a new prefix [Affix].
  static void prefix(String name, int level, int rarity, String groups,
      {_CreateAffix create, _SerializeAffix serialize,
      _DeserializeAffix deserialize}) {
    _prefixes.add(new _AffixFactory(name, groups.split(" "), level, rarity,
        create));
    _serializers[name] = serialize;
    _deserializers[name] = deserialize;
  }

  /// Defines a new suffix [Affix].
  static void suffix(String name, int level, int rarity, String groups,
      {_CreateAffix create, _SerializeAffix serialize,
      _DeserializeAffix deserialize}) {
    _suffixes.add(new _AffixFactory(name, groups.split(" "), level, rarity,
        create));
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
    return {
      "name": affix.name,
      "damage": affix._damage
    };
  }

  static Affix deserialize(Map data) {
    return new DamageAffix(
      data["name"],
      data["damage"]);
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
    return new BrandAffix(
      data["name"],
      Element.fromName(data["element"]),
      data["bonus"],
      data["multiplier"]);
  }

  final String name;

  final Element _element;
  final num _bonus;
  final num _multiplier;

  BrandAffix(this.name, this._element, this._bonus, this._multiplier);

  Attack modifyAttack(Attack attack) =>
      attack.brand(_element).addDamage(_bonus).multiplyDamage(_multiplier);
}
