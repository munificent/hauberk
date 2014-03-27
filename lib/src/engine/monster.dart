library dngn.engine.monster;

import 'dart:math' as math;

import '../debug.dart';
import '../util.dart';
import 'a_star.dart';
import 'action_base.dart';
import 'actor.dart';
import 'breed.dart';
import 'energy.dart';
import 'game.dart';
import 'hero.dart';
import 'log.dart';
import 'los.dart';
import 'melee.dart';
import 'option.dart';

/*

monster has "mood", which describes how it's feeling:
- how afraid
- how bored
- other stuff?

those change over time based on stimulus:
- los with hero decreases boredom
- hearing hero decreases boredom
- no los with hero increases boredom
- seeing hero take damage decreases fear
- taking damage increases fear
- seeing hero inflict damage increases fear
- just seeing hero's health increases fear?
- being bored decreases fear

monster also has set of moves it can perform, and it can reason about them
in ai:
- knows which moves are ranged attacks
- knows element move uses for attack

mood and moves are then used to determine goal:
- melee attack hero
- sleep
- flee
- get in position for ranged attack
- use other move

when goal is attack:
- tries to find path to get to hero
- if has haste, will likely use it
- if can teleport to, will likely use it
- hits if adjacent

when goal is flee:
- tries to find path to nearest tile that is not visible to hero
- if has healing move may use it
- if has haste, may use it
- if can teleport away, will likely use it
- if cornered, attacks

when goal is get in position for ranged attack:
- tries to find path to nearest range position. good range position is:
  - not too far from hero
  - not too close
  - has open los to hero
- if in position, uses ranged move
- distance range is based on
  - strength of melee attacks
  - strength of ranged attacks
  - cost of ranged attacks
  - fear
  - recharge

other stuff:
- semi-intelligent monsters should learn hero resists by seeing which moves
  are ineffective
- intelligent monsters do same, but take into account moves *other* monsters
  do if they can see hero when it happens
- omniscient monsters just know hero's weaknesses
- all but stupidest monsters won't use move that applies condition currently
  in effect

- would be nice to have a state for assisting other monsters

 */

class Monster extends Actor {
  final Breed breed;

  _MonsterState _state;

  /// After performing a [Move] a monster must recharge to regain its cost.
  /// This is how much recharging is left to do before another move can be
  /// performed.
  int _recharge = 0;

  bool get isRecharged => _recharge == 0;

  void spendCharge(int cost) {
    _recharge += cost;
  }

  Monster(Game game, this.breed, int x, int y, int maxHealth)
      : super(game, x, y, maxHealth) {
    Debug.addMonster(this);
    _changeState(new _AsleepState());
  }

  get appearance => breed.appearance;

  String get nounText => 'the ${breed.name}';
  Pronoun get pronoun => breed.pronoun;

  /// How much experience a level one [Hero] gains for killing this monster.
  int get experienceCents => breed.experienceCents;

  /// Gets whether or not this monster has an uninterrupted line of sight to
  /// [target].
  bool canView(Vec target) {
    // Walk to the target.
    for (final step in new Los(pos, target)) {
      if (step == target) return true;
      if (!game.stage[step].isTransparent) return false;
    }

    throw 'unreachable';
  }

  bool get canOpenDoors => breed.flags.contains('open-doors');

  int onGetSpeed() => Energy.NORMAL_SPEED + breed.speed;

  Action onGetAction() {
    // Recharge moves.
    _recharge = math.max(0, _recharge - Option.RECHARGE_RATE);
    return _state.getAction();
  }

  void _changeState(_MonsterState state) {
    _state = state;
    _state.bind(this);
  }

  Attack getAttack(Actor defender) => rng.item(breed.attacks);

  void takeHit(Hit hit) {
    _state.takeHit();

    // TODO(bob): Nothing to do yet. Should eventually handle armor.
  }

