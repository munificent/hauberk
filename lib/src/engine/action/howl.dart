library hauberk.engine.action.howl;

import 'action.dart';
import '../circle.dart';
import '../ai/flow.dart';
import '../game.dart';
import '../monster.dart';

/// Sends out a wave of sound, alerting nearby monsters.
class HowlAction extends Action {
  final int _range;
  int _step = 0;
  Flow _flow;

  HowlAction(this._range);

  ActionResult onPerform() {
    if (_flow == null) {
      _flow = new Flow(actor.game.stage, actor.pos,
          maxDistance: _range, canOpenDoors: false, ignoreActors: true);

      log("{1} howls!", actor);
    }

    for (var pos in new Circle(actor.pos, _step).edge) {
      if (!game.stage.bounds.contains(pos)) continue;
      if (_flow.getDistance(pos) == null) continue;

      addEvent(new Event(EventType.HOWL, pos: pos,
          value: _step / _range));

      var monster = game.stage.actorAt(pos);
      if (monster is! Monster) continue;

      // TODO: Should also reduce fear.

      if (monster.isAsleep) {
        monster.wakeUp();
        monster.log("{1} wakes up!", monster);
      }
    }

    _step++;
    if (_step > _range) return ActionResult.SUCCESS;
    return ActionResult.NOT_DONE;
  }
}
