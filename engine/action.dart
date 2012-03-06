class Action {
  Actor _actor;

  Actor get actor() => _actor;
  // TODO(bob): Should it check that the actor is a hero?
  Hero get hero() => _actor;

  void bindActor(Actor actor) {
    assert(_actor == null);
    _actor = actor;
  }

  void perform(Game game) {}
}

class MoveAction extends Action {
  final Vec offset;

  MoveAction(this.offset);

  void perform(Game game) {
    final pos = actor.pos + offset;
    if (actor.canOccupy(pos)) {
      actor.pos = pos;
    } else if (actor is Hero) {
      game.log.add('You hit the wall.');
    }
  }
}