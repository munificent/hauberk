part of engine;

class Monster extends Actor {
  final Breed breed;

  MonsterState state = MonsterState.ASLEEP;

  /// The amount of noise that the monster has heard recently. Nearby actions
  /// will increase this and it naturally decays over time (as the monster
  /// "forgets" sounds). If it gets high enough, a sleeping monster will wake
  /// up.
  num noise = 0;

  /// After performing a [Move] a monster must recharge to regain its cost.
  /// This is how much recharging is left to do before another move can be
  /// performed.
  int recharge = 0;

  Monster(Game game, this.breed, int x, int y, int maxHealth)
  : super(game, x, y, maxHealth) {
    energy.speed = Energy.NORMAL_SPEED + breed.speed;
  }

  get appearance => breed.appearance;

  String get nounText => 'the ${breed.name}';
  int get person => 3;
  Gender get gender => breed.gender;

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

  Action onGetAction() {
    // Recharge moves.
    recharge = math.max(0, recharge - Option.RECHARGE_RATE);

    // Forget sounds over time. Since this occurs on the monster's turn, it
    // means slower monsters will attenuate less frequently. The [pow()]
    // part compensates for this.
    noise *= math.pow(Option.NOISE_FORGET, Energy.ticksAtSpeed(breed.speed));

    switch (state) {
      case MonsterState.ASLEEP: return getActionAsleep();
      case MonsterState.AWAKE: return getActionAwake();
    }

    throw "unreachable";
  }

  Action getActionAsleep() {
    // See if there is enough noise to wake up.
    // TODO(bob): Add breed-specific modifier.
    if (noise > rng.range(50, 5000)) {
      state = MonsterState.AWAKE;
      game.log.message('{1} wake[s] up!', this);

      // Bump up the noise. This ensures the monsters is alert and stays awake
      // for a while.
      noise += 400;

      // Even though the monster is awake now, rest this turn. This avoids an
      // annoying behavior where a sleeping monster will almost always wake up
      // right when the hero walks next to it.
    }

    // TODO(bob): Take LOS into account too.

    // Keep sleeping.
    return new RestAction();
  }

  Action getActionAwake() {
    // See if things are quiet enough to fall asleep.
    if ((noise < rng.range(0,25)) && !canView(game.hero.pos)) {
      state = MonsterState.ASLEEP;
      game.log.message('{1} fall[s] asleep!', this);

      // Reset the noise. This ensures the monster stays asleep for a while.
      noise = 0;
      return getActionAsleep();
    }

    // Consider all possible moves and select the best one.
    final choices = <AIChoice>[];

    // The minimum scent required for the monster to notice it. Smaller numbers
    // mean a stronger sense of smell.
    final minScent = math.pow(0.5, breed.olfaction);

    // How much the monster listens to their sense of smell. The more sensitive
    // it is, the more the monster relies on it.
    // TODO(bob): Add a tuned multiplier here.
    final scentWeight = breed.olfaction * Option.AI_WEIGHT_SCENT;

    getScent(Vec pos) {
      return math.max(game.stage.getScent(pos.x, pos.y) - minScent, 0);
    }

    final scent = getScent(pos);

    // TODO(bob): Make maximum path-length be breed tunable.
    final path = AStar.findDirection(game.stage, pos, game.hero.pos, 10,
        canOpenDoors);

    // Consider melee attacking.
    final toHero = game.hero.pos - pos;
    if (toHero.kingLength == 1) {
      // TODO(bob): Figure out what this score should be. It should generally
      // be pretty high. Most of the time a monster should prefer this over
      // walking, but may prefer other moves over this.
      var score = Option.AI_START_SCORE + 50;
      choices.add(new AIChoice(score, () => new WalkAction(toHero)));
    }

    // Consider each direction to walk in.
    for (var i = 0; i < Direction.ALL.length; i++) {
      var score = Option.AI_START_SCORE;
      final dest = pos + Direction.ALL[i];

      // If the direction is blocked, don't consider it.
      if (!game.stage[dest].isTraversable) continue;
      if (!canOpenDoors && !game.stage[dest].isPassable) continue;
      if (game.stage.actorAt(dest) != null) continue;

      // Apply scent knowledge.
      final scentGradient = getScent(dest) - scent;
      score += scentGradient * scentWeight;

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

      choices.add(new AIChoice(score, () => new WalkAction(Direction.ALL[i])));
    }

    // Consider the monster's moves if it can.
    if (recharge == 0) {
      for (final move in breed.moves) {
        // TODO(bob): Should move cost affect its score?
        var score = Option.AI_START_SCORE + move.getScore(this);
        if (score == Option.AI_MIN_SCORE) continue;
        choices.add(new AIChoice(score, () => move.getAction(this)));
      }
    }

    // If the monster couldn't come up with anything to do, just sit.
    if (choices.length == 0) return new WalkAction(new Vec(0, 0));

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
    breed.drop.spawnDrop(game, (Item item) {
      item.pos = pos;
      // TODO(bob): Scatter items a bit?
      // TODO(bob): Add message.
      game.stage.items.add(item);
    });

    // Tell the quest.
    game.quest.killMonster(game, this);
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

  AIChoice(this.score, this.createAction);
}

/// A [Monster]'s internal mental state.
class MonsterState {
  static const ASLEEP = const MonsterState(0);
  static const AWAKE  = const MonsterState(1);

