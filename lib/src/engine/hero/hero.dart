library hauberk.engine.hero.hero;

import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/walk.dart';
import '../actor.dart';
import '../attack.dart';
import '../element.dart';
import '../energy.dart';
import '../game.dart';
import '../items/equipment.dart';
import '../items/inventory.dart';
import '../log.dart';
import '../monster.dart';
import '../option.dart';
import 'hero_class.dart';

/// When the player is playing the game inside a dungeon, he is using a [Hero].
/// When outside of the dungeon on the menu screens, though, only a subset of
/// the hero's data persists (for example, there is no position when not in a
/// dungeon). This class stores that state.
class HeroSave {
  final String name;

  int get level => calculateLevel(experienceCents);

  HeroClass heroClass;

  Inventory inventory = new Inventory(Option.INVENTORY_CAPACITY);
  Equipment equipment = new Equipment();

  /// Items in the hero's home.
  Inventory home = new Inventory(Option.HOME_CAPACITY);

  /// Items in the hero's crucible.
  Inventory crucible = new Inventory(Option.CRUCIBLE_CAPACITY);

  int experienceCents = 0;

  /// The index of the highest [Level] that the [Hero] has completed in each
  /// [Area]. The key will be the [Area] name. The value will be the one-based
  /// index of the level. No key means the hero has not completed any levels in
  /// that area.
  final Map<String, int> completedLevels;

  HeroSave(this.name, this.heroClass)
      : completedLevels = <String, int>{};

  HeroSave.load(this.name, this.heroClass, this.inventory, this.equipment,
      this.home, this.crucible, this.experienceCents,
      this.completedLevels);

  /// Copies data from [hero] into this object. This should be called when the
  /// [Hero] has successfully completed a [Stage] and his changes need to be
  /// "saved".
  void copyFrom(Hero hero) {
    heroClass = hero.heroClass;
    inventory = hero.inventory;
    equipment = hero.equipment;
    experienceCents = hero._experienceCents;
  }
}

