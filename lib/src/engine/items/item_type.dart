import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/combat.dart';
import '../core/element.dart';
import '../core/log.dart';
import '../hero/skill.dart';
import 'item.dart';

typedef Action ItemUse();
typedef Action TossItemUse(Vec pos);
typedef void AddItem(Item item);

abstract class Drop {
  void spawnDrop(AddItem addItem);
}

/// Tracks information about a tossable [ItemType].
class Toss {
  /// The percent chance of the item breaking when thrown. `null` if the item
  /// can't be thrown.
  final int breakage;

  /// The item's attack when thrown or `null` if the item can't be thrown.
  final Attack attack;

  /// The action created when the item is tossed and hits something, or `null`
  /// if it just falls to the ground.
  final TossItemUse use;

  Toss(this.breakage, this.attack, this.use);
}

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  /// The pattern string used to generate quantified names for items of this
  /// type: "Scroll[s] of Disappearing", etc.
  final String quantifiableName;

  /// The singular name of the item type: "Sword", "Scroll of Disappearing".
  ///
  /// This is used to identify the item type in drops, affixes, etc.
  String get name => Log.singular(quantifiableName);

  final Object appearance;

  /// The item types's depth.
  ///
  /// Higher depth objects are found later in the game.
  final int depth;

  final int sortIndex;

  // TODO: These two fields are sort of redundant with tags, but ItemTypes
  // don't own their tags. Should they?

  /// The name of the [Equipment] slot that [Item]s can be placed in. If `null`
  /// then this Item cannot be equipped.
  final String equipSlot;

  /// If this item is a weapon, returns which kind of weapon it is -- "spear",
  /// "sword", etc. Otherwise returns `null`.
  final String weaponType;

  final ItemUse use;

  /// The item's [Attack] or `null` if the item is not an equippable weapon.
  final Attack attack;

  /// The items toss information, or `null` if it can't be tossed.
  final Toss toss;

  final int armor;

  // TODO: Affix should modify this.
  /// How much gold this item is worth.
  final int price;

  /// The penalty to the hero's strength when wearing this.
  final int weight;

  /// The amount of strength required to wield the item effectively.
  final int heft;

  /// The amount of light this items gives off when equipped.
  ///
  /// This isn't a raw emanation value, but a level to be passed to
  /// [Lighting.emanationFromLevel()].
  final int emanationLevel;

  /// True if this item is "treasure".
  ///
  /// That means it just has a gold value. As soon as the hero steps on it, it
  /// increases the hero's gold and disappears.
  bool isTreasure;

  /// The maximum number of items of this type that a single stack may contain.
  final int maxStack;

  /// Percent chance of this item being destroyed when hit with a given element.
  final Map<Element, int> destroyChance = {};

  /// If the item burns when on the ground, how much fuel it adds to the
  /// burning tile.
  final int fuel;

  /// The [Skill]s discovered when picking up an item of this type.
  final List<Skill> skills = [];

  ItemType(
      this.quantifiableName,
      this.appearance,
      this.depth,
      this.sortIndex,
      this.equipSlot,
      this.weaponType,
      this.use,
      this.attack,
      this.toss,
      this.armor,
      this.price,
      this.maxStack,
      {this.weight = 0,
      this.heft = 1,
      int emanation,
      int fuel,
      bool treasure})
      : emanationLevel = emanation ?? 0,
        fuel = fuel ?? 0,
        isTreasure = treasure ?? false;

  String toString() => name;
}

// TODO: Affixes should modify price.
/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is an affix.
class Affix {
  final String name;

  final double heftScale;
  final int weightBonus;
  final int strikeBonus;
  final double damageScale;
  final int damageBonus;
  final Element brand;
  final int armor;

  final Map<Element, int> _resists = {};

  final int priceBonus;
  final double priceScale;

  Affix(this.name,
      {double heftScale,
      int weightBonus,
      int strikeBonus,
      double damageScale,
      int damageBonus,
      Element brand,
      int armor,
      int priceBonus,
      double priceScale})
      : heftScale = heftScale ?? 1.0,
        weightBonus = weightBonus ?? 0,
        strikeBonus = strikeBonus ?? 0,
        damageScale = damageScale ?? 1.0,
        damageBonus = damageBonus ?? 1,
        brand = brand ?? Element.none,
        armor = armor ?? 0,
        priceBonus = priceBonus ?? 0,
        priceScale = priceScale ?? 1.0 {}

  int resistance(Element element) {
    if (!_resists.containsKey(element)) return 0;
    return _resists[element];
  }

  void resist(Element element, int power) {
    _resists[element] = power;
  }

  String toString() => name;
}
