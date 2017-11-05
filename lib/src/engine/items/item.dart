import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../attack.dart';
import '../element.dart';
import '../log.dart';

/// A thing that can be picked up.
class Item implements Comparable<Item>, Noun {
  final ItemType type;

  final Affix prefix;
  final Affix suffix;

  Item(this.type, this._count, [this.prefix, this.suffix]);

  get appearance => type.appearance;

  bool get canEquip => equipSlot != null;
  String get equipSlot => type.equipSlot;

  /// Whether the item can be used or not.
  bool get canUse => type.use != null;

  /// Create the action to perform when this item is used, and reduce its count.
  Action use() {
    // TODO: Some kinds of usable items shouldn't be consumed, like rods in
    // Angband.
    _count--;
    return type.use();
  }

  /// Whether the item can be thrown or not.
  bool get canToss => type.toss != null;

  /// The base attack for the item, ignoring its own affixes.
  Attack get attack => type.attack;

  Toss get toss => type.toss;

  Element get element {
    var result = Element.none;
    if (attack != null) result = attack.element;
    if (prefix != null && prefix.brand != Element.none) result = prefix.brand;
    if (suffix != null && suffix.brand != Element.none) result = suffix.brand;
    return result;
  }

  int get strikeBonus {
    var result = 0;
    if (prefix != null) result += prefix.strikeBonus;
    if (suffix != null) result += suffix.strikeBonus;
    return result;
  }

  double get damageScale {
    var result = 1.0;
    if (prefix != null) result *= prefix.damageScale;
    if (suffix != null) result *= suffix.damageScale;
    return result;
  }

  int get damageBonus {
    var result = 0;
    if (prefix != null) result += prefix.damageBonus;
    if (suffix != null) result += suffix.damageBonus;
    return result;
  }

  /// The amount of protection provided by the item when equipped.
  int get armor => baseArmor + armorModifier;

  /// The base amount of protection provided by the item when equipped,
  /// ignoring any affix modifiers.
  int get baseArmor => type.armor;

  /// The amount of protection added by the affixes.
  int get armorModifier {
    var result = 0;
    if (prefix != null) result += prefix.armor;
    if (suffix != null) result += suffix.armor;
    return result;
  }

  String get nounText {
    final name = new StringBuffer();

    if (prefix != null) {
      name.write(prefix.name);
      name.write(' ');
    }

    name.write(type._name);

    if (suffix != null) {
      name.write(' ');
      name.write(suffix.name);
    }

    return Log.quantify(name.toString(), count);
  }

  Pronoun get pronoun => Pronoun.it;

  // TODO: Take affixes into account.
  /// How much the one unit of the item can be bought and sold for.
  int get price => type.price;

  bool get isTreasure => type.isTreasure;

  Set<String> get flags => type.flags;

  // TODO: Let affixes modify. Affixes like "ghostly" and "elven" reduce
  // encumbrance. "Heavy" and "adamant" increase it (but also increase armor
  // power).
  /// The penalty to the hero's strength when wearing this.
  int get encumbrance => type.encumbrance;

  // TODO: Affixes that modify.
  /// The amount of strength required to wield the item effectively.
  int get heft => type.heft;

  /// The number of items in this stack.
  int get count => _count;
  int _count = 1;

  /// Apply any affix modifications to hit.
  void modifyHit(Hit hit) {
    hit.addStrike(strikeBonus);
    hit.scaleDamage(damageScale);
    hit.addDamage(damageBonus);
    hit.brand(element);
    // TODO: Range modifier.
  }

  /// Gets the resistance this item confers to [element].
  int resistance(Element element) {
    var resistance = 0;

    if (prefix != null) resistance += prefix.resists[element];
    if (suffix != null) resistance += suffix.resists[element];

    return resistance;
  }

  int compareTo(Item other) {
    if (type.sortIndex != other.type.sortIndex) {
      return type.sortIndex.compareTo(other.type.sortIndex);
    }

    // TODO: Take into account affixes.

    // Order by descending count.
    if (count != other.count) return other.count.compareTo(count);

    return 0;
  }

  /// Creates a new [Item] with the same type and affixes as this one.
  ///
  /// If [count] is given, the clone has that count. Otherwise, it has the
  /// same count as this item.
  Item clone([int count]) => new Item(type, count ?? _count, prefix, suffix);

  bool canStack(Item item) {
    if (type != item.type) return false;

    // Items with affixes don't stack.
    // TODO: Should they?
    if (prefix != null || item.prefix != null) return false;
    if (suffix != null || item.suffix != null) return false;

    return true;
  }

  /// Try to combine [item] with this item into a single stack.
  ///
  /// Updates the counts of the two items. If completely successful, [item]
  /// will end up with a count of zero. If the items cannot be stacked, [item]'s
  /// count is unchanged.
  void stack(Item item) {
    if (!canStack(item)) return;

    // If we get here, we are trying to stack. We don't support stacking
    // items with affixes, and we should avoid that by not having any affixes
    // defined for stackable items. Validate that invariant here.
    assert(prefix == null &&
        suffix == null &&
        item.prefix == null &&
        item.suffix == null);

    var total = count + item.count;
    if (total <= type.maxStack) {
      // Completely merge the stack.
      _count = total;
      item._count = 0;
    } else {
      // There is some left.
      _count = type.maxStack;
      item._count = total - type.maxStack;
    }
  }

  /// Splits this item into two stacks. Returns a new item with [count], and
  /// reduces this stack by that amount.
  Item splitStack(int count) {
    assert(count < _count);

    _count -= count;
    return clone(count);
  }

  String toString() => nounText;
}

typedef Action ItemUse();
typedef Action TossItemUse(Vec pos);

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
  final String _name;
  String get name => Log.singular(_name);

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
  final int encumbrance;

  /// The amount of strength required to wield the item effectively.
  final int heft;

  /// True if this item is "treasure".
  ///
  /// That means it just has a gold value. As soon as the hero steps on it, it
  /// increases the hero's gold and disappears.
  bool isTreasure;

  /// The maximum number of items of this type that a single stack may contain.
  final int maxStack;

  final Set<String> flags = new Set();

  ItemType(
      this._name,
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
      {this.encumbrance = 0,
        this.heft = 1,
      treasure = false})
      : isTreasure = treasure;

  String toString() => name;
}

/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is an affix.
class Affix {
  final String name;

  final int strikeBonus;
  final double damageScale;
  final int damageBonus;
  final Element brand;

  final int armor;

  final Map<Element, int> resists = {};

  Affix(this.name,
      {int strikeBonus,
      double damageScale,
      int damageBonus,
      Element brand,
      int armor})
      : strikeBonus = strikeBonus ?? 0,
        damageScale = damageScale ?? 1.0,
        damageBonus = damageBonus ?? 1,
        brand = brand ?? Element.none,
        armor = armor ?? 0 {
    for (var element in Element.all) {
      resists[element] = 0;
    }
  }
}

typedef void AddItem(Item item);

abstract class Drop {
  void spawnDrop(AddItem addItem);
}
