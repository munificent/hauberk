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

  /// How much noise is produced by this action. Override to make certain
  /// actions quieter or louder.
  bool get noise() => Option.NOISE_NORMAL;
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

  bool get noise() => Option.NOISE_HIT;

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

    // See if it's a door.
    if (game.level[pos].type == TileType.CLOSED_DOOR) {
      return new ActionResult.alternate(new OpenDoorAction(pos));
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

class OpenDoorAction extends Action {
  final Vec doorPos;

  OpenDoorAction(this.doorPos);

  ActionResult onPerform(Game game) {
    game.level[doorPos].type = TileType.OPEN_DOOR;
    game.level.dirtyVisibility();
    game.level.dirtyPathfinding();

    game.log.add('{1} open[s] the door.', actor);

    return ActionResult.SUCCESS;
  }

  String toString() => '$actor moves $offset';
}

class CloseDoorAction extends Action {
  final Vec doorPos;

  CloseDoorAction(this.doorPos);

  ActionResult onPerform(Game game) {
    game.level[doorPos].type = TileType.CLOSED_DOOR;
    game.level.dirtyVisibility();
    game.level.dirtyPathfinding();

    game.log.add('{1} close[s] the door.', actor);

    return ActionResult.SUCCESS;
  }

  String toString() => '$actor moves $offset';
}

/// Action for essentially spending a turn walking in place. This is a separate
/// class mainly to track that it's quieter than walking.
class RestAction extends Action {
  ActionResult onPerform(Game game) {
    return ActionResult.SUCCESS;
  }

  bool get noise() => Option.NOISE_REST;
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

class UseAction extends Action {
  // TODO(bob): Right now, it assumes you always use an inventory item. May
  // want to support using items on the ground at some point.
  final int index;

  UseAction(this.index);

  ActionResult onPerform(Game game) {
    final item = hero.inventory[index];
    final use = item.type.use;
    if (use == null) {
      game.log.add("{1} can't be used.", item);
      return ActionResult.FAILURE;
    }

    hero.inventory.remove(index);

    use(game, this);

    return ActionResult.SUCCESS;
  }
}