/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  String get nounText => 'you';
  final Pronoun pronoun = Pronoun.YOU;

  final HeroClass heroClass;

  final Inventory inventory;
  final Equipment equipment;

  /// Experience is stored internally as hundredths of a point for higher (but
  /// not floating point) precision.
  int _experienceCents = 0;

  /// The hero's experience level.
  int _level = 1;

  Behavior _behavior;

  /// How much "food" the hero has.
  ///
  /// The hero gains food by exploring the level and can spend it while resting
  /// to regain health.
  num food = 0.0;

  /// The hero's current "charge".
  ///
  /// This is interpreted and managed differently for each class: "fury" for
  /// warriors, "mana" for mages, etc.
  num charge = 0.0;

  /// How much noise the Hero's last action made.
  int get lastNoise => _lastNoise;
  int _lastNoise = 0;

  Hero(Game game, Vec pos, HeroSave save)
      : super(game, pos.x, pos.y, Option.HERO_HEALTH_START),
    // Cloned so that if the hero dies in the dungeon, he loses anything gained.
    heroClass = save.heroClass.clone(),
    inventory = save.inventory.clone(),
    equipment = save.equipment.clone(),
    _experienceCents = save.experienceCents {
    _refreshLevel(log: false);

    heroClass.bind(this);

    // Give the hero energy so we can act before all of the monsters.
    energy.energy = Energy.ACTION_COST;

    // Start with some initial ability to rest so we aren't weakest at the very
    // beginning.
    food = health.max;
  }

  // TODO: Hackish.
  get appearance => 'hero';

  bool get needsInput {
    if (_behavior != null && !_behavior.canPerform(this)) {
      waitForInput();
    }

    return _behavior == null;
  }

  int get experience => _experienceCents ~/ 100;

  int get level => _level;

  int get armor {
    int total = 0;
    for (final item in equipment) {
      total += item.armor;
    }

    total += heroClass.armor;

    return total;
  }

  /// Increases the hero's food by an appropriate amount after having explored
  /// [numExplored] additional tiles.
  void explore(int numExplored) {
    food += health.max * game.area.abundance *
            numExplored / game.stage.numExplorable;
  }

  int onGetSpeed() => Energy.NORMAL_SPEED;

  Action onGetAction() => _behavior.getAction(this);

  Attack onGetAttack(Actor defender) {
    var attack;

    // See if a melee weapon is equipped.
    final weapon = equipment.weapon;
    if (weapon != null && !weapon.isRanged) {
      attack = weapon.attack;
    } else {
      attack = new Attack('punch[es]', Option.HERO_PUNCH_DAMAGE, Element.NONE);
    }

    // Let the class modify it.
    return heroClass.modifyAttack(attack, defender);
  }

  Attack defend(Attack attack) {
    disturb();
    attack = super.defend(attack);
    return attack.addArmor(armor);
  }

  void onDamaged(Action action, Actor attacker, int damage) {
    heroClass.tookDamage(action, attacker, damage);
  }

  void onKilled(Action action, Monster defender) {
    _experienceCents += defender.experienceCents ~/ level;
    _refreshLevel(log: true);
    heroClass.killedMonster(action, defender);
  }

  void onDied(Actor attacker) {
    game.log.message("you were slain by {1}.", attacker);
  }

  void onFinishTurn(Action action) {
    // Make some noise.
    _lastNoise = action.noise;

    heroClass.finishedTurn(action);
  }

  void changePosition(Vec from, Vec to) {
    super.changePosition(from, to);
    game.stage.dirtyVisibility();
    game.quest.enterTile(game, game.stage[to]);
  }

  void waitForInput() {
    _behavior = null;
  }

  void setNextAction(Action action) {
    _behavior = new ActionBehavior(action);
  }

  /// Starts resting, if the hero has eaten and is able to regenerate.
  bool rest() {
    if (poison.isActive) {
      game.log.error(
          "You cannot rest while poison courses through your veins!");
      return false;
    }

    if (food == 0) {
      game.log.error("You must explore more before you can rest.");
      return false;
    }

    _behavior = new RestBehavior();
    return true;
  }

  void run(Direction direction) {
    _behavior = new RunBehavior(direction);
  }

  void disturb() {
    if (_behavior is! ActionBehavior) waitForInput();
  }

  void _refreshLevel({bool log: false}) {
    int level = calculateLevel(_experienceCents);

    // See if the we levelled up.
    while (_level < level) {
      _level++;
      health.max += Option.HERO_HEALTH_GAIN;
      health.current += Option.HERO_HEALTH_GAIN;

      if (log) {
        game.log.gain('{1} [have|has] reached level $level.', this);
      }
    }
  }
}

