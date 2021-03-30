import '../../engine.dart';

class EatAction extends Action {
  final int _amount;

  EatAction(this._amount);

  ActionResult onPerform() {
    if (hero.stomach == Option.heroMaxStomach) {
      log("{1} [is|are] already full!", actor);
    } else if (hero.stomach + _amount > Option.heroMaxStomach) {
      log("{1} [is|are] stuffed!", actor);
    } else {
      log("{1} feel[s] satiated.", actor);
    }

    hero.stomach += _amount;

    return ActionResult.success;
  }
}
