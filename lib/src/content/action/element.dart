/// These actions are side effects from taking elemental damage.
import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../elements.dart';
import '../tiles.dart';

mixin ElementActionMixin implements Action {
  void hitTile(Hit hit, Vec pos, num distance, [int fuel = 0]) {
    // Open tiles if the given motility lets us go through them.
    var tile = game.stage[pos];
    if (tile.type.canOpen) {
      addAction(tile.type.onOpen(pos));
    }

    addEvent(EventType.cone, element: hit.element, pos: pos);

    // See if there is an actor there.
    var target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      // TODO: Modify damage based on range?
      hit.perform(this, actor, target, canMiss: false);
    }

    // Hit stuff on the floor too.
    var action = hit.element.floorAction(pos, hit, distance, fuel);
    if (action != null) addAction(action);
  }
}

/// Side-effect action when an actor has been hit with an [Elements.fire]
/// attack.
class BurnActorAction extends Action with DestroyActionMixin {
  ActionResult onPerform() {
    destroyHeldItems(Elements.fire);

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.success;
  }
}

/// Side-effect action when an [Elements.fire] area attack sweeps over a tile.
class BurnFloorAction extends Action with DestroyActionMixin {
  final Vec _pos;
  final int _damage;
  final int _fuel;

  BurnFloorAction(this._pos, this._damage, this._fuel);

  ActionResult onPerform() {
    var fuel = _fuel + destroyFloorItems(_pos, Elements.fire);

    // Try to set the tile on fire.
    var tile = game.stage[_pos];
    var ignition = Tiles.ignition(tile.type);
    if (fuel > 0 || ignition > 0 && _damage > rng.range(ignition)) {
      fuel += Tiles.fuel(tile.type);
      tile.substance = rng.range(fuel ~/ 2, fuel);

      // Higher damage instantly burns off some of the fuel, leaving less to
      // burn over time.
      tile.substance -= _damage ~/ 4;
      if (tile.substance <= 0) tile.substance = 1;

      tile.element = Elements.fire;
      game.stage.floorEmanationChanged();
    }

    return ActionResult.success;
  }
}

/// Action created by the [Elements.fire] substance each turn a tile continues
/// to burn.
class BurningFloorAction extends Action with DestroyActionMixin {
  final Vec _pos;

  BurningFloorAction(this._pos);

  ActionResult onPerform() {
    // See if there is an actor there.
    var target = game.stage.actorAt(_pos);
    if (target != null) {
      // TODO: What should the damage be?
      var hit = Attack(Noun("fire"), "burns", 10, 0, Elements.fire).createHit();
      hit.perform(this, null, target, canMiss: false);
    }

    // Try to burn items.
    game.stage[_pos].substance += destroyFloorItems(_pos, Elements.fire);
    return ActionResult.success;
  }
}

/// Side-effect action when an [Elements.cold] area attack sweeps over a tile.
class FreezeFloorAction extends Action with DestroyActionMixin {
  final Vec _pos;

  FreezeFloorAction(this._pos);

  ActionResult onPerform() {
    destroyFloorItems(_pos, Elements.cold);

    // TODO: Put out fire.

    return ActionResult.success;
  }
}

/// Side-effect action when an [Elements.poison] area attack sweeps over a tile.
class PoisonFloorAction extends Action with DestroyActionMixin {
  final Vec _pos;
  final int _damage;

  PoisonFloorAction(this._pos, this._damage);

  ActionResult onPerform() {
    var tile = game.stage[_pos];

    // Fire beats poison.
    if (tile.element == Elements.fire && tile.substance > 0) {
      return ActionResult.success;
    }

    // Try to fill the tile with poison gas.
    if (tile.isFlyable) {
      tile.element = Elements.poison;
      tile.substance = (tile.substance + _damage * 16).clamp(0, 255);
    }

    return ActionResult.success;
  }
}

/// Action created by the [Elements.poison] substance each turn a tile contains
/// poisonous gas.
class PoisonedFloorAction extends Action with DestroyActionMixin {
  final Vec _pos;

  PoisonedFloorAction(this._pos);

  ActionResult onPerform() {
    // See if there is an actor there.
    var target = game.stage.actorAt(_pos);
    if (target != null) {
      // TODO: What should the damage be?
      var hit =
          Attack(Noun("poison"), "chokes", 4, 0, Elements.poison).createHit();
      hit.perform(this, null, target, canMiss: false);
    }

    return ActionResult.success;
  }
}

class WindAction extends Action {
  /// Not immediate to ensure an actor doesn't get blown into the path of a
  /// yet-to-be-processed tile.
  bool get isImmediate => false;

  ActionResult onPerform() {
    // Move the actor to a random reachable tile. Flying actors get blown more.
    var distance = actor.motility.overlaps(Motility.fly) ? 6 : 3;

    // Don't blow through doors.
    var motility = actor.motility - Motility.door;
    var flow =
        MotilityFlow(game.stage, actor.pos, motility, maxDistance: distance);
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