int calculateLevel(int experienceCents) {
  var experience = experienceCents ~/ 100;

  for (var level = 1; level <= Option.HERO_LEVEL_MAX; level++) {
    if (experience < calculateLevelCost(level)) return level - 1;
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
abstract class Behavior {
  bool canPerform(Hero hero);
  Action getAction(Hero hero);
}

/// A simple one-shot behavior that performs a given [Action] and then reverts
/// back to waiting for input.
class ActionBehavior extends Behavior {
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
class RestBehavior extends Behavior {
  bool canPerform(Hero hero) {
    // See if done resting.
    if (hero.health.isMax) return false;

    if (hero.food <= 0) {
      hero.game.log.message("You must explore more before you can rest.");
      return false;
    }

    return true;
  }

  Action getAction(Hero hero) => new RestAction();
}

/// Automatic running.
class RunBehavior extends Behavior {
  bool firstStep = true;

  /// Whether the hero is running with open tiles to their left.
  bool openLeft;

  /// Whether the hero is running with open tiles to their right.
  bool openRight;

  Direction direction;

  RunBehavior(this.direction);

  bool canPerform(Hero hero) {
    if (firstStep) {
      // On first step, always try to go in direction player pressed.
    } else if (openLeft == null) {
      // On the second step, figure out if we're in a corridor and which way
      // it's going. If the hero is running straight (NSEW), allow up to a 90°
      // turn. This covers cases like:
      //
      //     ####
      //     .@.#
      //     ##.#
      //
      // If the player presses right here, we want to take a first step, then
      // turn and run south. If the hero is running diagonally, we only allow
      // a 45° turn. That way it doesn't get confused by cases like:
      //
      //      #.#
      //     ##.##
      //     .@...
      //     #####
      //
      // If the player presses NE here, we want to run north and not get
      // confused by the east passage.
      var dirs = [direction.rotateLeft45,
        direction,
        direction.rotateRight45,
      ];

      if (Direction.CARDINAL.contains(direction)) {
        dirs.add(direction.rotateLeft90);
        dirs.add(direction.rotateRight90);
      }

      var openDirs = dirs.where((dir) => _isOpen(hero, dir));

      if (openDirs.isEmpty) return false;

      if (openDirs.length == 1) {
        // Entering a corridor.
        openLeft = false;
        openRight = false;

        // The direction may change if the first step entered a corridor from
        // around a corner.
        direction = openDirs.first;
      } else {
        // Entering an open area.
        openLeft = _isOpen(hero, direction.rotateLeft90);
        openRight = _isOpen(hero, direction.rotateRight90);
      }
    } else if (!openLeft && !openRight) {
      if (!_runInCorridor(hero)) return false;
    } else {
      if (!_runInOpen(hero)) return false;
    }

    return _shouldKeepRunning(hero);
  }

  Action getAction(Hero hero) {
    firstStep = false;
    return new WalkAction(direction);
  }

  /// Advance one step while in a corridor.
  ///
  /// The hero will follow curves and turns as long as there is only one
  /// direction they can go. (This is more or less true, though right-angle
  /// turns need special handling.)
  bool _runInCorridor(Hero hero) {
    // Keep running as long as there's only one direction to go. Allow up to a
    // 90° turn while running.
    var openDirs = [
      direction.rotateLeft90,
      direction.rotateLeft45,
      direction,
      direction.rotateRight45,
      direction.rotateRight90
    ].where((dir) => _isOpen(hero, dir)).toSet();

    if (openDirs.length == 1) {
      direction = openDirs.first;
      return true;
    }

    // Corner case, literally. If we're approaching a right-angle turn, keep
    // going. We'd normally stop here because there are two ways you can go,
    // straight into the corner of the turn (1) or diagonal to take a shortcut
    // around it (2):
    //
    //     ####
    //     #12.
    //     #@##
    //     #^#
    //
    // We detect this case by seeing if there are two (and only two) open
    // directions: ahead and 45° *and* if one step past that is blocked.
    if (openDirs.length != 2) return false;
    if (!openDirs.contains(direction)) return false;
    if (!openDirs.contains(direction.rotateLeft45) &&
        !openDirs.contains(direction.rotateRight45)) return false;

    var twoStepsAhead = hero.game.stage[hero.pos + direction * 2].isTraversable;
    if (twoStepsAhead) return false;

    // If we got here, we're in a corner. Keep going straight.
    return true;
  }

  bool _runInOpen(Hero hero) {
    var game = hero.game;

    // Whether or not the hero's left and right sides are open cannot change.
    // In other words, if he is running along a wall on his left (closed on
    // left, open on right), he will stop if he enters an open room (open on
    // both).
    var nextLeft = _isOpen(hero, direction.rotateLeft45);
    var nextRight = _isOpen(hero, direction.rotateRight45);
    return openLeft == nextLeft && openRight == nextRight;
  }

  /// Returns `true` if the hero can run one step in the current direction.
  ///
  /// Returns `false` if they should stop because they'd hit a wall or actor.
  bool _shouldKeepRunning(Hero hero) {
    var stage = hero.game.stage;
    var pos = hero.pos + direction;
    if (!stage[pos].isPassable) return false;

    // Don't run into someone.
    if (stage.actorAt(pos) != null) return false;

    // Don't run next to someone.
    if (stage.actorAt(pos + direction.rotateLeft90) != null) return false;
    if (stage.actorAt(pos + direction.rotateLeft45) != null) return false;
    if (stage.actorAt(pos + direction) != null) return false;
    if (stage.actorAt(pos + direction.rotateRight45) != null) return false;
    if (stage.actorAt(pos + direction.rotateRight90) != null) return false;

    return true;
  }

  bool _isOpen(Hero hero, Direction dir) =>
      hero.game.stage[hero.pos + dir].isTraversable;
}
