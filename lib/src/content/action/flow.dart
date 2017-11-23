import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

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
