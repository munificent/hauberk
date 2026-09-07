import '../../engine.dart';
import '../races.dart';

class FlitterAbility extends Ability with ActionAbility {
  @override
  String get name => "Flitter";

  @override
  List<Requirement> get requirements => [RaceRequirement(Races.fae)];

  @override
  Action onGetAction(Game game) => FlyAction();
}

class FlyAction extends Action {
  @override
  ActionResult onPerform() {
    var hero = game.hero;

    if (hero.flying.isActive) {
      hero.flying.cancel();
    } else {
      // TODO: Extend the duration based on strength?
      hero.flying.activate(8);
      log("{1} unfold your wings and take flight.", actor);
    }

    return ActionResult.success;
  }
}
