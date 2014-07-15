library hauberk.engine.item;

import 'dart:collection';

import '../util.dart';
import 'action_base.dart';
import 'actor.dart';
import 'game.dart';
import 'melee.dart';

/// A thing that can be picked up.
class Item extends Thing implements Comparable {
  final ItemType type;

  final Affix prefix;
  final Affix suffix;

  Item(this.type, [this.prefix, this.suffix]) : super(Vec.ZERO);

  get appearance => type.appearance;

  bool get isRanged => type.attack != null && type.attack.isRanged;

  bool get canEquip => equipSlot != null;
  String get equipSlot => type.equipSlot;

  bool get canUse => type.use != null;
  Action use() => type.use();

  /// Gets the melee [Attack] for the item, taking into account any [Affixes]s
  // it has.
  Attack get attack {
    if (type.attack == null) return null;

    var attack = type.attack;
    if (prefix != null) attack = prefix.modifyAttack(attack);
    if (suffix != null) attack = suffix.modifyAttack(attack);

    return attack;
  }

  /// The amount of protected provided by the item when equipped.
  int get armor => type.armor;

  String get nounText {
    final name = new StringBuffer();
    name.write('a ');

    if (prefix != null) {
      name.write(prefix.name);
      name.write(' ');
    }

    name.write(type.name);

    if (suffix != null) {
      name.write(' ');
      name.write(suffix.name);
    }

    if (attack != null) {
      name.write(' (');
      name.write(attack);
      name.write(')');
    }

    return name.toString();
  }

  int compareTo(Item other) {
    // TODO: Take into account affixes.
    return type.sortIndex.compareTo(other.type.sortIndex);
  }
}

typedef Action ItemUse();

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  final String name;
  final appearance;

  /// The item's level.
  ///
  /// Higher level items are found later in the game. Some items may not have
  /// a level.
  final int level;

  final int sortIndex;

  /// The name of the [Equipment] slot that [Item]s can be placed in. If `null`
  /// then this Item cannot be equipped.
  final String equipSlot;

  final ItemUse use;

  /// The item's [Attack] or `null` if the item is not a weapon.
  final Attack attack;

  final int armor;

  /// The path to this item type in the hierarchical organization of items.
  ///
  /// May be empty for uncategorized items.
  final List<String> categories;

  /// A more precise categorization than [equipSlot]. For example, "dagger",
  /// or "cloak". May be `null`.
  String get category {
    if (categories.isEmpty) return null;
    return categories.last;
  }

  ItemType(this.name, this.appearance, this.level, this.sortIndex,
      this.categories, this.equipSlot, this.use, this.attack, this.armor);

  String toString() => name;
}

/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is an affix.
abstract class Affix {
  String get name;

  // TODO: Affix, TrainedStat, Condition and HeroClass all have this or
  // something similar. Should we have a generic interface for stuff that can
  // modify an attack?
  Attack modifyAttack(Attack attack) => attack;
}

abstract class ItemCollection extends Iterable<Item> {
  int get length;
  Item operator[](int index);
  Item removeAt(int index);
  bool tryAdd(Item item);
}

/// The collection of [Item]s held by an [Actor].
class Inventory extends IterableBase<Item> implements ItemCollection {
  final List<Item> _items;
  final int capacity;

  /// If the [Hero] had to unequip an item in order to equip another one, this
  /// will refer to the index of the item that was unequipped.
  ///
  /// If the hero isn't holding an unequipped item, returns `-1`.
  int get lastUnequipped => _items.indexOf(_lastUnequipped);
  Item _lastUnequipped;

  int get length => _items.length;

  Item operator[](int index) => _items[index];

  Inventory(this.capacity)
      : _items = <Item>[];

  /// Creates a new copy of this Inventory. This is done when the [Hero] enters
  /// a [Stage] so that any inventory changes that happen in the stage are
  /// discarded if the hero dies.
  Inventory clone() {
    // TODO: If items themselves ever become mutable, will need to deep
    // clone them too.
    var inventory = new Inventory(capacity);
    for (var item in this) inventory.tryAdd(item);

    return inventory;
  }

  /// Removes all items from the inventory.
  void clear() {
    _items.clear();
    _lastUnequipped = null;
  }

  Item removeAt(int index) {
    var item = _items[index];
    _items.removeAt(index);
    if (_lastUnequipped == item) _lastUnequipped = null;
    return item;
  }

  bool tryAdd(Item item, {bool wasUnequipped: false}) {
    // TODO: Merge stacks.
    if (_items.length >= capacity) return false;

    _items.add(item);
    _items.sort();

    if (wasUnequipped) _lastUnequipped = item;

    return true;
  }

