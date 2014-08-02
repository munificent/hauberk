library hauberk.engine.action_combat;

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'action_base.dart';
import 'actor.dart';
import 'game.dart';
import 'los.dart';
import 'melee.dart';
import 'option.dart';

/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    // Get all of the melee information from the participants.
    final attack = actor.getAttack(defender);
    return attack.perform(this, actor, defender);
  }

  int get noise => Option.NOISE_HIT;

  String toString() => '$actor attacks $defender';
}

class BoltAction extends Action {
  final Vec _start;
  final Iterator<Vec> _los;
  final Attack _attack;

  // TODO: Move to Attack.
  final num _minRange;

  BoltAction(Vec from, Vec to, this._attack, [this._minRange = 0])
      : _start = from,
        _los = new Los(from, to).iterator {
    // Advance to the first tile.
    _los.moveNext();
  }

  ActionResult onPerform() {
    final pos = _los.current;

    // Stop if we hit a wall.
    if (!game.stage[pos].isTransparent) return succeed();

    // Stop if we're out of range.
    if (pos - _start > _attack.range) return succeed();

    addEvent(new Event(EventType.BOLT, element: _attack.element, value: pos));

    // See if there is an actor there.
    final target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      var attack = _attack;

      // Being too close or too far weakens the bolt.
      // TODO: Make this modify strike instead?
      var toTarget = pos - _start;
      if (toTarget <= _minRange || toTarget > _attack.range * 2 / 3) {
        attack = attack.multiplyDamage(0.5);
      }

      return attack.perform(this, actor, target, canMiss: false);
    }

    return _los.moveNext() ? ActionResult.NOT_DONE : ActionResult.SUCCESS;
  }
}

/// Creates a 45° swath of damage that radiates out from a point.
class ConeAction extends Action {
  /// The centerpoint that the cone is radiating from.
  final Vec _from;

  /// The tile being targeted. The arc of the cone will center on a line from
  /// [_from] to this.
  final Vec _to;

  final Attack _attack;

  /// The tiles that have already been touched by the effect. Used to make sure
  /// we don't hit the same tile multiple times.
  final _hitTiles = new Set<Vec>();

  /// The cone incrementally spreads outward. This is how far we currently are.
  var _radius = 1;

  // We "fill" the cone by tracing a number of rays, each of which can get
  // obstructed. This is the angle of each ray still being traced.
  final _rays = <double>[];

  ConeAction(this._from, this._to, this._attack) {
    // Don't hit the creator of the cone.
    _hitTiles.add(_from);

    // We "fill" the cone by tracing a number of rays. We need enough of them
    // to ensure there are no gaps when the cone is at its maximum extent.
    var circumference = math.PI * 2 * _attack.range;
    var numRays = (circumference / 8).ceil();

    // Figure out the center angle of the cone.
    var offset = _to - _from;
    // TODO: Make atan2 getter on Vec?
    var centerTheta = math.atan2(offset.x, offset.y);

    // Create the rays.
    for (var i = 0; i < numRays; i++) {
      var range = (i / (numRays - 1)) - 0.5;
      _rays.add(centerTheta + range * (math.PI / 4));
    }
  }

  ActionResult onPerform() {
    // See which new tiles each ray hit now.
    _rays.removeWhere((ray) {
      var pos = new Vec(
          _from.x + (math.sin(ray) * _radius).round(),
          _from.y + (math.cos(ray) * _radius).round());

      // Kill the ray if it's obstructed.
      if (!game.stage[pos].isTransparent) return true;

      // Don't hit the same tile twice.
      if (_hitTiles.contains(pos)) return false;

      addEvent(new Event(EventType.CONE, value: pos, element: _attack.element));
      _hitTiles.add(pos);

      // See if there is an actor there.
      var target = game.stage.actorAt(pos);
      if (target != null && target != actor) {
        // TODO: Modify damage based on range?
        _attack.perform(this, actor, target, canMiss: false);
      }

      return false;
    });

    _radius++;
    if (_radius > _attack.range || _rays.isEmpty) return ActionResult.SUCCESS;

    // Still going.
    return ActionResult.NOT_DONE;
  }
}

class InsultAction extends Action {
  final Actor target;

  InsultAction(this.target);

  ActionResult onPerform() {
    var message = rng.item(const [
       "{1} insult[s] {2 his} mother!",
       "{1} jeer[s] at {2}!",
       "{1} mock[s] {2} mercilessly!",
       "{1} make[s] faces at {2}!"
    ]);

    return succeed(message, actor, target);
  }
}