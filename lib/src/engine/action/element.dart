library hauberk.engine.action.element;

import 'action.dart';

/// These actions are side effects from taking elemental damage.

class BurnAction extends Action {
  BurnAction(num damage);

  ActionResult onPerform() {
    // TODO: Burn flammable items.

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.SUCCESS;
  }
}
