import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/walk.dart';
import '../core/actor.dart';
import '../core/combat.dart';
import '../core/element.dart';
import '../core/energy.dart';
import '../core/game.dart';
import '../core/log.dart';
import '../core/option.dart';
import '../core/stage.dart';
import '../hero/skill.dart';
import '../items/equipment.dart';
import '../items/inventory.dart';
import '../monster/monster.dart';

/// When the player is playing the game inside a dungeon, he is using a [Hero].
/// When outside of the dungeon on the menu screens, though, only a subset of
/// the hero's data persists (for example, there is no position when not in a
/// dungeon). This class stores that state.
class HeroSave {
  final String name;

  int get level => calculateLevel(experienceCents);

  Inventory inventory = new Inventory(Option.inventoryCapacity);
  Equipment equipment = new Equipment();

  /// Items in the hero's home.
  Inventory home = new Inventory(Option.homeCapacity);

  /// Items in the hero's crucible.
  Inventory crucible = new Inventory(Option.crucibleCapacity);

  int experienceCents = 0;

  SkillSet skills;

  /// Available points that can be spent raising skills.
  int skillPoints = 12;

  // TODO: Get rid of gold and shops if I'm sure we won't be using it.
  /// How much gold the hero has.
  int gold = Option.heroGoldStart;

  /// The lowest depth that the hero has successfully explored and exited.
  int maxDepth = 0;

  HeroSave(this.name) : skills = new SkillSet();

  HeroSave.load(
      this.name,
      this.inventory,
      this.equipment,
      this.home,
      this.crucible,
      this.experienceCents,
      this.skillPoints,
      this.skills,
      this.gold,
      this.maxDepth);

  /// Copies data from [hero] into this object. This should be called when the
  /// [Hero] has successfully completed a [Stage] and his changes need to be
  /// "saved".
  void copyFrom(Hero hero) {
    inventory = hero.inventory;
    equipment = hero.equipment;
    experienceCents = hero._experienceCents;
    skillPoints = hero.skillPoints;
    gold = hero.gold;
    skills = hero.skills.clone();
  }
}

