import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// These actions are side effects from taking elemental damage.

abstract class ElementAction extends Action {
  void hitTile(Hit hit, Vec pos, num distance) {
    // Open doors if the given motility lets us go through them.
    // TODO: Set on fire if fire element?
    var tile = game.stage[pos];
    if (tile.type.opensTo != null) {
      tile.type = tile.type.opensTo;
      game.stage.tileOpacityChanged();
    }

    addEvent(EventType.cone, element: hit.element, pos: pos);

    // See if there is an actor there.
    var target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      // TODO: Modify damage based on range?
      hit.perform(this, actor, target, canMiss: false);
    }

    // Hit stuff on the floor too.
    var action = hit.element.floorAction(pos, hit, distance);
    if (action != null) addAction(action);
  }
}

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
    // TODO: Use a different flow that makes diagonal moves more expensive to
    // give more natural circular behavior?
    var flow = new MotilityFlow(game.stage, actor.pos, actor.motilities,
        maxDistance: distance);
    var positions =
        flow.reachable.where((pos) => game.stage.actorAt(pos) == null).toList();
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
    var max = (128.0 + hit.averageDamage * 16.0).clamp(0.0, Lighting.max);
    _emanation =
        lerpDouble(hit.range - distance, 0.0, hit.range, min, max).toInt();
  }

  ActionResult onPerform() {
    game.stage[_pos].emanation += _emanation;
    game.stage.floorEmanationChanged();

    return ActionResult.success;
  }
}
