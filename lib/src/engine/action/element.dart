import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../hero/hero.dart';

/// These actions are side effects from taking elemental damage.

abstract class DestroyItemsMixin extends Action {
  int get resistance;

  void destroyItems(int chance, String flag, String message) {
    // TODO: If monsters have inventories, need to handle that here.
    if (actor is! Hero) return;

    // If the hero resists, there is a chance to avoid all burning.
    if (resistance > 0 && !rng.oneIn(resistance + 1)) return;

    // TODO: Do same thing for equipment slots if there are any flammable
    // equippable items.
    for (var i = 0; i < hero.inventory.length; i++) {
      var item = hero.inventory[i];
      if (item.flags.contains(flag) && rng.oneIn(chance)) {
        log("{1} $message!", item);
        hero.inventory.removeAt(i);
        i--;
      }
    }
  }
}

class BurnAction extends Action with DestroyItemsMixin {
  final int resistance;

  BurnAction(num damage, this.resistance);

  ActionResult onPerform() {
    destroyItems(5, "flammable", "burns up");

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.success;
  }
}
