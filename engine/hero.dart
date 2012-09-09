/// When the player is playing the game inside a dungeon, he is using a [Hero].
/// When outside of the dungeon on the menu screens, though, only a subset of
/// the hero's data persists (for example, there is no position when not in a
/// dungeon). This class stores that state.
class HeroSave {
  Inventory inventory;
  Equipment equipment;

  /// Items in the hero's home.
  Inventory home;

  /// Items in the hero's crucible.
  Inventory crucible;

  int experienceCents = 0;

  HeroSave()
  : inventory = new Inventory(Option.INVENTORY_CAPACITY),
    equipment = new Equipment(),
    home = new Inventory(Option.HOME_CAPACITY),
    crucible = new Inventory(Option.CRUCIBLE_CAPACITY);

  HeroSave.load(this.inventory, this.equipment, this.home, this.crucible,
      this.experienceCents);

  /// Copies data from [hero] into this object. This should be called when the
  /// [Hero] has successfully completed a [Level] and his changes need to be
  /// "saved".
  void copyFrom(Hero hero) {
    inventory = hero.inventory;
    equipment = hero.equipment;
    experienceCents = hero._experienceCents;
  }
}

/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  // TODO(bob): Let user specify.
  final Gender gender = Gender.MALE;

  final Inventory inventory;
  final Equipment equipment;

  /// Experience is stored internally as hundredths of a point for higher (but
  /// not floating point) precision.
  int _experienceCents = 0;

  /// The hero's experience level.
  int _level = 1;

  Behavior _behavior;

  Hero(Game game, Vec pos, HeroSave save)
  : super(game, pos.x, pos.y, Option.HERO_HEALTH_START),
    // Cloned so that if the hero dies in the dungeon, he loses any items
    // he gained.
    inventory = save.inventory.clone(),
    equipment = save.equipment.clone(),
    _experienceCents = save.experienceCents {
    _refreshLevel(log: false);
  }

  // TODO(bob): Hackish.
  get appearance() => 'hero';

  bool get needsInput() {
    if ((_behavior != null) && !_behavior.canPerform(this)) {
      waitForInput();
    }

    return _behavior == null;
  }

  int get experience() => _experienceCents ~/ 100;

  int get level() => _level;

  int get armor() {
    int total = 0;
    for (final item in equipment) {
      total += item.armor;
    }
    return total;
  }

  Action onGetAction() => _behavior.getAction(this);

  Attack getAttack(Actor defender) {
    // See if a weapon is equipped.
    final weapon = equipment.find('Weapon');
    if (weapon != null) return weapon.attack;

    // TODO(bob): Temp.
    return new Attack('punch[es]', Option.HERO_PUNCH_DAMAGE, Element.NONE);
  }

  void takeHit(Hit hit) {
    disturb();

    hit.armor = armor;
  }

  void onKilled(Monster defender) {
    _experienceCents += defender.experienceCents ~/ level;
    _refreshLevel(log: true);
  }

  Vec changePosition(Vec pos) {
    game.level.dirtyVisibility();
    return pos;
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

  void _refreshLevel([bool log = false]) {
    // See if the we levelled up.
    for (var level = 1; level <= Option.HERO_LEVEL_MAX; level++) {
      final levelCost = (level - 1) * (level - 1) * Option.HERO_LEVEL_COST;

      if (experience < levelCost) break;

      if (_level < level) {
        _level++;
        health.max += Option.HERO_HEALTH_GAIN;
        health.current += Option.HERO_HEALTH_GAIN;

        if (log) {
          game.log.add('{1} [have|has] reached level $level.', this);
        }
      }
    }
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
    return new WalkAction(direction);
  }
}
