import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'inventory.dart';

class Shop {
  /// The maximum number of items a shop can contain.
  static const capacity = 26;

  final Drop _drop;

  final String name;

  Shop(this.name, this._drop);

  Inventory create() {
    var inventory = Inventory(ItemLocation.shop(name), capacity);
    update(inventory);
    return inventory;
  }

  Inventory load(Iterable<Item> items) {
    return Inventory(ItemLocation.shop(name), capacity, items);
  }

  void update(Inventory inventory) {
    // Remove some.
    var remainCount = rng.float(capacity * 0.2, capacity * 0.4).toInt();

    while (inventory.length > remainCount) {
      inventory.removeAt(rng.range(inventory.length));
    }

    // Add some.
    var count = rng.float(capacity * 0.3, capacity * 0.7).toInt();

    while (inventory.length < count) {
      // Try to add an item.
      _drop.spawnDrop(1, inventory.tryAdd);

      // Remove duplicates.
      for (var i = 1; i < inventory.length; i++) {
        var previous = inventory[i - 1];
        var item = inventory[i];

        if (previous.type == item.type &&
            previous.prefix == item.prefix &&
            previous.suffix == item.suffix) {
          inventory.removeAt(i);
          i--;
        }
      }
    }
  }
}
