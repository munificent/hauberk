library hauberk.engine.action.attack;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../actor.dart';
import '../option.dart';

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