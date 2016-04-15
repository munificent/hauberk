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
    var attack = actor.getAttack(defender);
    attack.perform(this, actor, defender);
    return ActionResult.success;
  }

  int get noise => Option.noiseHit;

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