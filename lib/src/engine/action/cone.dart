library hauberk.engine.action.cone;

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../actor.dart';
import '../game.dart';
import '../melee.dart';

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
