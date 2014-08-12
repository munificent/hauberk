library hauberk.engine.action.bolt;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../actor.dart';
import '../game.dart';
import '../los.dart';
import '../melee.dart';

/// Fires a bolt, a straight line of an elemental attack that stops at the
/// first [Actor] is hits or opaque tile.
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
    var pos = _los.current;

    // Stop if we hit a wall.
    if (!game.stage[pos].isTransparent) return succeed();

    // Stop if we're out of range.
    if (pos - _start > _attack.range) return succeed();

    addEvent(EventType.BOLT, element: _attack.element, pos: pos);

    // See if there is an actor there.
    var target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      var attack = _attack;

      // Being too close or too far weakens the bolt.
      // TODO: Make this modify strike instead?
      var toTarget = pos - _start;
      if (toTarget <= _minRange || toTarget > _attack.range * 2 / 3) {
        attack = attack.multiplyDamage(0.5);
      }

      attack.perform(this, actor, target, canMiss: false);
      return ActionResult.SUCCESS;
    }

    return _los.moveNext() ? ActionResult.NOT_DONE : ActionResult.SUCCESS;
  }
}
