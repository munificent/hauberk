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

class Monster extends Actor {
  final Breed breed;

  MonsterState state = MonsterState.ASLEEP;

  /// After performing a [Move] a monster must recharge to regain its cost.
  /// This is how much recharging is left to do before another move can be
  /// performed.
  int recharge = 0;

  /// How many turns the monster has taken while awake since it last saw the
  /// hero. If it goes too long, it will eventually get bored and fall back
  /// asleep.
  int _turnsSinceLastSawHero = 0;

  Monster(Game game, this.breed, int x, int y, int maxHealth)
      : super(game, x, y, maxHealth) {
    Debug.addMonster(this);
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
    recharge = math.max(0, recharge - Option.RECHARGE_RATE);

    switch (state) {
      case MonsterState.ASLEEP: return _getActionAsleep();
      case MonsterState.AWAKE: return _getActionAwake();
    }

    throw "unreachable";
  }

  Action _getActionAsleep() {
    var distance = (game.hero.pos - pos).kingLength;

    // Don't wake up it very far away.
    if (distance > 30) {
      Debug.logMonster(this, "Sleep: Distance $distance is too far to see.");
      return new RestAction();
    }

    // If the monster can see the hero, there's a good chance it will wake up.
    if (canView(game.hero.pos)) {
      // TODO: Breed-specific sight/alertness.
      if (rng.oneIn(distance + 1)) {
        _turnsSinceLastSawHero = 0;
        state = MonsterState.AWAKE;
        game.log.message('{1} notice[s] {2}!', this, game.hero);
        Debug.logMonster(this, "Sleep: In LOS, awoke.");
        return _getActionAwake();
      }

      Debug.logMonster(this, "Sleep: In LOS, failed oneIn(${distance + 1}).");
      return new RestAction();
    }

    if (distance > 20) {
      Debug.logMonster(this, "Sleep: Distance $distance is too far to hear");
      return new RestAction();
    }

    // Otherwise, if sound can travel to it from the hero, it may wake up.
    // TODO: Breed-specific hearing.
    // Sound attenuates based on the inverse square of the distance.
    var flowDistance = game.stage.getHeroDistanceTo(pos);
    var noise = game.hero.lastNoise * 100 ~/ (flowDistance * flowDistance);

    if (noise > rng.range(500)) {
      _turnsSinceLastSawHero = 0;
      state = MonsterState.AWAKE;
      game.log.message('Something stirs in the darkness.');
      Debug.logMonster(this, "Sleep: Passed noise check, flow distance: "
          "$flowDistance, noise: $noise");
      return _getActionAwake();
    }

    // Keep sleeping.
    Debug.logMonster(this, "Sleep: Failed noise check, flow distance: "
        "$flowDistance, noise: $noise");
    return new RestAction();
  }

  Action _getActionAwake() {
    // See if things are quiet enough to fall asleep.
    if (canView(game.hero.pos)) {
      _turnsSinceLastSawHero = 0;
    } else {
      _turnsSinceLastSawHero++;

      // The longer it goes without seeing the hero the more likely it will
      // fall asleep.
      if (_turnsSinceLastSawHero > rng.range(10, 20)) {
        Debug.logMonster(this,
            "Haven't seen hero in $_turnsSinceLastSawHero, sleeping");
        state = MonsterState.ASLEEP;
        return _getActionAsleep();
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
    if (recharge == 0) {
      for (final move in breed.moves) {
        // TODO(bob): Should move cost affect its score?
        var score = Option.AI_START_SCORE + move.getScore(this);
        if (score == Option.AI_MIN_SCORE) continue;
        choices.add(new AIChoice(score, move.toString(),
            () => move.getAction(this)));
      }
    }

    // If the monster couldn't come up with anything to do, just sit.
    if (choices.length == 0) {
      Debug.logMonster(this, "Nothing to do, resting.");
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
      Debug.logMonster(this, buffer.toString());
    }

    return rng.item(bestChoices).createAction();
  }

  Attack getAttack(Actor defender) => rng.item(breed.attacks);

  void takeHit(Hit hit) {
    if (state == MonsterState.ASLEEP) {
      // Can't sleep through a beating!
      state = MonsterState.AWAKE;
    }
    // TODO(bob): Nothing to do yet. Should eventually handle armor.
  }

  /// Called when this Actor has been killed by [attacker].
  void onDied(Actor attacker) {
    // Handle drops.
    breed.drop.spawnDrop(game, (item) {
      item.pos = pos;
      // TODO(bob): Scatter items a bit?
      // TODO(bob): Add message.
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

class AIChoice {
  final num score;
  final createAction;
  final description;

  AIChoice(this.score, this.description, this.createAction);

  String toString() => "$score - $description";
}

/// A [Monster]'s internal mental state.
class MonsterState {
  static const ASLEEP = const MonsterState(0);
  static const AWAKE  = const MonsterState(1);

  final int _value;
  const MonsterState(this._value);
}
