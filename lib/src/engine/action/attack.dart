import '../core/actor.dart';
import '../stage/sound.dart';
import 'action.dart';

/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    // Get all of the melee information from the participants.
    var hit = actor.createMeleeHit(defender);
    hit.perform(this, actor, defender);
    return ActionResult.success;
  }

  double get noise => Sound.attackNoise;

  String toString() => '$actor attacks $defender';
}
