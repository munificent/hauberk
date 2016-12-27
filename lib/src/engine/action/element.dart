import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../hero/hero.dart';

/// These actions are side effects from taking elemental damage.

class BurnAction extends Action {
  final int _resistance;

  BurnAction(num damage, this._resistance);

  ActionResult onPerform() {
    // TODO: If monsters have inventories, need to handle that here.
    if (actor is Hero) _tryBurnItems();

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.success;
  }

  void _tryBurnItems() {
    // If the hero resists, there is a chance to avoid all burning.
    if (_resistance > 0 && !rng.oneIn(_resistance + 1)) return;

    // TODO: Do same thing for equipment slots if there are any flammable
    // equippable items.
    for (var i = 0; i < hero.inventory.length; i++) {
      var item = hero.inventory[i];
      if (item.flags.contains("flammable") && rng.oneIn(5)) {
        log("{1} burns up!", item);
        hero.inventory.removeAt(i);
        i--;
      }
    }
  }
}
