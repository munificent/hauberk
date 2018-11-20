import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// Fires a bolt, a straight line of an elemental attack that stops at the
/// first [Actor] is hits or opaque tile.
class BoltAction extends LosAction {
  final Hit _hit;
  final bool _canMiss;
  final int _range;

  int get range => _range ?? _hit.range;

  BoltAction(Vec target, this._hit, {bool canMiss = false, int range})
      : _canMiss = canMiss,
        _range = range,
        super(target);

  void onStep(Vec previous, Vec pos) {
    // TODO: Include direction.
    addEvent(EventType.bolt,
        element: _hit.element,
        pos: pos,
        dir: (pos - previous).nearestDirection);
  }

  bool onHitActor(Vec pos, Actor target) {
    // TODO: Should range increase odds of missing? If so, do that here. Also
    // need to tweak enemy AI then since they shouldn't always try to maximize
    // distance.
    _hit.perform(this, actor, target, canMiss: _canMiss);
    return true;
  }
}
