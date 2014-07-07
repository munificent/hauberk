library hauberk.engine.action_combat;

import '../util.dart';
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
  final Iterator<Vec> los;
  final Attack attack;

  BoltAction(Vec from, Vec to, this.attack)
  : los = new Los(from, to).iterator {
    // Advance to the first item.
    los.moveNext();
  }

  ActionResult onPerform() {
    final pos = los.current;

    // Stop if we hit a wall.
    if (!game.stage[pos].isTransparent) return succeed();

    addEvent(new Event(EventType.BOLT, element: attack.element, value: pos));

    // TODO: Chance of missing that increases with distance.

    // See if there is an actor there.
    final target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      return attack.perform(this, actor, target);
    }

    return los.moveNext() ? ActionResult.NOT_DONE : ActionResult.SUCCESS;
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