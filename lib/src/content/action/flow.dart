import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'element.dart';

/// Creates a swath of damage that flows out from a point through reachable
/// tiles.
class FlowAction extends Action with ElementActionMixin {
  /// The centerpoint that the flow is radiating from.
  final Vec _from;
  final Hit _hit;

  late final Flow _flow;
  // TODO: Make this late final?
  List<Vec>? _tiles;

  final Motility _motility;
  final int _slowness;

  @override
  bool get isImmediate => false;

  var _frame = 0;

  // TODO: Support motilities that can flow into closed doors but not out of
  // them. That would let fire flow attacks that can set closed doors on fire.

  FlowAction(this._from, this._hit, this._motility, {int? slowness})
      : _slowness = slowness ?? 1;

  @override
  ActionResult onPerform() {
    // Only animate 1/slowness frames.
    _frame = (_frame + 1) % _slowness;
    if (_frame != 0) {
      addEvent(EventType.pause);
      return ActionResult.notDone;
    }

    if (_tiles == null) {
      // TODO: Use a different flow that makes diagonal moves more expensive to
      // give more natural circular behavior?
      _flow = MotilityFlow(game.stage, _from, _motility, avoidActors: false);

      _tiles = _flow.reachable
          .takeWhile((pos) => _flow.costAt(pos)! <= _hit.range)
          .toList();
    }

    // Hit all tiles at the same distance.
    var distance = _flow.costAt(_tiles!.first)!;
    int end;
    for (end = 0; end < _tiles!.length; end++) {
      if (_flow.costAt(_tiles![end]) != distance) break;
    }

    for (var pos in _tiles!.sublist(0, end)) {
      hitTile(_hit, pos, distance);
    }

    _tiles = _tiles!.sublist(end);
    if (_tiles!.isEmpty) return ActionResult.success;

    return ActionResult.notDone;
  }
}

/// Creates an expanding flow of damage centered on the [Actor].
///
/// This class mainly exists as an [Action] that [Item]s can use.
class FlowSelfAction extends Action {
  final Attack _attack;
  final Motility _motility;

  FlowSelfAction(this._attack, this._motility);

  @override
  ActionResult onPerform() {
    return alternate(FlowAction(actor!.pos, _attack.createHit(), _motility));
  }
}

class FlowFromAction extends Action {
  final Attack _attack;
  final Vec _pos;
  final Motility _motility;

  FlowFromAction(this._attack, this._pos, this._motility);

  @override
  ActionResult onPerform() {
    return alternate(FlowAction(_pos, _attack.createHit(), _motility));
  }
}
