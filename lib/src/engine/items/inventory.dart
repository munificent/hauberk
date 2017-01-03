import 'dart:collection';

import '../actor.dart';
import '../hero/hero.dart';
import 'item.dart';

/// An [Item] in the game can be either on the ground in the level, or held by
/// the [Hero] in their [Inventory] or [Equipment]. This enum describes which
/// of those is the case.
class ItemLocation {
  static const onGround = const ItemLocation("on ground");
  static const inventory = const ItemLocation("inventory");
  static const equipment = const ItemLocation("equipment");

  final String name;
  const ItemLocation(this.name);
}

abstract class ItemCollection extends Iterable<Item> {
  int get length;
  Item operator[](int index);
  Item removeAt(int index);
  bool tryAdd(Item item);
}

/// The collection of [Item]s held by an [Actor].
class Inventory extends IterableMixin<Item> implements ItemCollection {
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

  Inventory(this.capacity, [Iterable<Item> items])
      : _items = <Item>[] {
    if (items != null) _items.addAll(items);
  }

  /// Creates a new copy of this Inventory. This is done when the [Hero] enters
  /// a [Stage] so that any inventory changes that happen in the stage are
  /// discarded if the hero dies.
  Inventory clone() {
    var items = _items.map((item) => item.clone());
    return new Inventory(capacity, items);
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

  // TODO: Get rid of this and rename tryAdd2() to tryAdd() once everything is
  // using this.
  bool tryAdd(Item item, {bool wasUnequipped: false}) {
    // TODO: Merge stacks.
    if (_items.length >= capacity) return false;

    _items.add(item);
    _items.sort();

    if (wasUnequipped) _lastUnequipped = item;

    return true;
  }

  AddItemResult tryAdd2(Item item, {bool wasUnequipped: false}) {
    var adding = item.count;

    // Try to add it to existing stacks.
    for (var existing in _items) {
      existing.stack(item);

      // If we completely stacked it, we're done.
      if (item.count == 0) {
        return new AddItemResult(adding, 0);
      }
    }

    // See if there is room to start a new stack with the rest.
    if (_items.length >= capacity) {
      // There isn't room to pick up everything.
      return new AddItemResult(adding - item.count, item.count);
    }

    // Add a new stack.
    _items.add(item);
    _items.sort();

    if (wasUnequipped) _lastUnequipped = item;
    return new AddItemResult(adding, 0);
  }

  /// Re-sorts multiple stacks of the same item to pack them into the minimum
  /// number of stacks.
  ///
  /// This should be called any time the count of an item stack in the hero's
  /// inventory is changed.
  void optimizeStacks() {
    // Hacky. Just re-add everything from scratch.
    var items = _items.toList();
    _items.clear();

    for (var item in items) {
      var result = tryAdd2(item);
      assert(result.remaining == 0);
    }
  }

  Iterator<Item> get iterator => _items.iterator;
}

/// Describes the result of attempting to add an item stack to the inventory.
class AddItemResult {
  /// The count of items in the stack that were successfully added.
  final int added;

  /// The count of items that could not be fit into the inventory.
  final int remaining;

  AddItemResult(this.added, this.remaining);
}