/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  String get nounText => 'you';
  final Pronoun pronoun = Pronoun.you;

  final Inventory inventory;
  final Equipment equipment;

  /// Experience is stored internally as hundredths of a point for higher (but
  /// not floating point) precision.
  int _experienceCents = 0;

  int get strength => _attribute(Skill.strength, -weight);
  int get agility => _attribute(Skill.agility);
  int get fortitude => _attribute(Skill.fortitude);
  int get intellect => _attribute(Skill.intellect);
  int get will => _attribute(Skill.will);

  int _attribute(Skill skill, [int bonus = 0]) =>
      (10 + skills[skill] + bonus).clamp(1, 60);

  final SkillSet skills;

  /// Available points that can be spent raising skills.
  int skillPoints;

  /// The hero's experience level.
  int _level = 1;

  int gold;

  Behavior _behavior;

  /// How much "food" the hero has.
  ///
  /// The hero gains food by exploring the level and can spend it while resting
  /// to regain health.
  double food = 0.0;

  /// The hero's current "charge".
  ///
  /// This is interpreted and managed differently for each class: "fury" for
  /// warriors, "mana" for mages, etc.
  double charge = 0.0;

  int _focus = 400;
  int get focus => _focus;
  set focus(int value) => _focus = value.clamp(0, Option.maxFocus);

  /// How much noise the Hero's last action made.
  int get lastNoise => _lastNoise;
  int _lastNoise = 0;

  // TODO: Equipment and items that let the hero swim, fly, etc.
  MotilitySet get motilities => MotilitySet.walkAndDoor;

  Hero(Game game, Vec pos, HeroSave save)
      : inventory = save.inventory.clone(),
        equipment = save.equipment.clone(),
        _experienceCents = save.experienceCents,
        skillPoints = save.skillPoints,
        skills = save.skills.clone(),
        gold = save.gold,
        super(game, pos.x, pos.y, 0) {
    // Hero state is cloned above so that if they die in the dungeon, they lose
    // anything they found.

    health.max = Fortitude.maxHealth(fortitude);
    health.current = health.max;

    _refreshLevel(gain: false);

    // Give the hero energy so we can act before all of the monsters.
    energy.energy = Energy.actionCost;

    // Start with some initial ability to rest so we aren't weakest at the very
    // beginning.
    food = health.max.toDouble();
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
    var total = 0;
    for (var item in equipment) {
      total += item.armor;
    }

    // TODO: Apply skills.
//    total += heroClass.armor;

    return total;
  }

  // TODO: If this changes or the equipped weapon changes, should check to see
  // if weapon has too much weight for player and log.
  /// The total weight of all equipment.
  int get weight {
    var total = 0;
    for (var item in equipment) {
      total += item.weight;
    }

    return total;
  }

  /// Gets the total permament resistance provided by all equipment.
  int equipmentResistance(Element element) {
    // TODO: If class or race can affect this, add it in.
    var resistance = 0;

    for (var item in equipment) {
      resistance += item.resistance(element);
    }

    // TODO: Unify this with onDefend().

    return resistance;
  }

  /// Increases the hero's food by an appropriate amount after having explored
  /// [numExplored] additional tiles.
  void explore(int numExplored) {
    // TODO: Tune abundance by depth, with some randomness?
    const abundance = 12.0;
    food += health.max * abundance * numExplored / game.stage.numExplorable;
  }

  /// Updates the hero's skill levels to [skills] and apply any other changes
  /// caused by that.
  void updateSkills(SkillSet skills) {
    var oldFortitude = fortitude;

    // Update anything affected.
    this.skills.update(skills);

    if (fortitude != oldFortitude) {
      // Update max health.
      var change = Fortitude.maxHealth(fortitude) - health.max;
      health.max = Fortitude.maxHealth(fortitude);

      if (change > 0) {
        game.log.message("you feel healthier!");

        // Increase the current health by a matching amount if it goes up.
        health.current += change;
      } else {
        game.log.message("you feel less healthy.");
      }
    }
  }

  int onGetSpeed() => Energy.normalSpeed;

  int onGetDodge() => 20 + Agility.dodgeBonus(agility);

  // TODO: Shields, temporary bonuses, etc.
  Iterable<Defense> onGetDefenses() sync* {
    for (var skill in skills.all) {
      var defense = skill.getDefense(this, skills[skill]);
      if (defense != null) yield defense;
    }
  }

  Action onGetAction() => _behavior.getAction(this);

  Hit onCreateMeleeHit() {
    // See if a melee weapon is equipped.
    var weapon = equipment.weapon;

    Hit hit;
    if (weapon != null && !weapon.attack.isRanged) {
      hit = weapon.attack.createHit();

      // Take heft and strength into account.
      var relativeStrength = strength - weapon.heft;
      var scale = Strength.scaleHeft(relativeStrength);
      hit.scaleDamage(scale);
    } else {
      hit = new Attack(this, 'punch[es]', Option.heroPunchDamage).createHit();
    }

    hit.addStrike(Agility.strikeBonus(agility));

    for (var skill in skills.all) {
      skill.modifyAttack(this, hit, skills[skill]);
    }

    return hit;
  }

  Hit createRangedHit() {
    var weapon = equipment.weapon;

    // TODO: Figure out how heft affects this.

    // This should only be called when we know the hero has a ranged weapon
    // equipped.
    assert(weapon != null && weapon.attack.isRanged);

    var hit = weapon.attack.createHit();
    modifyHit(hit, HitType.ranged);
    return hit;
  }

  /// Applies the hero-specific modifications to [hit].
  void onModifyHit(Hit hit, HitType type) {
    // TODO: Use agility to affect strike.

    switch (type) {
      case HitType.melee:
        break;

      case HitType.ranged:
        // TODO: Use strength to affect range.
        // TODO: Take heft into account.
        break;

      case HitType.toss:
        hit.scaleRange(Strength.tossRangeScale(strength));
        break;
    }

    // Let equipment modify it.
    for (var item in equipment) {
      item.modifyHit(hit);
    }

    // TODO: Apply skills.
    // Let the class modify it.
//    heroClass.modifyHit(hit);
  }

  void defend() {
    disturb();
  }

  // TODO: If class or race can affect this, add it in.
  int onGetResistance(Element element) => equipmentResistance(element);

  void onDamaged(Action action, Actor attacker, int damage) {
    // Getting hit loses focus.
    focus -= Option.maxFocus * damage * 2 ~/ health.max;
  }

  void onKilled(Action action, Actor defender) {
    var monster = defender as Monster;
    _experienceCents += monster.experienceCents;
    _refreshLevel(gain: true);
  }

  void onDied(Noun attackNoun) {
    game.log.message("you were slain by {1}.", attackNoun);
  }

  void onFinishTurn(Action action) {
    // Make some noise.
    _lastNoise = action.noise;

    // TODO: Passive skills?
//    heroClass.finishedTurn(action);
  }

  void changePosition(Vec from, Vec to) {
    super.changePosition(from, to);
    game.stage.dirtyVisibility();
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
      game.log
          .error("You cannot rest while poison courses through your veins!");
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

  void _refreshLevel({bool gain: false}) {
    int level = calculateLevel(_experienceCents);

    // See if the we levelled up.
    while (_level < level) {
      _level++;

      if (gain) {
        game.log.gain('{1} [have|has] reached level $level.', this);

        skillPoints += Option.skillPointsPerLevel;
      }
    }
  }
}

int calculateLevel(int experienceCents) {
  var experience = experienceCents ~/ 100;

  for (var level = 1; level <= Option.heroLevelMax; level++) {
    if (experience < calculateLevelCost(level)) return level - 1;
  }

  return Option.heroLevelMax;
}

/// Returns how much experience is needed to reach [level] or `null` if [level]
/// is greater than the maximum level.
int calculateLevelCost(int level) {
  if (level > Option.heroLevelMax) return null;
  return (level - 1) * (level - 1) * Option.heroLevelCost;
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
      var dirs = [
        direction.rotateLeft45,
        direction,
        direction.rotateRight45,
      ];

      if (Direction.cardinal.contains(direction)) {
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
    return new WalkAction(direction, running: true);
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
    if (!stage[pos].isWalkable) return false;

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
