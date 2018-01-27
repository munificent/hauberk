import '../../engine.dart';

/// Heals the [Actor] performing the action.
class HealAction extends Action {
  final int amount;
  final bool curePoison;

  HealAction(this.amount, {this.curePoison: false});

  ActionResult onPerform() {
    var changed = false;

    if (actor.poison.isActive && curePoison) {
      actor.poison.cancel();
      log("{1} [are|is] cleansed of poison.", actor);
      changed = true;
    }

    if (actor.health != actor.maxHealth && amount > 0) {
      actor.health += amount;
      addEvent(EventType.heal, actor: actor, other: amount);
      log('{1} feel[s] better.', actor);
      changed = true;
    }

    if (changed) {
      return ActionResult.success;
    } else {
      return succeed("{1} [don't|doesn't] feel any different.", actor);
    }
  }
}