  Iterator<Item> get iterator => _items.iterator;
}

// TODO: Which collection interface should it implement?
/// The collection of wielded [Item]s held by the [Hero]. Unlike [Inventory],
/// the [Equipment] holds each Item in a categorized slot.
class Equipment extends IterableBase<Item> implements ItemCollection {
  final List<String> slotTypes;
  final List<Item> slots;

  Equipment()
  : slotTypes = const [
      'weapon',
      'bow',
      'ring',
      'necklace',
      'body',
      'cloak',
      'shield',
      'helm',
      'gloves',
      'boots'
    ],
    slots = new List<Item>(11);

  /// Gets the [Item] in the weapon slot, if any.
  Item get weapon => find('weapon');

  /// Gets the number of equipped item. Ignores empty slots.
  int get length {
    return slots.fold(0, (count, item) => count + ((item == null) ? 0 : 1));
  }

  /// Gets the equipped item at the given index. Ignores empty slots.
  Item operator[](int index) {
    // Find the slot, skipping over empty ones.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slots[i] != null) {
        if (index == 0) return slots[i];
        index--;
      }
    }

    throw "unreachable";
  }

  /// Creates a new copy of this Equipment. This is done when the [Hero] enters
  /// a [Level] so that any inventory changes that happen in the level are
  /// discarded if the hero dies.
  Equipment clone() {
    // TODO: If items themselves ever become mutable, will need to deep
    // clone them too.
    final equipment = new Equipment();
    for (var i = 0; i < slotTypes.length; i++) {
      equipment.slots[i] = slots[i];
    }

    return equipment;
  }

  /// Gets the [Item] currently equipped in [slotType], if any.
  Item find(String slotType) {
    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == slotType) {
        return slots[i];
      }
    }

    throw 'Unknown equipment slot type "$slotType".';
  }

  /// Gets whether or not there is a slot to equip [item].
  bool canEquip(Item item) {
    return slotTypes.any((slot) => item.equipSlot == slot);
  }

  /// Tries to add the item. This will only succeed if there is an empty slot
  /// that allows the item. Unlike [equip], this will not swap items. It is
  /// used by the [HomeScreen].
  bool tryAdd(Item item) {
    // TODO: Need to handle multiple slots of the same type. In that case,
    // should prefer an empty slot before reusing an in-use one.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == item.equipSlot && slots[i] == null) {
        slots[i] = item;
        return true;
      }
    }

    return false;
  }

  /// Equips [item]. Returns the previously equipped item in that slot, if any.
  Item equip(Item item) {
    // TODO: Need to handle multiple slots of the same type. In that case,
    // should prefer an empty slot before reusing an in-use one.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == item.equipSlot) {
        final unequipped = slots[i];
        slots[i] = item;
        return unequipped;
      }
    }

    throw "unreachable";
  }

  /// Unequips and returns the [Item] at [index].
  Item removeAt(int index) {
    // Find the slot, skipping over empty ones.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slots[i] != null) {
        if (index == 0) {
          final item = slots[i];
          slots[i] = null;
          return item;
        } else {
          index--;
        }
      }
    }

    throw "unreachable";
  }

  Iterator<Item> get iterator {
    // TODO: Would be better if empty slots were shown with a slot label.
    // Don't include empty slots.
    return slots.where((item) => item != null).iterator;
  }
}

typedef void AddItem(Item item);

abstract class Drop {
  void spawnDrop(Game game, AddItem addItem);
}

/// A recipe defines a set of items that can be placed into the crucible and
/// transmuted into a new item.
// TODO: Figure out how this works with affixes.
class Recipe {
  final List<ItemType> ingredients;
  final ItemType result;

  Recipe(this.ingredients, this.result);

  /// Returns `true` if [items] are valid (but not necessarily complete)
  /// ingredients for this recipe.
  bool allows(Iterable<Item> items) => getMissingIngredients(items) != null;

  /// Returns `true` if [items] are the complete ingredients needed for this
  /// recipe.
  bool isComplete(Iterable<Item> items) {
    final missing = getMissingIngredients(items);
    return missing != null && missing.length == 0;
  }

  /// Gets the remaining ingredients needed to complete this recipe given
  /// [items] ingredients. Returns `null` if [items] contains invalid
  /// ingredients.
  List<ItemType> getMissingIngredients(Iterable<Item> items) {
    final missing = new List.from(ingredients);

    for (final item in items) {
      final found = missing.indexOf(item.type);
      if (found == -1) return null;

      // Don't allow extra copies of ingredients.
      missing.removeAt(found);
    }

    return missing;
  }
}
