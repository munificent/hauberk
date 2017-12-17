import '../../engine.dart';

/// Alert nearby sleeping monsters.
class HowlAction extends Action {
  final int _range;

  HowlAction(this._range);

  ActionResult onPerform() {
    log("{1} howls!", actor);

    for (var actor in monster.game.stage.actors) {
      if (actor == monster) continue;

      if (actor is Monster && (actor.pos - monster.pos) <= _range) {
        monster.wakeUp();
        monster.log("{1} wakes up!", monster);
      }
    }

    return ActionResult.success;
  }
}
