import '../../engine.dart';

class EatAction extends Action {
  final int _amount;

  EatAction(this._amount);

  @override
  ActionResult onPerform() {
    if (hero.stomach == Option.heroMaxStomach) {
      show("{1} [are|is] already full!", actor);
    } else if (hero.stomach + _amount > Option.heroMaxStomach) {
      show("{1} [are|is] stuffed!", actor);
    } else {
      show("{1} feel[s] satiated.", actor);
    }

    hero.stomach += _amount;

    return ActionResult.success;
  }
}
