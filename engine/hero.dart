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

  final SkillSet skills;

  int experienceCents = 0;

  /// The index of the highest [Level] that the [Hero] has completed in each
  /// [Area]. The key will be the [Area] name. The value will be the one-based
  /// index of the level. No key means the hero has not completed any levels in
  /// that area.
  final Map<String, int> completedLevels;

  HeroSave(Map<String, Skill> skills)
      : inventory = new Inventory(Option.INVENTORY_CAPACITY),
        equipment = new Equipment(),
        home = new Inventory(Option.HOME_CAPACITY),
        crucible = new Inventory(Option.CRUCIBLE_CAPACITY),
        skills = new SkillSet(skills),
        completedLevels = <String, int>{};

  HeroSave.load(this.inventory, this.equipment, this.home, this.crucible,
      this.skills, this.experienceCents, this.completedLevels);

  /// Copies data from [hero] into this object. This should be called when the
  /// [Hero] has successfully completed a [Stage] and his changes need to be
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

  final SkillSet skills;

  /// Experience is stored internally as hundredths of a point for higher (but
  /// not floating point) precision.
  int _experienceCents = 0;

  /// The hero's experience level.
  int _level = 1;

  Behavior _behavior;

  int _focus = Option.FOCUS_MAX;

  Hero(Game game, Vec pos, HeroSave save, this.skills)
  : super(game, pos.x, pos.y, Option.HERO_HEALTH_START),
    // Cloned so that if the hero dies in the dungeon, he loses any items
    // he gained.
    inventory = save.inventory.clone(),
    equipment = save.equipment.clone(),
    _experienceCents = save.experienceCents {
    _refreshLevel(log: false);

    // TODO(bob): Doing this here assumes skills don't change while in the
    // stage.
    skills.forEach((skill, level) => health.max += skill.modifyHealth(level));
    health.current = health.max;
  }

  // TODO(bob): Hackish.
  get appearance => 'hero';

  bool get needsInput() {
    if ((_behavior != null) && !_behavior.canPerform(this)) {
      waitForInput();
    }

    return _behavior == null;
  }

  int get experience => _experienceCents ~/ 100;

  int get level => _level;

  int get focus => _focus;

  int get armor {
    int total = 0;
    for (final item in equipment) {
      total += item.armor;
    }
    return total;
  }

  Action onGetAction() => _behavior.getAction(this);

  Attack getAttack(Actor defender) {
    var attack;

    // See if a weapon is equipped.
    final weapon = equipment.find('Weapon');
    if (weapon != null) {
      attack = weapon.attack;
    } else {
      attack = new Attack('punch[es]', Option.HERO_PUNCH_DAMAGE, Element.NONE);
    }

    // See if any skills modify it.
    var add = 0;
    var multiply = 1.0;
    skills.forEach((skill, level) {
      add += skill.getAttackAddBonus(level, weapon, attack);
      multiply += skill.getAttackMultiplyBonus(level, weapon, attack);
    });

    attack = new Attack(attack.verb, ((attack.damage + add) * multiply).toInt(),
        attack.element, attack.noun);

    return attack;
  }

  void takeHit(Hit hit) {
    disturb();

    hit.armor = armor;
  }

  void onKilled(Monster defender) {
    _experienceCents += defender.experienceCents ~/ level;
    _refreshLevel(log: true);
  }

  void onFinishTurn(Action action) {
    // Spend and regain focus.
    _focus = clamp(0, _focus + action.focusOffset, Option.FOCUS_MAX);
  }

  Vec changePosition(Vec pos) {
    game.stage.dirtyVisibility();
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
    int level = calculateLevel(_experienceCents);

    // See if the we levelled up.
    while (_level < level) {
      _level++;
      health.max += Option.HERO_HEALTH_GAIN;
      health.current += Option.HERO_HEALTH_GAIN;

      if (log) {
        game.log.add('{1} [have|has] reached level $level.', this);
      }
    }
  }

  String get nounText() => 'you';
  int get person() => 2;
}

int calculateLevel(int experienceCents) {
  var experience = experienceCents ~/ 100;

  for (var level = 1; level <= Option.HERO_LEVEL_MAX; level++) {
    final levelCost = (level - 1) * (level - 1) * Option.HERO_LEVEL_COST;
    if (experience < levelCost) return level;
  }

  return Option.HERO_LEVEL_MAX;
}

/// Returns how much experience is needed to reach [level] or `null` if [level]
/// is greater than the maximum level.
int calculateLevelCost(int level) {
  if (level > Option.HERO_LEVEL_MAX) return null;
 return (level - 1) * (level - 1) * Option.HERO_LEVEL_COST;
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
    if (!game.stage[ahead].isPassable) return false;

    // Whether or not the hero's left and right sides are open cannot change.
    // In other words, if he is running in a corridor (closed on both sides)
    // he will stop if he leaves the corridor (open on both sides). If he is
    // running along a wall on his left (closed on left, open on right), he
    // will stop if he enters an open room (open on both).
    if (!firstStep) {
      final leftSide = hero.pos + direction.rotateLeft90;
      final leftCorner = hero.pos + direction.rotateLeft45;
      if (game.stage[leftSide].isPassable !=
          game.stage[leftCorner].isPassable) return false;

      final rightSide = hero.pos + direction.rotateRight90;
      final rightCorner = hero.pos + direction.rotateRight45;
      if (game.stage[rightSide].isPassable !=
          game.stage[rightCorner].isPassable) return false;
    }

    // Don't run into someone.
    if (game.stage.actorAt(ahead) != null) return false;

    // Don't run next to someone.
    if (game.stage.actorAt(ahead + (direction.rotateLeft90)) != null) return false;
    if (game.stage.actorAt(ahead + (direction.rotateLeft45)) != null) return false;
    if (game.stage.actorAt(ahead + (direction)) != null) return false;
    if (game.stage.actorAt(ahead + (direction.rotateRight45)) != null) return false;
    if (game.stage.actorAt(ahead + (direction.rotateRight90)) != null) return false;

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
