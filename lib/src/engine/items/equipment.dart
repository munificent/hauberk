import 'dart:collection';

import 'inventory.dart';
import 'item.dart';

/// The collection of wielded [Item]s held by the [Hero]. Unlike [Inventory],
/// the [Equipment] holds each item in a categorized slot.
class Equipment extends IterableBase<Item> with ItemCollection {
  ItemLocation get location => ItemLocation.equipment;

  final List<String> slotTypes;
  final List<Item> slots;

  Equipment()
      : slotTypes = const [
          'hand',
          'hand',
          'ring',
          'necklace',
          'body',
          'cloak',
          'helm',
          'gloves',
          'boots'
        ],
        slots = List<Item>(9);

  /// Gets the currently-equipped weapons, if any.
  Iterable<Item> get weapons =>
      slots.where((item) => item != null && item.type.weaponType != null);

  /// Gets the number of equipped items. Ignores empty slots.
  int get length {
    return slots.fold(0, (count, item) => count + ((item == null) ? 0 : 1));
  }

  /// Gets the equipped item at the given index. Ignores empty slots.
  Item operator [](int index) {
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
  /// the dungeon so that any inventory changes that happen there are discarded
  /// if the hero dies.
  Equipment clone() {
    var equipment = Equipment();
    for (var i = 0; i < slotTypes.length; i++) {
      if (slots[i] != null) {
        equipment.slots[i] = slots[i].clone();
      }
    }

    return equipment;
  }

  /// Gets whether or not there is a slot to equip [item].
  bool canEquip(Item item) {
    return slotTypes.any((slot) => item.equipSlot == slot);
  }

  bool canAdd(Item item) {
    // Look for an empty slot of the right type.
    for (var i = 0; i < slots.length; i++) {
      if (slotTypes[i] == item.equipSlot && slots[i] == null) return true;
    }

    return false;
  }

  /// Tries to add the item. This will only succeed if there is an empty slot
  /// that allows the item. Unlike [equip], this will not swap items. It is
  /// used by the [ItemScreen].
  AddItemResult tryAdd(Item item) {
    // Should not be able to equip stackable items. If we want to make, say,
    // knives stackable, we'll have to add support for splitting stacks here.
    assert(item.count == 1);

    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == item.equipSlot && slots[i] == null) {
        slots[i] = item;
        return AddItemResult(item.count, 0);
      }
    }

    return AddItemResult(0, item.count);
  }

  void countChanged() {
    // Do nothing. Equipment doesn't stack.
  }

  /// Equips [item].
  ///
  /// Returns any items that had to be unequipped to make room for it. This is
  /// usually nothing or a single item, but can be two held items if equipping
  /// a two-handed item.
  List<Item> equip(Item item) {
    assert(item.count == 1, "Must split the stack before equipping.");

    // Handle hands and two-handed items specially. We need to preserve the
    // invariant that you can never get into a state where you are holding a
    // two-handed item and something else.
    if (item.equipSlot == "hand") {
      var handSlots = <int>[];
      var heldSlots = <int>[];
      for (var i = 0; i < slotTypes.length; i++) {
        if (slotTypes[i] == "hand") {
          handSlots.add(i);
          if (slots[i] != null) heldSlots.add(i);
        }
      }

      // Nothing held, so hold it.
      if (heldSlots.isEmpty) {
        slots[handSlots[0]] = item;
        return const [];
      }

      // Holding a two-handed item, so unequip it.
      if (heldSlots.length == 1 && slots[heldSlots[0]].type.isTwoHanded) {
        var unequipped = slots[heldSlots[0]];
        slots[handSlots[0]] = item;
        return [unequipped];
      }

      // Equipping a two-handed, so unequip anything held.
      if (item.type.isTwoHanded) {
        var unequipped = <Item>[];
        for (var slot in heldSlots) {
          unequipped.add(slots[slot]);
          slots[slot] = null;
        }

        slots[handSlots[0]] = item;
        return unequipped;
      }

      // Both hands full, so empty one.
      if (heldSlots.length == 2) {
        var unequipped = slots[heldSlots[0]];
        slots[heldSlots[0]] = item;
        return [unequipped];
      }

      // One empty hand, so use it.
      if (heldSlots[0] == handSlots[0]) {
        slots[handSlots[1]] = item;
      } else {
        slots[handSlots[0]] = item;
      }
      return const [];
    }

    var usedSlot = -1;
    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == item.equipSlot) {
        if (slots[i] == null) {
          // Found an empty slot, so put it there.
          slots[i] = item;
          return const [];
        } else {
          // Found the slot, but it's occupied.
          usedSlot = i;
        }
      }
    }

    // If we get here, all matching slots were already full. Swap out an item.
    assert(usedSlot != -1, "Should have at least one of every slot.");
    var unequipped = [slots[usedSlot]];
    slots[usedSlot] = item;
    return unequipped;
  }

  void remove(Item item) {
    for (var i = 0; i < slots.length; i++) {
      if (slots[i] == item) {
        slots[i] = null;
        break;
      }
    }
  }

  /// Unequips and returns the [Item] at [index].
  Item removeAt(int index) {
    // Find the slot, skipping over empty ones.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slots[i] == null) continue;
      if (index == 0) {
        var item = slots[i];
        slots[i] = null;
        return item;
      }

      index--;
    }

    throw "unreachable";
  }

  /// Gets the non-empty item slots.
  Iterator<Item> get iterator => slots.where((item) => item != null).iterator;
}
