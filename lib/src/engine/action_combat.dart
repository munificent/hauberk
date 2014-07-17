library hauberk.engine.action_combat;

import 'package:piecemeal/piecemeal.dart';

import 'action_base.dart';
import 'actor.dart';
import 'game.dart';
import 'los.dart';
import 'melee.dart';
import 'option.dart';

/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    // Get all of the melee information from the participants.
    final attack = actor.getAttack(defender);
    return attack.perform(this, actor, defender);
  }

  int get noise => Option.NOISE_HIT;

  String toString() => '$actor attacks $defender';
}

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
    final pos = _los.current;

    // Stop if we hit a wall.
    if (!game.stage[pos].isTransparent) return succeed();

    // Stop if we're out of range.
    if (pos - _start > _attack.range) return succeed();

    addEvent(new Event(EventType.BOLT, element: _attack.element, value: pos));

    // See if there is an actor there.
    final target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      var attack = _attack;

      // Being too close or too far weakens the bolt.
      var toTarget = pos - _start;
      if (toTarget <= _minRange || toTarget > _attack.range * 2 / 3) {
        attack = attack.multiplyDamage(0.5);
      }

      return attack.perform(this, actor, target);
    }

    return _los.moveNext() ? ActionResult.NOT_DONE : ActionResult.SUCCESS;
  }
}

class InsultAction extends Action {
  final Actor target;

  InsultAction(this.target);

  ActionResult onPerform() {
    var message = rng.item(const [
       "{1} insult[s] {2 his} mother!",
       "{1} jeer[s] at {2}!",
       "{1} mock[s] {2} mercilessly!",
       "{1} make[s] faces at {2}!"
    ]);

    return succeed(message, actor, target);
  }
}