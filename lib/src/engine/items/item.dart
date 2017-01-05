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

  bool get isRanged => type.attack is RangedAttack;

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
  bool get canToss => type.tossAttack != null;

  /// Gets the melee [Attack] for the item, taking into account any [Affixes]s
  /// it has.
  Attack get attack {
    if (type.attack == null) return null;

    var attack = type.attack;
    if (prefix != null && prefix.attack != null) {
      attack = attack.combine(prefix.attack);
    }

    if (suffix != null && suffix.attack != null) {
      attack = attack.combine(suffix.attack);
    }

    return attack;
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

  /// The number of items in this stack.
  int get count => _count;
  int _count = 1;

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
    assert(prefix == null && suffix == null &&
        item.prefix == null && item.suffix == null);

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

  /// The item's [RangedAttack] when thrown or `null` if the item can't be
  /// thrown.
  final RangedAttack tossAttack;

  /// The percent chance of the item breaking when thrown. `null` if the item
  /// can't be thrown.
  final int breakage;

  final int armor;

  // TODO: Affix should modify this.
  /// How much gold this item is worth.
  final int price;

  /// True if this item is "treasure".
  ///
  /// That means it just has a gold value. As soon as the hero steps on it, it
  /// increases the hero's gold and disappears.
  bool isTreasure;

  /// The maximum number of items of this type that a single stack may contain.
  final int maxStack;

  final Set<String> flags = new Set();

  ItemType(this._name, this.appearance, this.depth, this.sortIndex,
      this.equipSlot, this.weaponType, this.use, this.attack, this.tossAttack,
      this.breakage, this.armor, this.price, this.maxStack, {treasure: false})
      : isTreasure = treasure;

  String toString() => name;
}

/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is an affix.
class Affix {
  final String name;

  final Attack attack;

  final int armor;

  final Map<Element, int> resists = {};

  Affix(this.name, {this.attack, this.armor: 0}) {
    for (var element in Element.all) {
      resists[element] = 0;
    }
  }
}

typedef void AddItem(Item item);

abstract class Drop {
  void spawnDrop(AddItem addItem);
}
