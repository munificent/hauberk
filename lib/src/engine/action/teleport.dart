library hauberk.engine.action.teleport;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../game.dart';

/// Teleports to a random tile with a given range.
class TeleportAction extends Action {
  final int distance;

  TeleportAction(this.distance);

  ActionResult onPerform() {
    final targets = [];

    final bounds = Rect.intersect(
        new Rect.leftTopRightBottom(
            actor.x - distance, actor.y - distance,
            actor.x + distance, actor.y + distance),
        game.stage.bounds);

    for (var pos in bounds) {
      if (!game.stage[pos].isPassable) continue;
      if (game.stage.actorAt(pos) != null) continue;
      if (pos - actor.pos > distance) continue;
      targets.add(pos);
    }

    if (targets.length == 0) {
      return fail("{1} couldn't escape.", actor);
    }

    // Try to teleport as far as possible.
    var best = rng.item(targets);

    for (var tries = 0; tries < 10; tries++) {
      final pos = rng.item(targets);
      if (pos - actor.pos > best - actor.pos) best = pos;
    }

    var from = actor.pos;
    actor.pos = best;
    addEvent(new Event(EventType.TELEPORT, actor: actor, value: from));
    return succeed('{1} teleport[s]!', actor);
  }
}
