import '../../engine.dart';

/// An [Action] that gives the hero temporary monster perception.
class PerceiveAction extends Action {
  final int _duration;
  final int _distance;

  PerceiveAction(this._duration, this._distance);

  // TODO: Options for range and monster tag.
  bool get isImmediate => false;

  ActionResult onPerform() {
    var alreadyPerceived = <Actor>{};
    for (var actor in game.stage.actors) {
      if (actor == hero) continue;

      if (hero.canPerceive(actor)) alreadyPerceived.add(actor);
    }

    hero.perception.activate(_duration, _distance);

    var perceived = false;
    for (var actor in game.stage.actors) {
      if (actor == hero) continue;

      if (hero.canPerceive(actor) && !alreadyPerceived.contains(actor)) {
        addEvent(EventType.perceive, actor: actor);
        perceived = true;
      }
    }

    if (perceived) {
      return succeed("{1} perceive[s] monsters beyond your sight!", actor);
    } else {
      return succeed("{1} do[es]n't perceive anything.", actor);
    }
  }
}
