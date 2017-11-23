import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// Sends out a wave of sound, alerting nearby monsters.
class HowlAction extends Action {
  final int _range;
  int _step = 0;
  Flow _flow;

  HowlAction(this._range);

  ActionResult onPerform() {
    if (_flow == null) {
      _flow = new Flow(actor.game.stage, actor.pos, MotilitySet.walkAndFly,
          maxDistance: _range,
          ignoreActors: true);

      log("{1} howls!", actor);
    }

    for (var pos in new Circle(actor.pos, _step).edge) {
      if (!game.stage.bounds.contains(pos)) continue;
      if (_flow.getDistance(pos) == null) continue;

      addEvent(EventType.howl, pos: pos, other: _step / _range);

      var actor = game.stage.actorAt(pos);

      if (actor is! Monster) continue;
      var monster = actor as Monster;

      // TODO: Should also reduce fear.

      if (monster.isAsleep) {
        monster.wakeUp();
        monster.log("{1} wakes up!", monster);
      }
    }

    _step++;
    if (_step > _range) return ActionResult.success;
    return ActionResult.notDone;
  }
}
