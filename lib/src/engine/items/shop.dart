import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'inventory.dart';

class Shop {
  final Drop _drop;

  final String name;

  Shop(this.name, this._drop);

  Inventory create() {
    var inventory = Inventory(ItemLocation.shop(name), Option.shopCapacity);

    for (var i = 0; i < 10; i++) {
      update(inventory);
    }

    return inventory;
  }

  Inventory load(Iterable<Item> items) {
    return Inventory(ItemLocation.shop(name), Option.shopCapacity, items);
  }

  void update(Inventory inventory) {
    for (var i = 0; i < 5; i++) {
      // Possibly remove an item. Try to keep the shop ~50% full.
      var deleteChance = inventory.length / (Option.shopCapacity * 0.50);
      if (rng.float() < deleteChance) {
        inventory.removeAt(rng.range(inventory.length));
      }

      // Try to add an item.
      _drop.spawnDrop((item) => inventory.tryAdd(item));

      // TODO: Make this smarter. Don't have more than one full stack of any
      // kind of item. Don't have more than a couple identical pieces of
      // equipment.
    }
  }
}
