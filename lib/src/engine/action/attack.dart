import '../core/actor.dart';
import '../stage/sound.dart';
import 'action.dart';

/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    for (var hit in actor.createMeleeHits(defender)) {
      hit.perform(this, actor, defender);
      if (!defender.isAlive) break;
    }

    return ActionResult.success;
  }

  double get noise => Sound.attackNoise;

  String toString() => '$actor attacks $defender';
}
