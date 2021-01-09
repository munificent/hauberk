import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// Teleports to a random tile with a given range.
class TeleportAction extends Action {
  final int distance;

  TeleportAction(this.distance);

  ActionResult onPerform() {
    var targets = <Vec>[];

    var bounds = Rect.intersect(
        Rect.leftTopRightBottom(actor.x - distance, actor.y - distance,
            actor.x + distance, actor.y + distance),
        game.stage.bounds);

    for (var pos in bounds) {
      if (!actor.willEnter(pos)) continue;
      if (pos - actor.pos > distance) continue;
      targets.add(pos);
    }

    if (targets.isEmpty) {
      return fail("{1} couldn't escape.", actor);
    }

    // Try to teleport as far as possible.
    var best = rng.item(targets);

    for (var tries = 0; tries < 10; tries++) {
      var pos = rng.item(targets);
      if (pos - actor.pos > best - actor.pos) best = pos;
    }

    var from = actor.pos;
    actor.pos = best;
    addEvent(EventType.teleport, actor: actor, pos: from);
    return succeed('{1} teleport[s]!', actor);
  }
}
