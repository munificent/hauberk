library hauberk.engine.items.equipment;

import 'dart:collection';

import 'inventory.dart';
import 'item.dart';

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
