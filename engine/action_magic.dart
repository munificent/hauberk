class HealAction extends Action {
  final int amount;

  HealAction(this.amount);

  ActionResult onPerform() {
    if (actor.health.isMax) {
      return succeed("{1} [don't|doesn't] feel any different.", actor);
    } else {
      actor.health.current += amount;
      addEvent(new Event.heal(actor, amount));
      return succeed('{1} feel[s] better.', actor);
    }
  }
}

class TeleportAction extends Action {
  final int distance;

  TeleportAction(this.distance);

  ActionResult onPerform() {
    final targets = [];

    final bounds = Rect.intersect(
        new Rect(actor.x - distance, actor.y - distance,
                 actor.x + distance, actor.y + distance),
        game.stage.bounds);

    for (var pos in bounds) {
      if (!game.stage[pos].isPassable) continue;
      if (game.stage.actorAt(pos) != null) continue;
      if ((pos - actor.pos).lengthSquared > distance * distance) continue;
      targets.add(pos);
    }

    if (targets.length == 0) {
      return fail("{1} couldn't escape.", actor);
    }

    // Try to teleport as far as possible.
    var bestDistance = -1;
    var best;

    for (var tries = 0; tries < 10; tries++) {
      final pos = rng.item(targets);
      final distance = (pos - actor.pos).lengthSquared;
      if (distance > bestDistance) {
        best = pos;
        bestDistance = distance;
      }
    }

    // TODO(bob): Effect.
    actor.pos = best;
    return succeed('{1} teleport[s] away!', actor);
  }
}

class QuestAction extends Action {
  ActionResult onPerform() {
    game.completeQuest();
    return succeed();
  }
}
