class Action {
  Actor _actor;
  Game _game;
  GameResult _gameResult;

  Actor get actor() => _actor;
  // TODO(bob): Should it check that the actor is a hero?
  Hero get hero() => _actor;

  ActionResult perform(Game game, GameResult gameResult, Actor actor) {
    assert(_actor == null);
    _actor = actor;
    _game = game;
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

  ActionResult succeed([String message, Noun noun1, Noun noun2, Noun noun3]) {
    if (message != null) {
      _game.log.add(message, noun1, noun2, noun3);
    }

    return ActionResult.SUCCESS;
  }

  ActionResult fail([String message, Noun noun1, Noun noun2, Noun noun3]) {
    if (message != null) {
      _game.log.add(message, noun1, noun2, noun3);
    }

    return ActionResult.FAILURE;
  }

  ActionResult alternate(Action action) {
    return new ActionResult.alternate(action);
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

class MoveAction extends Action {
  final Vec offset;

  MoveAction(this.offset);

  ActionResult onPerform(Game game) {
    // Rest if we aren't moving anywhere.
    if (offset == Vec.ZERO) {
      return alternate(new RestAction());
    }

    final pos = actor.pos + offset;

    // See if there is an actor there.
    final target = game.level.actorAt(pos);
    if (target != null && target != actor) {
      return alternate(new AttackAction(target));
    }

    // See if it's a door.
    if (game.level[pos].type == TileType.CLOSED_DOOR) {
      return alternate(new OpenDoorAction(pos));
    }

    // See if we can walk there.
    if (!actor.canOccupy(pos)) {
      return fail('{1} hit[s] the wall.', actor);
    }

    actor.pos = pos;
    return succeed();
  }

  String toString() => '$actor moves $offset';
}

class OpenDoorAction extends Action {
  final Vec doorPos;

  OpenDoorAction(this.doorPos);

  ActionResult onPerform(Game game) {
    game.level[doorPos].type = TileType.OPEN_DOOR;
    game.level.dirtyVisibility();

    return succeed('{1} open[s] the door.', actor);
  }

  String toString() => '$actor moves $offset';
}

class CloseDoorAction extends Action {
  final Vec doorPos;

  CloseDoorAction(this.doorPos);

  ActionResult onPerform(Game game) {
    game.level[doorPos].type = TileType.CLOSED_DOOR;
    game.level.dirtyVisibility();

    return succeed('{1} close[s] the door.', actor);
  }

  String toString() => '$actor moves $offset';
}

/// Action for essentially spending a turn walking in place. This is a separate
/// class mainly to track that it's quieter than walking.
class RestAction extends Action {
  ActionResult onPerform(Game game) => succeed();
  bool get noise() => Option.NOISE_REST;
}
