import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'element.dart';

/// Creates a swath of damage that radiates out from a point.
class BarrierAction extends ElementAction {
  /// The center of the barrier.
  final Vec _center;

  final double _h;
  final double _v;

  final Hit _hit;

  /// The tiles that have already been touched by the effect. Used to make sure
  /// we don't hit the same tile multiple times.
  final _hitTiles = Set<Vec>();

  /// The barrier incrementally spreads outward. This is how far we currently
  /// are.
  var _distance = 0.0;

  /// Whether the barrier has hit a wall in the positive direction.
  bool _goingPositive = true;

  /// Whether the barrier has hit a wall in the negative direction.
  bool _goingNegative = true;

  bool get isImmediate => false;

  factory BarrierAction(Vec from, Vec to, Hit hit) {
    // The barrier spreads out perpendicular to the line from the actor to the
    // target. Swapping the coordinates does a 90° rotation.
    var offset = from - to;
    var h = -offset.y.toDouble();
    var v = offset.x.toDouble();

    // Normalize to unit distance.
    var length = offset.length;
    h /= length;
    v /= length;

    return BarrierAction._(to, h, v, hit);
  }

  /// Creates a [RayAction] radiating from [_from] centered on [_to] (which
  /// may be the same as [_from] if the ray is a full circle. It applies
  /// [_hit] to each touched tile. The rays cover a chord whose width is
  /// [fraction] which varies from 0 (an infinitely narrow line) to 1.0 (a full
  /// circle.
  BarrierAction._(this._center, this._h, this._v, this._hit);

  ActionResult onPerform() {
    while (_distance < 6.0) {
      var madeProgress = false;

      tryDirection(bool going, int sign) {
        if (!going) return false;

        tryOffset(double h, double v) {
          var offset =
              Vec((_h * _distance + h).round(), (_v * _distance + v).round());
          var pos = _center + offset * sign;
          if (!game.stage[pos].canEnter(Motility.fly)) return false;

          if (_hitTiles.add(pos)) {
            // TODO: Tune fuel.
            hitTile(_hit, pos, _distance, rng.range(30, 40));
            madeProgress = true;
          }

          return true;
        }

        var allStopped = true;
        if (tryOffset(0.0, 0.0)) allStopped = false;

        // TODO: Hackish. We want to ensure that a diagonal barrier doesn't
        // leave any gaps, so we sort of cheat it outwards. Do something better.
        if (tryOffset(-0.1, 0.0)) allStopped = false;
        if (tryOffset(0.1, 0.0)) allStopped = false;
        if (tryOffset(0.0, -0.1)) allStopped = false;
        if (tryOffset(0.0, 0.1)) allStopped = false;

        return !allStopped;
      }

      _goingPositive = tryDirection(_goingPositive, 1);
      _goingNegative = tryDirection(_goingNegative, -1);

      if (madeProgress) return ActionResult.notDone;

      _distance += 0.1;
    }

    return ActionResult.success;
  }
}
