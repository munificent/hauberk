library hauberk.engine.action.stab;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../game.dart';
import '../option.dart';

/// A melee attack that penetrates a row of actors.
class StabAction extends Action {
  /// How many frames it pauses between each step of the swing.
  static const _FRAME_RATE = 2;

  final Direction _dir;
  int _step = 0;

  StabAction(this._dir);

  ActionResult onPerform() {
    var pos = actor.pos + _dir * (_step ~/ _FRAME_RATE + 1);

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % 2 == 0) {
      addEvent(EventType.STAB, pos: pos, dir: _dir);
    } else if (_step % 2 == 1) {
      var defender = game.stage.actorAt(pos);
      if (defender != null) {
        var attack = actor.getAttack(defender);

        // A stab is weaker than a regular attack.
        // TODO: If we make this consume fury, it can be as strong, or stronger
        // than a normal attack.
        attack.multiplyDamage(0.5);
        attack.perform(this, actor, defender);
      }
    }

    _step++;
    return _step == _FRAME_RATE * 3 ?
        ActionResult.SUCCESS : ActionResult.NOT_DONE;
  }

  int get noise => Option.NOISE_HIT;

  String toString() => '$actor stabs $_dir';
}
