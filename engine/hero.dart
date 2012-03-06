/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  Hero(Game game, int x, int y) : super(game, x, y);

  Action nextAction;

  bool get needsInput() => nextAction == null;

  void getAction() {
    final action = nextAction;
    nextAction = null;
    return action;
  }
}
