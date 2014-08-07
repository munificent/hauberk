library hauberk.engine.action.walk;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import 'attack.dart';
import '../hero/hero.dart';
import '../option.dart';

class WalkAction extends Action {
  final Vec offset;

  WalkAction(this.offset);

  ActionResult onPerform() {
    // Rest if we aren't moving anywhere.
    if (Vec.ZERO == offset) {
      return alternate(new RestAction());
    }

    final pos = actor.pos + offset;

    // See if there is an actor there.
    final target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      return alternate(new AttackAction(target));
    }

    // See if it's a door.
    var tile = game.stage[pos].type;
    if (tile.opensTo != null) {
      return alternate(new OpenDoorAction(pos));
    }

    // See if we can walk there.
    if (!actor.canOccupy(pos)) {
      return fail('{1} hit[s] the ${tile.name}.', actor);
    }

    actor.pos = pos;

    // See if the hero stepped on anything interesting.
    if (actor is Hero) {
      for (var item in game.stage.itemsAt(pos)) {
        log('{1} [are|is] standing on {2}.', actor, item);
      }
    }

    return succeed();
  }

  String toString() => '$actor walks $offset';
}

class OpenDoorAction extends Action {
  final Vec doorPos;

  OpenDoorAction(this.doorPos);

  ActionResult onPerform() {
    game.stage[doorPos].type = game.stage[doorPos].type.opensTo;
    game.stage.dirtyVisibility();

    return succeed('{1} open[s] the door.', actor);
  }
}

class CloseDoorAction extends Action {
  final Vec doorPos;

  CloseDoorAction(this.doorPos);

  ActionResult onPerform() {
    game.stage[doorPos].type = game.stage[doorPos].type.closesTo;
    game.stage.dirtyVisibility();

    return succeed('{1} close[s] the door.', actor);
  }
}

/// Action for doing nothing for a turn.
class RestAction extends Action {
  ActionResult onPerform() {
    if (actor is Hero) {
      _eatFood();
    } else {
      // Monsters can always rest.
      actor.health.current++;
    }

    return succeed();
  }

  /// Regenerates health when the hero rests, if possible.
  void _eatFood() {
    if (hero.food <= 0) return;
    if (hero.poison.isActive) return;
    if (hero.health.isMax) return;

    hero.food--;
    hero.health.current++;
  }

  int get noise => Option.NOISE_REST;
}
