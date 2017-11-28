import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// These actions are side effects from taking elemental damage.

class BurnAction extends Action {
  ActionResult onPerform() {
    addAction(new DestroyInInventoryAction(5, "flammable", "burns up"), actor);

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.success;
  }
}

class WindAction extends Action {
  ActionResult onPerform() {
    // Move the actor to a random reachable tile.
    var distance = actor.motilities.contains(Motility.fly) ? 6 : 3;
    // TODO: Using the actor's motilities here is a little weird. It means, for
    // example, that humans can be blown through doors and amphibians can be
    // blown into water. Is that what we want?
    var flow = new Flow(game.stage, actor.pos, actor.motilities,
        maxDistance: distance);
    var positions =
        flow.findAll().where((pos) => game.stage.actorAt(pos) == null).toList();
    if (positions.isEmpty) return ActionResult.failure;

    log("{1} [are|is] thrown by the wind!", actor);
    addEvent(EventType.wind, actor: actor, pos: actor.pos);
    actor.pos = rng.item(positions);

    return ActionResult.success;
  }
}
