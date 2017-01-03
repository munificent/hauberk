import 'dart:collection';

import 'inventory.dart';
import 'item.dart';

class Shop extends IterableMixin<Item> implements ItemCollection {
  final String name;
  final List<Item> _items;

  Shop(this.name, this._items);

  Iterator<Item> get iterator => _items.iterator;

  int get length => _items.length;

  Item operator[](int index) => _items[index];

  Item removeAt(int index) => _items[index].clone(1);

  /// Any item can be "added" to a shop.
  ///
  /// This just means the item is sold and the hero gains some gold. The item
  /// itself does not appear in the shop.
  // TODO: Add the item to the shop? This would let the player buy back an
  // erroneous sale, but it means we have to deal with making sure there is
  // room for it.
  bool tryAdd(Item item) => true;
}
