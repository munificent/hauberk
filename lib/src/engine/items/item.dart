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

  /// The random affixes added to the item, not including any intrinsic one.
  final List<Affix> _affixes;

  List<Affix> get affixes {
    // If there's an instrinsic affix, that's the only one.
    if (type.intrinsicAffix case var affix?) return [affix];

    return _affixes;
  }

  Item(this.type, this._count, [List<Affix> affixes = const []])
      : _affixes = List.unmodifiable(affixes);

  Object get appearance => type.appearance;

  bool get canEquip => equipSlot != null;
  String? get equipSlot => type.equipSlot;

  /// Whether the item can be used or not.
  bool get canUse => type.use != null;

  /// Create the action to perform when this item is used, and reduce its count.
  Action use() {
    // TODO: Some kinds of usable items shouldn't be consumed, like rods in
    // Angband.
    _count--;
    return type.use!.createAction();
  }

  /// Whether the item can be thrown or not.
  bool get canToss => type.toss != null;

  /// The base attack for the item, ignoring its own affixes.
  Attack? get attack => type.attack;

  Toss? get toss => type.toss;

  Element get element {
    var result = Element.none;
    if (attack != null) result = attack!.element;

    for (var affix in affixes) {
      if (affix.brand != Element.none) result = affix.brand;
    }

    return result;
  }

  int get strikeBonus =>
      affixes.fold(0, (bonus, affix) => bonus + affix.strikeBonus);

  double get damageScale =>
      affixes.fold(1.0, (bonus, affix) => bonus * affix.damageScale);

  int get damageBonus =>
      affixes.fold(0, (bonus, affix) => bonus + affix.damageBonus);

  // TODO: Affix defenses?
  Defense? get defense => type.defense;

  /// The amount of protection provided by the item when equipped.
  int get armor => baseArmor + armorModifier;

  /// The base amount of protection provided by the item when equipped,
  /// ignoring any affix modifiers.
  int get baseArmor => type.armor;

  /// The amount of protection added by the affixes.
  int get armorModifier =>
      affixes.fold(0, (bonus, affix) => bonus + affix.armor);

  @override
  String get nounText {
    var name = affixes.fold(
        type.quantifiableName, (name, affix) => affix.itemName(name));

    return Log.quantify(name, count);
  }

  @override
  Pronoun get pronoun => Pronoun.it;

  /// How much the one unit of the item can be bought and sold for.
  int get price {
    var price = type.price.toDouble();

    // If an item has multiple affixes, then it's even more valuable since it
    // provides multiple benefits in a single slot, so scale all of the affixes
    // by their total count.
    var affixScale = 1 + affixes.length;

    for (var affix in affixes) {
      price *= affix.priceScale * affixScale;
    }

    for (var affix in affixes) {
      price += affix.priceBonus * affixScale;
    }

    return price.ceil();
  }

  bool get isTreasure => type.isTreasure;

  /// The penalty to the hero's strength when wearing this.
  int get weight {
    var totalWeight = affixes.fold(
        type.weight, (weight, affix) => weight + affix.weightBonus);

    return math.max(0, totalWeight);
  }

  /// The amount of strength required to wield the item effectively.
  int get heft {
    var totalHeft = affixes.fold(
        type.heft.toDouble(), (heft, affix) => heft * affix.heftScale);

    return totalHeft.round();
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

  /// Gets the resistance this item confers to [element] when equipped.
  int resistance(Element element) => affixes.fold(
      0, (resistance, affix) => resistance + affix.resistance(element));

  @override
  int compareTo(Item other) {
    // Sort by type.
    if (type.sortIndex != other.type.sortIndex) {
      return type.sortIndex.compareTo(other.type.sortIndex);
    }

    // Sort by affixes. Fewer affixes first.
    if (affixes.length != other.affixes.length) {
      return affixes.length.compareTo(other.affixes.length);
    }

    // Same number of affixes, so sort by affix.
    for (var i = 0; i < affixes.length; i++) {
      var affix = affixes[i];
      var otherAffix = other.affixes[i];
      if (affix.sortIndex != otherAffix.sortIndex) {
        return affix.sortIndex.compareTo(otherAffix.sortIndex);
      }
    }

    // Order by descending count.
    if (count != other.count) return other.count.compareTo(count);

    return 0;
  }

  /// Creates a new [Item] with the same type and affixes as this one.
  ///
  /// If [count] is given, the clone has that count. Otherwise, it has the
  /// same count as this item.
  Item clone([int? count]) => Item(type, count ?? _count, affixes);

  bool canStack(Item item) {
    if (type != item.type) return false;

    // Items with affixes don't stack.
    // TODO: Should they?
    if (affixes.isNotEmpty) return false;
    if (item.affixes.isNotEmpty) return false;

    return true;
  }

  /// Try to combine [item] with this item into a single stack.
  ///
  /// Updates the counts of the two items. If completely successful, [item]
  /// will end up with a count of zero. If the items cannot be stacked, [item]'s
  /// count is unchanged.
  void stack(Item item) {
    if (!canStack(item)) return;

    // We don't support stacking items with affixes.
    assert(affixes.isEmpty && item.affixes.isEmpty);

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

  @override
  String toString() => nounText;
}
