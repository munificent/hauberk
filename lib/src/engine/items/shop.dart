import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'inventory.dart';

class Shop {
  final Drop _drop;

  final String name;

  Shop(this.name, this._drop);

  Inventory create() {
    var inventory = Inventory(ItemLocation.shop(name), Option.shopCapacity);
    update(inventory);
    return inventory;
  }

  Inventory load(Iterable<Item> items) {
    return Inventory(ItemLocation.shop(name), Option.shopCapacity, items);
  }

  void update(Inventory inventory) {
    // Decide how many items we want to have.
    var desiredSize =
        rng.float(Option.shopCapacity * 0.3, Option.shopCapacity * 0.7).toInt();

    // If there are too many, delete some.
    while (inventory.length > desiredSize) {
      inventory.removeAt(rng.range(inventory.length));
    }

    // If there aren't enough, add some.
    while (inventory.length < desiredSize) {
      // Try to add an item.
      _drop.spawnDrop(1, inventory.tryAdd);

      // TODO: Make this smarter. Don't have more than one full stack of any
      // kind of item. Don't have more than a couple identical pieces of
      // equipment.
    }
  }
}
