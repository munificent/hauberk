/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  // TODO(bob): Let user specify.
  final Gender gender = Gender.MALE;

  final Inventory inventory;

  /// Resting increases this. Eating food lowers it. If it reaches
  /// [Option.HUNGER_MAX] then resting is ineffective.
  int hunger = 0;

  Behavior _behavior;

  Hero(Game game, int x, int y)
  : super(game, x, y, Option.HERO_START_HEALTH),
    inventory = new Inventory();

  // TODO(bob): Hackish.
  get appearance() => 'hero';

  bool get needsInput() {
    if ((_behavior != null) && !_behavior.canPerform(this)) {
      waitForInput();
    }

    return _behavior == null;
  }

  Action getAction() => _behavior.getAction(this);

  Attack getAttack(Actor defender) {
    // TODO(bob): Temp.
    return new Attack('punch[es]', 4);
  }

  void takeHit(Hit hit) {
    // TODO(bob): Nothing to do yet. Should eventually handle armor.
    disturb();
  }

  Vec changePosition(Vec pos) {
    game.level.dirtyVisibility();
    return pos;
  }

  void regenerate() {
    // The hero can only rest if not hungry.
    if (hunger < Option.HUNGER_MAX) {
      hunger++;
      super.regenerate();
    }
  }

  void waitForInput() {
    _behavior = null;
  }

  void setNextAction(Action action) {
    _behavior = new ActionBehavior(action);
  }

  void rest() {
    _behavior = new RestBehavior();
  }

  void run(Direction direction) {
    _behavior = new RunBehavior(direction);
  }

  void disturb() {
    if (_behavior is! ActionBehavior) waitForInput();
  }

  String get nounText() => 'you';
  int get person() => 2;
}

/// What the [Hero] is "doing". If the hero has no behavior, he is waiting for
/// user input. Otherwise, the behavior will determine which [Action]s he
/// performs.
interface Behavior {
  bool canPerform(Hero hero);
  Action getAction(Hero hero);
}

/// A simple one-shot behavior that performs a given [Action] and then reverts
/// back to waiting for input.
class ActionBehavior implements Behavior {
  final Action action;

  ActionBehavior(this.action);

  bool canPerform(Hero hero) => true;

  Action getAction(Hero hero) {
    hero.waitForInput();
    return action;
  }
}

/// Automatic resting. With this [Behavior], the [Hero] will rest each turn
/// until any of the following occurs:
///
/// * He is fully rested.
/// * He gets hungry.
/// * He is "disturbed" and something gets hit attention, like a [Monster]
///   moving, being hit, etc.
class RestBehavior implements Behavior {
  bool canPerform(Hero hero) {
    // See if done resting.
    if (hero.health.isMax) return false;

    // Can't rest while hungry.
    if (hero.hunger == Option.HUNGER_MAX) {
      // TODO(bob): This message doesn't actually display immediately. Because
      // it gets added and then no turn is processed, the screen doesn't
      // refresh.
      hero.game.log.add('{1} [are|is] too hungry to rest.', hero);
      return false;
    }

    return true;
  }

  Action getAction(Hero hero) => new RestAction();
}

/// Automatic running. The [Hero] will continue to walk in a given direction
/// until:
///
/// * He hits a wall.
/// * He is disturbed.
class RunBehavior implements Behavior {
  bool firstStep = true;
  Direction direction;

  RunBehavior(this.direction);

  bool canPerform(Hero hero) {
    final game = hero.game;

    // Don't run into a wall.
    final ahead = hero.pos + direction;
    if (!game.level[ahead].isPassable) return false;

    // Whether or not the hero's left and right sides are open cannot change.
    // In other words, if he is running in a corridor (closed on both sides)
    // he will stop if he leaves the corridor (open on both sides). If he is
    // running along a wall on his left (closed on left, open on right), he
    // will stop if he enters an open room (open on both).
    if (!firstStep) {
      final leftSide = hero.pos + direction.rotateLeft90;
      final leftCorner = hero.pos + direction.rotateLeft45;
      if (game.level[leftSide].isPassable !=
          game.level[leftCorner].isPassable) return false;

      final rightSide = hero.pos + direction.rotateRight90;
      final rightCorner = hero.pos + direction.rotateRight45;
      if (game.level[rightSide].isPassable !=
          game.level[rightCorner].isPassable) return false;
    }

    // Don't run into someone.
    if (game.level.actorAt(ahead) != null) return false;

    // Don't run next to someone.
    if (game.level.actorAt(ahead + (direction.rotateLeft90)) != null) return false;
    if (game.level.actorAt(ahead + (direction.rotateLeft45)) != null) return false;
    if (game.level.actorAt(ahead + (direction)) != null) return false;
    if (game.level.actorAt(ahead + (direction.rotateRight45)) != null) return false;
    if (game.level.actorAt(ahead + (direction.rotateRight90)) != null) return false;

    // TODO(bob): This is still pretty simple. It won't run around corners in
    // corridors, which is probably good. (Running around a corner means either
    // taking a diagonal step which makes you step next to a tile you haven't
    // see, or going all the way through the corner which is a waste of a turn.)
    // It also currently won't stop for items.

    return true;
  }

  Action getAction(Hero hero) {
    firstStep = false;
    return new MoveAction(direction);
  }
}
