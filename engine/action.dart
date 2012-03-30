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
  static final SUCCESS = const ActionResult(succeeded: true);
  static final FAILURE = const ActionResult(succeeded: false);

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
    final attack = actor.getAttack(defender);
    final hit = new Hit(attack);
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
      return ActionResult.SUCCESS;
    }

    // The hit made contact.
    final damage = rng.triangleInt(attack.damage, attack.damage ~/ 2);
    defender.health.current -= damage;

    if (defender.health.current == 0) {
      game.log.add('{1} kill[s] {2}.', actor, defender);

      addEvent(new Event.kill(defender));

      if (defender is! Hero) {
        game.level.actors.remove(defender);
      }
    } else {
      final health = defender.health;
      game.log.add('{1} ${attack.verb} {2}.', actor, defender);

      addEvent(new Event.hit(defender, damage));
    }

    return ActionResult.SUCCESS;
  }

  String toString() => '$actor attacks $defender';
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
      return ActionResult.FAILURE;
    }

    actor.pos = pos;
    return ActionResult.SUCCESS;
  }

  String toString() => '$actor moves $offset';
}

class RestAction extends Action {
  ActionResult onPerform(Game game) {
    if (actor.health.isMax) {
      // Don't do anything if already maxed.
      actor.restCount = 0;
    } else {
      // The hero can only rest if not hungry.
      if (actor is Hero) {
        if (hero.hunger < Option.HUNGER_MAX) {
          hero.hunger++;
        } else {
          game.log.add('{1} [are|is] too hungry to rest!', actor);
          return ActionResult.SUCCESS;
        }
      }

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

      // Whenever the hero rests, there is a chance for new monsters to appear
      // in unexplored areas of the level. This is to discourage the player
      // from resting too much.
      if (actor is Hero) {
        if (rng.oneIn(Option.REST_SPAWN_CHANCE)) {
          final pos = rng.vecInRect(game.level.bounds);
          final tile = game.level[pos];
          if (!tile.isExplored && tile.isPassable) {
            final monster = rng.item(game.breeds).spawn(game, pos);
            game.log.add('Spawned ${monster.breed.name} at $pos.');
            game.level.actors.add(monster);
          }
        }
      }
    }

    return ActionResult.SUCCESS;
  }
}

class PickUpAction extends Action {
  ActionResult onPerform(Game game) {
    final item = game.level.itemAt(actor.pos);
    if (item == null) {
      game.log.add('There is nothing here.');
      return ActionResult.FAILURE;
    }

    if (!hero.inventory.tryAdd(item)) {
      game.log.add("{1} [don't|doesn't] have room for {2}.", actor, item);
      return ActionResult.FAILURE;
    }
    // Remove it from the level.
    // TODO(bob): Hackish.
    for (var i = 0; i < game.level.items.length; i++) {
      if (game.level.items[i] == item) {
        game.level.items.removeRange(i, 1);
        break;
      }
    }

    game.log.add('{1} pick[s] up {2}.', actor, item);
    return ActionResult.SUCCESS;
  }
}

class DropAction extends Action {
  final int index;

  DropAction(this.index);

  ActionResult onPerform(Game game) {
    final item = hero.inventory.remove(index);
    item.pos = hero.pos;
    game.level.items.add(item);

    game.log.add('{1} drop[s] {2}.', actor, item);

    return ActionResult.SUCCESS;
  }
}
