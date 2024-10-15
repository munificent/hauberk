import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// Teleports to a random tile with a given range.
class TeleportAction extends Action {
  final int distance;

  TeleportAction(this.distance);

  @override
  ActionResult onPerform() {
    var targets = <Vec>[];

    var actorPos = actor!.pos;
    var bounds = Rect.intersect(
        Rect.leftTopRightBottom(actorPos.x - distance, actorPos.y - distance,
            actorPos.x + distance, actorPos.y + distance),
        game.stage.bounds);

    for (var pos in bounds) {
      if (!game.stage.willEnter(pos, actor!.motility)) continue;
      if (pos - actor!.pos > distance) continue;
      targets.add(pos);
    }

    if (targets.isEmpty) {
      return fail("{1} couldn't escape.", actor);
    }

    // Try to teleport as far as possible.
    var best = rng.item(targets);

    for (var tries = 0; tries < 10; tries++) {
      var pos = rng.item(targets);
      if (pos - actor!.pos > best - actor!.pos) best = pos;
    }

    var from = actor!.pos;
    moveActor(actor!, best);
    addEvent(EventType.teleport, actor: actor, pos: from);
    return succeed('{1} teleport[s]!', actor);
  }
}
