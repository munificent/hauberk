
class Monster extends Actor {
  final Breed breed;

  MonsterState state = MonsterState.ASLEEP;

  /// The amount of noise that the monster has heard recently. Nearby actions
  /// will increase this and it naturally decays over time (as the monster
  /// "forgets" sounds). If it gets high enough, a sleeping monster will wake
  /// up.
  num noise = 0;

  /// In order to perform [Move]s other than just walking and melee attacks, a
  /// monster must spend this, which regenerates over time.
  int effort = Option.EFFORT_START;

  Monster(Game game, this.breed, int x, int y, int maxHealth)
  : super(game, x, y, maxHealth) {
    energy.speed = Energy.NORMAL_SPEED + breed.speed;
  }

  get appearance() => breed.appearance;

  String get nounText() => 'the ${breed.name}';
  int get person() => 3;
  Gender get gender() => breed.gender;

  /// How much experience a level one [Hero] gains for killing this monster.
  int get experienceCents() => breed.experienceCents;

  /// Gets whether or not this monster has an uninterrupted line of sight to
  /// [target].
  bool canView(Vec target) {
    // Walk to the target.
    for (final step in new Los(pos, game.hero.pos)) {
      if (!game.level[step].isTransparent) return false;
    }

    // If we got here, we made it.
    return true;
  }

  Action onGetAction() {
    // Regenerate effort.
    effort = Math.min(Option.EFFORT_MAX, effort + Option.EFFORT_REGENERATE);

    // Forget sounds over time. Since this occurs on the monster's turn, it
    // means slower monsters will attenuate less frequently. The [Math.pow()]
    // part compensates for this.
    noise *= Math.pow(Option.NOISE_FORGET, Energy.ticksAtSpeed(breed.speed));

    switch (state) {
      case MonsterState.ASLEEP: return getActionAsleep();
      case MonsterState.AWAKE: return getActionAwake();
    }
  }

  Action getActionAsleep() {
    // See if there is enough noise to wake up.
    // TODO(bob): Add breed-specific modifier.
    if (noise > rng.range(50, 5000)) {
      state = MonsterState.AWAKE;
      game.log.add('{1} wake[s] up!', this);

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
      game.log.add('{1} fall[s] asleep!', this);

      // Reset the noise. This ensures the monster stays asleep for a while.
      noise = 0;
      return getActionAsleep();
    }

    // If we're next to the hero, just go for the melee hit. Check this first
    // to avoid more costly AI processing when not needed.
    final toHero = game.hero.pos - pos;
    if (toHero.kingLength == 1) {
      return new WalkAction(toHero);
    }

    // Calculate the score for moving in each possible direction.
    final scores = new List(Direction.ALL.length);

    // The minimum scent required for the monster to notice it. Smaller numbers
    // mean a stronger sense of smell.
    final minScent = Math.pow(0.5, breed.olfaction);

    // How much the monster listens to their sense of smell. The more sensitive
    // it is, the more the monster relies on it.
    // TODO(bob): Add a tuned multiplier here.
    final scentWeight = breed.olfaction * Option.AI_WEIGHT_SCENT;

    getScent(Vec pos) {
      return Math.max(game.level.getScent(pos.x, pos.y) - minScent, 0);
    }

    final scent = getScent(pos);

    // TODO(bob): Make maximum path-length be breed tunable.
    final path = AStar.findDirection(game.level, pos, game.hero.pos, 10);

    final START_SCORE = 100;

    for (var i = 0; i < Direction.ALL.length; i++) {
      final dest = pos + Direction.ALL[i];

      // If the direction is blocked, give it a negative score and skip it.
      if (!canOccupy(dest) || game.level.actorAt(dest) != null) {
        scores[i] = Option.AI_MIN_SCORE;
        continue;
      }

      scores[i] = START_SCORE;

      // TODO(bob): These different score modifiers should be weighted so that
      // (for example) path finding has a greater influence than scent.

      // Apply scent knowledge.
      final scentGradient = getScent(dest) - scent;
      scores[i] += scentGradient * scentWeight;

      // Apply pathfinding.
      if (Direction.ALL[i] == path) {
        scores[i] += Option.AI_WEIGHT_PATH_STRAIGHT;
      } else if (Direction.ALL[i].rotateLeft45 == path) {
        scores[i] += Option.AI_WEIGHT_PATH_NEAR;
      } else if (Direction.ALL[i].rotateRight45 == path) {
        scores[i] += Option.AI_WEIGHT_PATH_NEAR;
      }

      // Add some randomness to make the monster meander.
      scores[i] += rng.range(breed.meander * Option.AI_WEIGHT_MEANDER);
    }

    // Pick the best move.
    var bestScore = Option.AI_MIN_SCORE - 1;
    var bestIndexes;
    for (var i = 0; i < scores.length; i++) {
      if (scores[i] == bestScore) {
        // If multiple directions have the same score, we'll pick randomly
        // between them.
        bestIndexes.add(i);
      } if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndexes = [i];
      }
    }

    if ((bestIndexes.length == 0) || (bestScore == START_SCORE)) {
      // All directions are blocked or no move had any appeal, so just sit.
      return new WalkAction(new Vec(0, 0));
    }

    return new WalkAction(Direction.ALL[rng.item(bestIndexes)]);
  }

  Attack getAttack(Actor defender) => rng.item(breed.attacks);

  void takeHit(Hit hit) {
    if (state == MonsterState.ASLEEP) {
      // Can't sleep through a beating!
      state = MonsterState.AWAKE;
    }
    // TODO(bob): Nothing to do yet. Should eventually handle armor.
  }

  Vec changePosition(Vec pos) {
    // If the monster is (or was) visible, don't let the hero rest through it
    // moving.
    if (game.level[this.pos].visible || game.level[pos].visible) {
      game.hero.disturb();
    }

    return pos;
  }
}

/// A [Monster]'s internal mental state.
class MonsterState {
  static final ASLEEP = const MonsterState(0);
  static final AWAKE  = const MonsterState(1);

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

  final Set<String> flags;

  Breed(this.name, this.gender, this.appearance, this.attacks, this.moves,
      [this.maxHealth, this.olfaction, this.meander, this.speed, this.flags]);

  /// How much experience a level one [Hero] gains for killing a [Monster] of
  /// this breed.
  int get experienceCents() {
    // The more health it has, the longer it can hurt the hero.
    var exp = maxHealth;

    // Faster monsters are worth more.
    exp *= Energy.GAINS[Energy.NORMAL_SPEED + speed];

    // Average the attacks (since they are selected randomly) and factor them
    // in.
    var attackTotal = 0;
    for (final attack in attacks) {
      attackTotal += attack.damage;
    }
    exp *= (attackTotal / attacks.length);

    // TODO(bob): Take into account meander, moves and olfaction.
    return exp.toInt();
  }

  /// When a [Monster] of this Breed is generated, how many of the same type
  /// should be spawned together (roughly).
  int get numberInGroup() {
    if (flags.contains('horde')) return 30;
    if (flags.contains('swarm')) return 20;
    if (flags.contains('pack')) return 12;
    if (flags.contains('group')) return 6;
    if (flags.contains('few')) return 3;
    return 1;
  }

  Monster spawn(Game game, Vec pos) {
    return new Monster(game, this, pos.x, pos.y, maxHealth);
  }
}