  /// Called when this Actor has been killed by [attacker].
  void onDied(Actor attacker) {
    // Handle drops.
    breed.drop.spawnDrop(game, (item) {
      item.pos = pos;
      // TODO: Scatter items a bit?
      // TODO: Add message.
      game.stage.items.add(item);
    });

    // Tell the quest.
    game.quest.killMonster(game, this);

    Debug.removeMonster(this);
  }

  Vec changePosition(Vec pos) {
    // If the monster is (or was) visible, don't let the hero rest through it
    // moving.
    if (game.stage[this.pos].visible || game.stage[pos].visible) {
      game.hero.disturb();
    }

    return pos;
  }
}

abstract class _MonsterState {
  Monster _monster;

  void bind(Monster monster) {
    _monster = monster;
  }

  Monster get monster => _monster;
  Breed get breed => _monster.breed;
  Game get game => _monster.game;
  Vec get pos => _monster.pos;
  bool get isRecharged => _monster.isRecharged;
  bool get canOpenDoors => _monster.canOpenDoors;

  void takeHit() {}
  Action getAction();

  void changeState(_MonsterState state) {
    _monster._changeState(state);
  }

  Action getNextStateAction(_MonsterState state) {
    _monster._changeState(state);
    return state.getAction();
  }
}

class _AsleepState extends _MonsterState {
  void takeHit() {
    // Don't sleep through a beating!
    Debug.logMonster(monster, "Wake on hit.");
    changeState(new _AwakeState());
  }

  Action getAction() {
    var distance = (game.hero.pos - pos).kingLength;

    // Don't wake up it very far away.
    if (distance > 30) {
      Debug.logMonster(monster, "Sleep: Distance $distance is too far to see.");
      return new RestAction();
    }

    // If the monster can see the hero, there's a good chance it will wake up.
    if (game.stage[pos].visible) {
      // TODO: Breed-specific sight/alertness.
      if (rng.oneIn(distance + 1)) {
        game.log.message('{1} notice[s] {2}!', monster, game.hero);
        Debug.logMonster(monster, "Sleep: In LOS, awoke.");
        return getNextStateAction(new _AwakeState());
      }

      Debug.logMonster(monster,
          "Sleep: In LOS, failed oneIn(${distance + 1}).");
      return new RestAction();
    }

    if (distance > 20) {
      Debug.logMonster(monster,
          "Sleep: Distance $distance is too far to hear");
      return new RestAction();
    }

    // Otherwise, if sound can travel to it from the hero, it may wake up.
    // TODO: Breed-specific hearing.
    // Sound attenuates based on the inverse square of the distance.
    var flowDistance = game.stage.getHeroDistanceTo(pos);
    var noise = game.hero.lastNoise * 100 ~/ (flowDistance * flowDistance);

    if (noise > rng.range(500)) {
      game.log.message('Something stirs in the darkness.');
      Debug.logMonster(monster, "Sleep: Passed noise check, flow distance: "
          "$flowDistance, noise: $noise");
      return getNextStateAction(new _AwakeState());
    }

    // Keep sleeping.
    Debug.logMonster(monster, "Sleep: Failed noise check, flow distance: "
        "$flowDistance, noise: $noise");
    return new RestAction();
  }
}

class _AwakeState extends _MonsterState {
  /// How many turns the monster has taken while awake since it last saw the
  /// hero. If it goes too long, it will eventually get bored and fall back
  /// asleep.
  int _turnsSinceLastSawHero = 0;

