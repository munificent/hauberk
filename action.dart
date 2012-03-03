class Action {
  void perform(Game game, Actor actor) {}
}

class MoveAction extends Action {
  final Vec offset;

  MoveAction(this.offset);

  void perform(Game game, Actor actor) {
    actor.pos += offset;
  }
}