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

  bool get needsInput() => _behavior == null;

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
    game.dirtyVisibility();
    game.level.dirtyPathfinding();
    return pos;
  }

  void regenerate() {
    // The hero can only rest if not hungry.
    if (hunger < Option.HUNGER_MAX) {
      hunger++;
      super.regenerate();

      if (health.isMax && (_behavior is RestBehavior)) {
        waitForInput();
      }
    } else {
      if (_behavior is RestBehavior) {
        waitForInput();
        game.log.add('{1} [are|is] too hungry to rest.', this);
      }
    }
  }

  void waitForInput() {
    _behavior = null;
  }

  void setNextAction(Action action) {
    if (action == null) {
      _behavior = null;
    } else {
      _behavior = new ActionBehavior(action);
    }
  }

  void rest() {
    _behavior = new RestBehavior();
  }

  void disturb() {
    if (_behavior is! ActionBehavior) waitForInput();
  }

  String get nounText() => 'you';
  int get person() => 2;
}

interface Behavior {
  Action getAction(Hero hero);
}

class ActionBehavior implements Behavior {
  final Action action;

  ActionBehavior(this.action);

  Action getAction(Hero hero) {
    hero.waitForInput();
    return action;
  }
}

class RestBehavior implements Behavior {
  Action getAction(Hero hero) => new RestAction();
}
