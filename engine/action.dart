class Action {
  Actor _actor;
  GameResult _gameResult;

  Actor get actor() => _actor;
  // TODO(bob): Should it check that the actor is a hero?
  Hero get hero() => _actor;

  ActionResult perform(Game game, GameResult gameResult, Actor actor) {
    assert(_actor == null);
    _actor = actor;
    _gameResult = gameResult;

    return onPerform(game);
  }

  ActionResult onPerform(Game game) {
    assert(false); // Must override.
  }

  void addEvent(Event event) {
    _gameResult.events.add(event);
  }
}

class ActionResult {
  static final success = const ActionResult(succeeded: true);
  static final failure = const ActionResult(succeeded: false);

  /// An alternate [Action] that should be performed instead of the one that
  /// failed to perform and returned this. For example, when the [Hero] walks
  /// into a closed door, the [WalkAction] will fail (the door is closed) and
  /// return an alternate [OpenDoorAction] instead.
  final Action alternate;

  /// `true` if the [Action] was successful and energy should be consumed.
  final bool succeeded;

  const ActionResult([bool this.succeeded])
  : alternate = null;

  const ActionResult.alternate(this.alternate)
  : succeeded = false;
}

class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform(Game game) {
    final hit = actor.getHit(defender);
    defender.takeHit(hit);

    // Ask the defender how hard it is to hit.
    var strike = hit.strike;

    // TODO(bob): Modify by the attacker's strike bonus.

    // Keep it in bounds. We clamp it to [5, 95] so there is always some chance
    // of a hit or a miss.
    strike = clamp(Option.STRIKE_MIN, strike, Option.STRIKE_MAX);

    final strikeRoll = rng.inclusive(1, 100);

    if (strikeRoll < strike) {
      // A swing and a miss!
      game.log.add('{1} miss[es] {2}.', actor, defender);
      return ActionResult.success;
    }

    // The hit made contact.
    final damage = rng.triangleInt(hit.damage, hit.damageRange);
    defender.health.current -= damage;

    if (defender.health.current == 0) {
      game.log.add('{1} kill[s] {2}.', actor, defender);

      if (defender is! Hero) {
        game.level.actors.remove(defender);
      }
    } else {
      final health = defender.health;
      game.log.add('{1} hit[s] {2} (${health.current}/${health.max}).',
        actor, defender);

      addEvent(new Event.hit(defender, damage));
    }

    return ActionResult.success;
  }

  String toString() => '$actor attacks $defender';
}

class Hit {
  /// The average (i.e. center) damage.
  final int damage;

  /// The range that damage can be around [damage].
  final int damageRange;

  int strike;

  Hit(this.damage, this.damageRange);

  void bindDefense([int strike]) {
    this.strike = strike;
  }
}

class MoveAction extends Action {
  final Vec offset;

  MoveAction(this.offset);

  ActionResult onPerform(Game game) {
    // Rest if we aren't moving anywhere.
    if (offset == Vec.ZERO) {
      return new ActionResult.alternate(new RestAction());
    }

    final pos = actor.pos + offset;

    // See if there is an actor there.
    final target = game.level.actorAt(pos);
    if (target != null && target != actor) {
      return new ActionResult.alternate(new AttackAction(target));
    }

    // See if we can walk there.
    if (!actor.canOccupy(pos)) {
      game.log.add('{1} hit[s] the wall.', actor);
      return ActionResult.failure;
    }

    actor.pos = pos;
    return ActionResult.success;
  }

  String toString() => '$actor moves $offset';
}

class RestAction extends Action {
  ActionResult onPerform(Game game) {
    if (actor.health.isMax) {
      // Don't do anything if already maxed.
      actor.restCount = 0;
    } else {
      // TODO(bob): Could have "regeneration" power-up that speeds this.
      // The greater the max health, the faster the actor heals when resting.
      final turnsNeeded = Math.max(
          Option.REST_MAX_HEALTH_FOR_RATE ~/ actor.health.max, 1);

      if (actor.restCount++ > turnsNeeded) {
        actor.health.current++;
        actor.restCount = 0;
        // TODO(bob): Temp.
        game.log.add('{1} rest[s].', actor);
      }
    }

    return ActionResult.success;
  }
}
