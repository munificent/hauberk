import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'element.dart';

/// Base class for an action that touches a conical or circular swath of tiles.
abstract class RayActionBase extends Action {
  /// The centerpoint that the cone is radiating from.
  final Vec _from;

  /// The tile being targeted. The arc of the cone will center on a line from
  /// [_from] to this.
  final Vec _to;

  /// The tiles that have already been touched by the effect. Used to make sure
  /// we don't hit the same tile multiple times.
  final _hitTiles = <Vec>{};

  /// The cone incrementally spreads outward. This is how far we currently are.
  var _radius = 1.0;

  /// We "fill" the cone by tracing a number of rays, each of which can get
  /// obstructed. This is the angle of each ray still being traced.
  final _rays = <double>[];

  bool get isImmediate => false;

  int get range;

  /// Creates a [RayActionBase] radiating from [_from] centered on [_to] (which
  /// may be the same as [_from] if the ray is a full circle. It applies
  /// [_hit] to each touched tile. The rays cover a chord whose width is
  /// [fraction] which varies from 0 (an infinitely narrow line) to 1.0 (a full
  /// circle.
  RayActionBase(this._from, this._to, double fraction) {
    // We "fill" the cone by tracing a number of rays. We need enough of them
    // to ensure there are no gaps when the cone is at its maximum extent.
    var circumference = math.pi * 2 * range;
    var numRays = (circumference * fraction * 2.0).ceil();

    if (fraction < 1.0) {
      // Figure out the center angle of the cone.
      var offset = _to - _from;
      // TODO: Make atan2 getter on Vec?
      var centerTheta = 0.0;
      if (_from != _to) {
        centerTheta = math.atan2(offset.x, offset.y);
      }

      // Create the rays centered on the line from [_from] to [_to].
      for (var i = 0; i < numRays; i++) {
        var theta = (i / (numRays - 1)) - 0.5;
        _rays.add(centerTheta + theta * (math.pi * 2.0 * fraction));
      }
    } else {
      // Create the rays all the way around the circle.
      var thetaStep = math.pi * 2.0 / numRays;
      for (var i = 0; i < numRays; i++) {
        _rays.add(i * thetaStep);
      }
    }
  }

  ActionResult onPerform() {
    if (_radius == 0.0) {
      reachStartTile(_from);
      _radius += 1.0;
      return ActionResult.notDone;
    }

    // TODO: When using this for casting light, should really hit the hero's
    // tile too.

    // See which new tiles each ray hit now.
    _rays.removeWhere((ray) {
      var pos = Vec(_from.x + (math.sin(ray) * _radius).round(),
          _from.y + (math.cos(ray) * _radius).round());

      // TODO: Support rays that hit closed doors but do not go past them. That
      // would let fire attacks set closed doors on fire.

      // Kill the ray if it's obstructed.
      if (!game.stage[pos].isFlyable) return true;

      // Don't hit the same tile twice.
      if (!_hitTiles.add(pos)) return false;

      reachTile(pos, (pos - _from).length);
      return false;
    });

    _radius += 1.0;
    if (_radius > range || _rays.isEmpty) return ActionResult.success;

    // Still going.
    return ActionResult.notDone;
  }

  void reachStartTile(Vec pos) {}

  void reachTile(Vec pos, num distance);
}

/// Creates a swath of damage that radiates out from a point.
class RayAction extends RayActionBase with ElementActionMixin {
  final Hit _hit;

  int get range => _hit.range;

  /// A 45° cone of [hit] centered on the line from [from] to [to].
  factory RayAction.cone(Vec from, Vec to, Hit hit) =>
      RayAction._(hit, from, to, 1.0 / 8.0);

  /// A complete ring of [hit] radiating outwards from [center].
  factory RayAction.ring(Vec center, Hit hit) =>
      RayAction._(hit, center, center, 1.0);

  RayAction._(this._hit, Vec from, Vec to, double fraction)
      : super(from, to, fraction);

  void reachTile(Vec pos, num distance) {
    hitTile(_hit, pos, distance);
  }
}

/// Creates an expanding ring of damage centered on the [Actor].
///
/// This class mainly exists as an [Action] that [Item]s can use.
class RingSelfAction extends Action {
  final Attack _attack;

  RingSelfAction(this._attack);

  bool get isImmediate => false;

  ActionResult onPerform() {
    return alternate(RayAction.ring(actor.pos, _attack.createHit()));
  }
}

class RingFromAction extends Action {
  final Attack _attack;
  final Vec _pos;

  RingFromAction(this._attack, this._pos);

  bool get isImmediate => false;

  ActionResult onPerform() {
    return alternate(RayAction.ring(_pos, _attack.createHit()));
  }
}