  final int _value;
  const MonsterState(this._value);
}

/// A single kind of [Monster] in the game.
class Breed {
  final Gender gender;
  final String name;

  /// Untyped so the engine isn't coupled to how monsters appear.
  final appearance;

  final List<Attack> attacks;
  final List<Move>   moves;

  final int maxHealth;

  /// How good the monster's sense of smell is. Ranges from 0 to 10 where 0 is
  /// no sense of smell and 10 means the monster navigates almost solely using
  /// it.
  final num olfaction;

  /// How much randomness the monster has when walking towards its target.
  final int meander;

  /// The breed's speed, relative to normal. Ranges from `-6` (slowest) to `6`
  /// (fastest) where `0` is normal speed.
  final int speed;

  /// The [Item]s this monster may drop when killed.
  final Drop drop;

  final Set<String> flags;

  Breed(this.name, this.gender, this.appearance, this.attacks, this.moves,
      this.drop, {
      this.maxHealth, this.olfaction, this.meander, this.speed, this.flags});

  /// How much experience a level one [Hero] gains for killing a [Monster] of
  /// this breed.
  int get experienceCents {
    // The more health it has, the longer it can hurt the hero.
    num exp = maxHealth;

    // Faster monsters are worth more.
    exp *= Energy.GAINS[Energy.NORMAL_SPEED + speed];

    // Average the attacks (since they are selected randomly) and factor them
    // in.
    var attackTotal = 0;
    for (final attack in attacks) {
      attackTotal += attack.damage;
    }
    exp *= attackTotal / attacks.length;

    // Take into account flags.
    for (final flag in flags) {
      exp *= Option.EXP_FLAG[flag];
    }

    // Meandering monsters are worth less.
    exp *= (Option.EXP_MEANDER - meander) / Option.EXP_MEANDER;

    // TODO(bob): Take into account moves and olfaction.
    return exp.toInt();
  }

  /// When a [Monster] of this Breed is generated, how many of the same type
  /// should be spawned together (roughly).
  int get numberInGroup {
    if (flags.contains('horde')) return 18;
    if (flags.contains('swarm')) return 12;
    if (flags.contains('pack')) return 8;
    if (flags.contains('group')) return 4;
    if (flags.contains('few')) return 2;
    return 1;
  }

  Monster spawn(Game game, Vec pos) {
    return new Monster(game, this, pos.x, pos.y, maxHealth);
  }
}
