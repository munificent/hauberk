/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  // TODO(bob): Let user specify.
  final Gender gender = Gender.MALE;

  Action nextAction;

  Hero(Game game, int x, int y) : super(game, x, y);

  // TODO(bob): Hackish.
  get appearance() => 'hero';

  bool get needsInput() => nextAction == null;

  void getAction() {
    final action = nextAction;
    nextAction = null;
    return action;
  }

  Vec changePosition(Vec pos) {
    game.dirtyVisibility();
    game.level.dirtyPathfinding();
    return pos;
  }

  String get nounText() => 'you';
  int get person() => 2;
}
