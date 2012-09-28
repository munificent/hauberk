class Action {
  Actor _actor;
  Game _game;
  GameResult _gameResult;
  bool _consumesEnergy;

  Game get game() => _game;
  Actor get actor() => _actor;
  // TODO(bob): Should it check that the actor is a hero?
  Hero get hero() => _actor;
  bool get consumesEnergy() => _consumesEnergy;

  void bind(Actor actor, bool consumesEnergy) {
    assert(_actor == null);

    _actor = actor;
    _game = actor.game;
    _consumesEnergy = consumesEnergy;
  }

  ActionResult perform(GameResult gameResult) {
    assert(_actor != null); // Action should be bound already.

    _gameResult = gameResult;
    return onPerform();
  }

  abstract ActionResult onPerform();

  void addEvent(Event event) {
    _gameResult.events.add(event);
  }

  /// How much noise is produced by this action. Override to make certain
  /// actions quieter or louder.
  int get noise() => Option.NOISE_NORMAL;

  void log(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    _game.log.add(message, noun1, noun2, noun3);
  }

  ActionResult succeed([String message, Noun noun1, Noun noun2, Noun noun3]) {
    if (message != null) log(message, noun1, noun2, noun3);
    return ActionResult.SUCCESS;
  }

  ActionResult fail([String message, Noun noun1, Noun noun2, Noun noun3]) {
    if (message != null) log(message, noun1, noun2, noun3);
    return ActionResult.FAILURE;
  }

  ActionResult alternate(Action action) {
    action.bind(_actor, _consumesEnergy);
    return new ActionResult.alternate(action);
  }
}

class ActionResult {
  static final SUCCESS = const ActionResult(succeeded: true, done: true);
  static final FAILURE = const ActionResult(succeeded: false, done: true);
  static final NOT_DONE = const ActionResult(succeeded: true, done: false);

  /// An alternate [Action] that should be performed instead of the one that
  /// failed to perform and returned this. For example, when the [Hero] walks
  /// into a closed door, the [WalkAction] will fail (the door is closed) and
  /// return an alternate [OpenDoorAction] instead.
  final Action alternative;

  /// `true` if the [Action] was successful and energy should be consumed.
  final bool succeeded;

  /// `true` if the [Action] does not need any further processing.
  final bool done;

  const ActionResult([this.succeeded, this.done])
  : alternative = null;

  const ActionResult.alternate(this.alternative)
  : succeeded = false,
    done = true;
}

class WalkAction extends Action {
  final Vec offset;

  WalkAction(this.offset);

  ActionResult onPerform() {
    // Rest if we aren't moving anywhere.
    if (offset == Vec.ZERO) {
      return alternate(new RestAction());
    }

    final pos = actor.pos + offset;

    // See if there is an actor there.
    final target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      return alternate(new AttackAction(target));
    }

    // See if it's a door.
    if (game.stage[pos].type.opensTo != null) {
      return alternate(new OpenDoorAction(pos));
    }

    // See if we can walk there.
    if (!actor.canOccupy(pos)) {
      return fail('{1} hit[s] the wall.', actor);
    }

    actor.pos = pos;

    // See if the hero stepped on anything interesting.
    if (actor is Hero) {
      final item = game.stage.itemAt(pos);
      if (item != null) {
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

/// Action for essentially spending a turn walking in place. This is a separate
/// class mainly to track that it's quieter than walking.
class RestAction extends Action {
  ActionResult onPerform() => succeed();
  int get noise() => Option.NOISE_REST;
}
