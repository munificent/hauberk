library hauberk.engine.items.inventory;

import 'dart:collection';

import '../actor.dart';
import 'item.dart';

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