  Action getAction() {
    // See if things are quiet enough to fall asleep.
    if (game.stage[pos].visible) {
      _turnsSinceLastSawHero = 0;
    } else {
      _turnsSinceLastSawHero++;

      // The longer it goes without seeing the hero the more likely it will
      // fall asleep.
      if (_turnsSinceLastSawHero > rng.range(10, 20)) {
        Debug.logMonster(monster,
            "Haven't seen hero in $_turnsSinceLastSawHero, sleeping");
        return getNextStateAction(new _AsleepState());
      }
    }

    // Consider all possible moves and select the best one.
    final choices = <AIChoice>[];

    final path = AStar.findDirection(game.stage, pos, game.hero.pos,
        10 - breed.meander, canOpenDoors);

    // Consider melee attacking.
    final toHero = game.hero.pos - pos;
    if (toHero.kingLength == 1) {
      // TODO(bob): Figure out what this score should be. It should generally
      // be pretty high. Most of the time a monster should prefer this over
      // walking, but may prefer other moves over this.
      var score = Option.AI_START_SCORE + 50;
      choices.add(new AIChoice(score, "melee",
          () => new WalkAction(toHero)));
    }

    // Consider each direction to walk in.
    for (var i = 0; i < Direction.ALL.length; i++) {
      var score = Option.AI_START_SCORE;
      final dest = pos + Direction.ALL[i];

      // If the direction is blocked, don't consider it.
      if (!game.stage[dest].isTraversable) continue;
      if (!canOpenDoors && !game.stage[dest].isPassable) continue;
      if (game.stage.actorAt(dest) != null) continue;

      // Apply pathfinding.
      if (Direction.ALL[i] == path) {
        score += Option.AI_WEIGHT_PATH_STRAIGHT;
      } else if (Direction.ALL[i].rotateLeft45 == path) {
        score += Option.AI_WEIGHT_PATH_NEAR;
      } else if (Direction.ALL[i].rotateRight45 == path) {
        score += Option.AI_WEIGHT_PATH_NEAR;
      }

      // Add some randomness to make the monster meander.
      score += rng.range(breed.meander * Option.AI_WEIGHT_MEANDER);

      choices.add(new AIChoice(score, "walk ${Direction.ALL[i]}",
          () => new WalkAction(Direction.ALL[i])));
    }

    // Consider the monster's moves if it can.
    if (isRecharged) {
      for (final move in breed.moves) {
        // TODO(bob): Should move cost affect its score?
        var score = Option.AI_START_SCORE + move.getScore(monster);
        if (score == Option.AI_MIN_SCORE) continue;
        choices.add(new AIChoice(score, move.toString(),
            () => move.getAction(monster)));
      }
    }

    // If the monster couldn't come up with anything to do, just sit.
    if (choices.length == 0) {
      Debug.logMonster(monster, "Nothing to do, resting.");
      return new RestAction();
    }

    // Pick the best choice.
    var bestScore = Option.AI_MIN_SCORE - 1;
    var bestChoices;
    for (var i = 0; i < choices.length; i++) {
      if (choices[i].score == bestScore) {
        // If multiple choices have the same score, we'll pick randomly
        // between them.
        bestChoices.add(choices[i]);
      } if (choices[i].score > bestScore) {
        bestScore = choices[i].score;
        bestChoices = [choices[i]];
      }
    }

    if (Debug.ENABLED) {
      choices.sort((a, b) => b.score.compareTo(a.score));
      var buffer = new StringBuffer();
      for (var choice in choices) {
        buffer.writeln(choice);
      }
      Debug.logMonster(monster, buffer.toString());
    }

    return rng.item(bestChoices).createAction();
  }
}

class AIChoice {
  final num score;
  final createAction;
  final description;

  AIChoice(this.score, this.description, this.createAction);

  String toString() => "$score - $description";
}

/*

  Action _getActionAfraid() {
    // TODO: Tune max distance?
    // Find the nearest place the hero can't see.
    var flow = new Flow(game.stage, pos, 10);
    var dir = flow.directionToNearestWhere((tile) => !tile.visible);
    Debug.logMonster(this, "Fleeing $dir");

    // TODO: Should not walk past hero to get to escape!
    // TODO: Should take into account distance from here when choosing an
    // escape destination.
    // TODO: What should it do once it's in shadow?
    return new WalkAction(dir);
  }

 */
