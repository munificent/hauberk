import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// Creates a swath of damage that flows out from a point through reachable
/// tiles.
class FlowAction extends Action {
  /// The centerpoint that the flow is radiating from.
  final Vec _from;
  final Hit _hit;

  Flow _flow;
  List<Vec> _tiles;

  final MotilitySet _motilities;

  bool get isImmediate => false;

  FlowAction(this._from, this._hit, this._motilities);

  ActionResult onPerform() {
    if (_tiles == null) {
      // TODO: Should water open doors? Should fire burn them?
      // TODO: Use a different flow that makes diagonal moves more expensive to
      // give more natural circular behavior?
      _flow =
          new MotilityFlow(game.stage, _from, _motilities, ignoreActors: true);

      var count = (math.PI * _hit.range * _hit.range).ceil();
      _tiles = _flow.reachable.take(count).toList();
    }

    // Hit all tiles at the same distance.
    var distance = _flow.costAt(_tiles.first);
    int end;
    for (end = 0; end < _tiles.length; end++) {
      if (_flow.costAt(_tiles[end]) != distance) break;
    }

    // TODO: Lot of copy/paste here from ray.dart. Unify.
    for (var pos in _tiles.sublist(0, end)) {
      addEvent(EventType.cone, element: _hit.element, pos: pos);

      // See if there is an actor there.
      var target = game.stage.actorAt(pos);
      if (target != null && target != actor) {
        // TODO: Modify damage based on range?
        _hit.perform(this, actor, target, canMiss: false);
      }

      // Hit stuff on the floor too.
      var action = _hit.element.floorAction(pos, _hit, distance);
      if (action != null) addAction(action);
    }

    _tiles = _tiles.sublist(end);
    if (_tiles.isEmpty) return ActionResult.success;

    return ActionResult.notDone;
  }
}

/// Creates an expanding flow of damage centered on the [Actor].
///
/// This class mainly exists as an [Action] that [Item]s can use.
class FlowSelfAction extends Action {
  final Attack _attack;
  final MotilitySet _motilities;

  FlowSelfAction(this._attack, this._motilities);

  ActionResult onPerform() {
    return alternate(
        new FlowAction(actor.pos, _attack.createHit(), _motilities));
  }
}

class FlowFromAction extends Action {
  final Attack _attack;
  final Vec _pos;
  final MotilitySet _motilities;

  FlowFromAction(this._attack, this._pos, this._motilities);

  ActionResult onPerform() {
    return alternate(new FlowAction(_pos, _attack.createHit(), _motilities));
  }
}
