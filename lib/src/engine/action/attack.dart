import '../core/actor.dart';
import '../core/option.dart';
import 'action.dart';

/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    // Get all of the melee information from the participants.
    var hit = actor.createMeleeHit();
    hit.perform(this, actor, defender);
    return ActionResult.success;
  }

  int get noise => Option.noiseHit;

  String toString() => '$actor attacks $defender';
}
