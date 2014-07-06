library dngn.engine.hero.hero;

import '../../util.dart';
import '../action_base.dart';
import '../actor.dart';
import '../element.dart';
import '../energy.dart';
import '../game.dart';
import '../item.dart';
import '../log.dart';
import '../melee.dart';
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
    health.current = health.max;
  }

  // TODO: Hackish.
  get appearance => 'hero';

  bool get needsInput {
    if ((_behavior != null) && !_behavior.canPerform(this)) {
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

  int onGetSpeed() => Energy.NORMAL_SPEED;

  Action onGetAction() => _behavior.getAction(this);

  Attack getAttack(Actor defender) {
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

  void onFinishTurn(Action action) {
    // Make some noise.
    _lastNoise = action.noise;
  }

  Vec changePosition(Vec pos) {
    game.stage.dirtyVisibility();
    game.quest.enterTile(game, game.stage[pos]);
    return pos;
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

    if (!food.isActive) {
      game.log.error("You are too hungry to rest!");
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

    if (!hero.food.isActive) {
      hero.game.log.message("You are getting hungry.");
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
class RunBehavior extends Behavior {
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
    // seen, or going all the way through the corner which is a waste of a
    // turn.) It also currently won't stop for items.

    return true;
  }

  Action getAction(Hero hero) {
    firstStep = false;
    return new WalkAction(direction);
  }
}
