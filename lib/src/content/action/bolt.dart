import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../events.dart';

/// Fires a straight line of an attack that stops at the first [Actor] or solid
/// tile that it hits.
class BoltAction extends LosAction {
  final Hit _hit;
  final bool _canMiss;
  final int? _range;
  final EventType _event;

  @override
  int get range => _range ?? _hit.range;

  BoltAction(
    super.target,
    this._hit, {
    bool canMiss = false,
    int? range,
    EventType? event,
  }) : _canMiss = canMiss,
       _range = range,
       _event = event ?? Events.bolt;

  @override
  void onStep(Vec previous, Vec pos) {
    addEvent(
      _event,
      element: _hit.element,
      pos: pos,
      dir: (pos - previous).nearestDirection,
    );
  }

  @override
  bool onHitActor(Vec pos, Actor target) {
    _hit.perform(this, actor, target, canMiss: _canMiss);
    return true;
  }
}
