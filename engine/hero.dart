/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  // TODO(bob): Let user specify.
  final Gender gender = Gender.MALE;

  Action nextAction;
  final Inventory inventory;

  Hero(Game game, int x, int y)
  : super(game, x, y, Option.HERO_START_HEALTH),
    inventory = new Inventory();

  // TODO(bob): Hackish.
  get appearance() => 'hero';

  bool get needsInput() => nextAction == null;

  Action getAction() {
    final action = nextAction;
    nextAction = null;
    return action;
  }

  Attack getAttack(Actor defender) {
    // TODO(bob): Temp.
    return new Attack('punch[es]', 4);
  }

  void takeHit(Hit hit) {
    // TODO(bob): Temp.
    hit.bindDefense(strike: Option.STRIKE_HERO);
  }

  Vec changePosition(Vec pos) {
    game.dirtyVisibility();
    game.level.dirtyPathfinding();
    return pos;
  }

  String get nounText() => 'you';
  int get person() => 2;
}
