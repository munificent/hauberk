/// These actions are side effects from taking elemental damage.
import 'package:piecemeal/piecemeal.dart';

import '../elements.dart';
import '../tiles.dart';
import '../../engine.dart';

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

/// Side-effect action when an actor has been hit with an [Elements.fire]
/// attack.
class BurnActorAction extends Action {
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

/// Side-effect action when an [Elements.fire] area attack sweeps over a tile.
class BurnFloorAction extends Action {
  final Vec _pos;
  final int _damage;

  BurnFloorAction(this._pos, this._damage);

  ActionResult onPerform() {
    addAction(new DestroyOnFloorAction(_pos, 3, "flammable", "burns up"));

    // Try to set the tile on fire.
    var tile = game.stage[_pos];
    var ignition = Tiles.ignition(tile.type);
    if (ignition > 0 && _damage > rng.range(ignition)) {
      var fuel = Tiles.fuel(tile.type);
      tile.substance = rng.range(fuel ~/ 2, fuel);

      // Higher damage instantly burns off some of the fuel, leaving less to
      // burn over time.
      tile.substance -= _damage ~/ 4;
      if (tile.substance == 0) tile.substance = 1;

      tile.element = Elements.fire;
      game.stage.floorEmanationChanged();
    }

    return ActionResult.success;
  }
}

/// Action created by the [Elements.fire] substance each turn a tile continues
/// to burn.
class BurningFloorAction extends Action {
  final Vec _pos;

  BurningFloorAction(this._pos);

  ActionResult onPerform() {
    // See if there is an actor there.
    var target = game.stage.actorAt(_pos);
    if (target != null) {
      // TODO: What should the damage be?
      var hit = new Attack(new Noun("fire"), "burns", 10, 0, Elements.fire)
          .createHit();
      // TODO: Modify damage based on range?
      hit.perform(this, null, target, canMiss: false);
    }

    // Try to burn items.
    addAction(new DestroyOnFloorAction(_pos, 3, "flammable", "burns up"));
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
    game.stage[_pos].addEmanation(_emanation);
    game.stage.floorEmanationChanged();

    return ActionResult.success;
  }
}
