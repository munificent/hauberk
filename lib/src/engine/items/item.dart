import 'dart:math' as math;

import '../action/action.dart';
import '../core/combat.dart';
import '../core/element.dart';
import '../core/log.dart';
import 'affix.dart';
import 'item_type.dart';

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
    var name = type.quantifiableName;

    if (prefix != null) name = "${prefix.displayName} $name";
    if (suffix != null) name = "$name ${suffix.displayName}";

    return Log.quantify(name, count);
  }

  Pronoun get pronoun => Pronoun.it;

  /// How much the one unit of the item can be bought and sold for.
  int get price {
    var price = type.price.toDouble();
    if (prefix != null) price *= prefix.priceScale;
    if (suffix != null) price *= suffix.priceScale;

    if (prefix != null) price += prefix.priceBonus;
    if (suffix != null) price += suffix.priceBonus;

    return price.ceil();
  }

  bool get isTreasure => type.isTreasure;

  /// The penalty to the hero's strength when wearing this.
  int get weight {
    var result = type.weight;

    if (prefix != null) result += prefix.weightBonus;
    if (suffix != null) result += suffix.weightBonus;

    return math.max(0, result);
  }

  /// The amount of strength required to wield the item effectively.
  int get heft {
    var result = type.heft.toDouble();

    if (prefix != null) result *= prefix.heftScale;
    if (suffix != null) result *= suffix.heftScale;

    return result.round();
  }

  // TODO: Affixes that modify.
  int get emanationLevel => type.emanationLevel;

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

    if (prefix != null) resistance += prefix.resistance(element);
    if (suffix != null) resistance += suffix.resistance(element);

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
  Item clone([int count]) => Item(type, count ?? _count, prefix, suffix);

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
