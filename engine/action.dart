class Action {
  Actor _actor;

  Actor get actor() => _actor;
  // TODO(bob): Should it check that the actor is a hero?
  Hero get hero() => _actor;

  ActionResult perform(Game game, Actor actor) {
    assert(_actor == null);
    _actor = actor;

    return onPerform(game);
  }

  ActionResult onPerform(Game game) {
    assert(false); // Must override.
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
    // TODO(bob): Real combat mechanics!
    game.log.add('$actor hits $defender.');
    game.level.actors.remove(defender);

    return ActionResult.success;
  }
}

class MoveAction extends Action {
  final Vec offset;

  MoveAction(this.offset);

  ActionResult onPerform(Game game) {
    final pos = actor.pos + offset;

    // See if there is an actor there.
    final target = game.level.actorAt(pos);
    if (target != null && target != actor) {
      return new ActionResult.alternate(new AttackAction(target));
    }

    // See if we can walk there.
    if (!actor.canOccupy(pos)) {
      if (actor is Hero) {
        game.log.add('You hit the wall.');
      }

      return ActionResult.failure;
    }

    actor.pos = pos;
    return ActionResult.success;
  }
}