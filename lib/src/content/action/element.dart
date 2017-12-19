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
  /// Not immediate to ensure an actor doesn't get blown into the path of a
  /// yet-to-be-processed tile.
  bool get isImmediate => false;

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

/// Permanently illuminates the given tile.
class LightFloorAction extends Action {
  final Vec _pos;
  int _emanation;

  LightFloorAction(this._pos, Hit hit, num distance) {
    // The intensity fades from the center outward. Also, strong hits produce
    // more light.
    var min = (1.0 + hit.averageDamage.toInt() * 4.0).clamp(0.0, Lighting.max);
    var max = (64.0 + hit.averageDamage * 16.0).clamp(0.0, Lighting.max);
    _emanation =
        lerpDouble(hit.range - distance, 0.0, hit.range, min, max).toInt();
  }

  ActionResult onPerform() {
    game.stage[_pos].emanation += _emanation;
    game.stage.floorEmanationChanged();

    return ActionResult.success;
  }
}
