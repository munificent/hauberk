library hauberk.engine.action.element;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../items/item.dart';

/// These actions are side effects from taking elemental damage.

class BurnAction extends Action {
  BurnAction(num damage);

  ActionResult onPerform() {
    // TODO: Burn flammable items.
    hero.inventory.forEach((Item item){
      if (rng.range(100) < item.type.flammable) {
        log("{1} burns!", item);
      }
    });

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.SUCCESS;
  }
}
