import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'items.dart';

typedef Attack _CreateAttack();

class _AttackAffix extends AffixType {
  final _CreateAttack _createAttack;

  _AttackAffix(String name, this._createAttack) : super(name);

  Affix create() {
    return new Affix(this, _createAttack());
  }
}

class _ResistAffix extends AffixType {
  final Element _element;
  final int _power;

  _ResistAffix(String name, this._element, this._power) : super(name);

  Affix create() => new Affix(this, null);

  Attack defend(Attack attack) {
    if (attack.element == _element) {
      attack = attack.addResistance(_power);
    }

    return attack;
  }
}

class Affixes {
  static final _prefixes = new ResourceSet<AffixType>();
  static final _suffixes = new ResourceSet<AffixType>();

  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType) {
    // Untagged items don't have any affixes.
    if (Items.types.getTags(itemType.name).isEmpty) return new Item(itemType);

    // Give items a chance to boost their effective level when choosing a
    // affixes.
    var depth = rng.taper(itemType.depth, 2);

    depth = 40;

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

  static AffixType find(String name) {
    var type = _prefixes.tryFind(name);
    if (type != null) return type;

    return _suffixes.find(name);
  }

  static Affix _chooseAffix(
      ResourceSet<AffixType> affixes, ItemType itemType, int depth) {
    var type = affixes.tryChooseMatching(depth,
        Items.types.getTags(itemType.name));

    if (type == null) return null;
    return type.create();
  }

  static void initialize() {
    _resists();
    _extraDamage();
    _brands();

    // TODO: "of Accuracy" increases range of bows.
  }

  static void _resists() {
    _resistWeak(Element.air, 4, 2);
    _resistWeak(Element.earth, 8, 2);
    _resistWeak(Element.fire, 12, 2);
    _resistWeak(Element.water, 16, 2);
    _resistWeak(Element.acid, 20, 2);
    _resistWeak(Element.cold, 24, 2);
    _resistWeak(Element.lightning, 28, 2);
    _resistWeak(Element.poison, 32, 2);
    _resistWeak(Element.dark, 36, 2);
    _resistWeak(Element.light, 40, 2);
    _resistWeak(Element.spirit, 46, 2);

    _resistStrong(Element.air, 14, 4);
    _resistStrong(Element.earth, 18, 4);
    _resistStrong(Element.fire, 22, 4);
    _resistStrong(Element.water, 26, 4);
    _resistStrong(Element.acid, 30, 4);
    _resistStrong(Element.cold, 34, 4);
    _resistStrong(Element.lightning, 38, 4);
    _resistStrong(Element.poison, 42, 4);
    _resistStrong(Element.dark, 46, 4);
    _resistStrong(Element.light, 50, 4);
    _resistStrong(Element.spirit, 54, 4);
  }

  static void _extraDamage() {
    // TODO: Should these scale damage?
    damage("of Harming", 8, 1, 1, 4);
    damage("of Wounding", 15, 1, 3, 4);
    damage("of Maiming", 35, 1, 6, 3);
    damage("of Slaying", 65, 1, 10, 3);

    bowDamage("Ash", 10, 1, 3, 4);
    bowDamage("Yew", 20, 1, 5, 3);
  }

  static void _brands() {
    // TODO: Should these grant resistance to their element too?
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
    brand("Spiritual", 80, 8, Element.spirit, 8, 1.5);
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
    var affix = new _ResistAffix(name, element, power);
    // TODO: Don't apply to all armor types?
    _suffixes.add(affix.name, affix, depth, rarity, "armor");
  }

  /// A weapon suffix for adding damage.
  static void damage(String name, int depth, int rarity, int base, int taper) {
    _attackAffix(_suffixes, name, depth, rarity, "weapon",
        () => new Attack.modifier(damageBonus: rng.taper(base, taper)));
  }

  /// bow prefix for adding damage.
  static void bowDamage(
      String name, int depth, int rarity, int base, int taper) {
    _attackAffix(_prefixes, name, depth, rarity, "bow",
        () => new Attack.modifier(damageBonus: rng.taper(base, taper)));
  }

  /// A weapon prefix for giving an elemental brand.
  static void brand(String name, int depth, int rarity, Element element,
      int bonus, num scale) {
    _attackAffix(_prefixes, name, depth, rarity, "weapon",
        () => new Attack.modifier(element: element,
            damageBonus: rng.taper(bonus, 5),
            damageScale: rng.taper((scale + 10).toInt(), 4) / 10));
  }

  /// Defines a new [Affix].
  static void _attackAffix(ResourceSet<AffixType> types, String name,
      int depth, int rarity, String tag, _CreateAttack createAttack) {
    var type = new _AttackAffix(name, createAttack);
    types.add(name, type, depth, rarity, tag);
  }
}
