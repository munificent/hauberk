
class Monster extends Actor {
  final Breed breed;

  Monster(Game game, this.breed, int x, int y, int maxHealth)
  : super(game, x, y, maxHealth) {
    energy.speed = Energy.NORMAL_SPEED + breed.speed;
  }

  get appearance() => breed.appearance;

  String get nounText() => 'the ${breed.name}';
  int get person() => 3;
  Gender get gender() => breed.gender;

  /// Gets whether or not this monster has an uninterrupted line of sight to
  /// [target].
  bool canView(Pos target) {
    // Walk to the target.
    for (final step in new Los(pos, game.hero.pos)) {
      if (!game.level[step].isTransparent) return false;
    }

    // If we got here, we made it.
    return true;
  }

  void getAction() {
    // If we're next to the hero, just go for the melee hit. Check this first
    // to avoid more costly AI processing when not needed.
    final toHero = game.hero.pos - pos;
    if (toHero.kingLength == 1) {
      return new MoveAction(toHero);
    }

    final directions = [
      Direction.N,
      Direction.NE,
      Direction.E,
      Direction.SE,
      Direction.S,
      Direction.SW,
      Direction.W,
      Direction.NW
    ];

    // Calculate the score for moving in each possible direction.
    final scores = new List(directions.length);

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
    final path  = game.level.getPath(pos.x, pos.y);

    final MIN_SCORE = -99999;
    final START_SCORE = 100;

    for (var i = 0; i < directions.length; i++) {
      final dest = pos + directions[i];

      // If the direction is blocked, give it a negative score and skip it.
      if (!canOccupy(dest) || game.level.actorAt(dest) != null) {
        scores[i] = MIN_SCORE;
        continue;
      }

      scores[i] = START_SCORE;

      // TODO(bob): These different score modifiers should be weighted so that
      // (for example) path finding has a greater influence than scent.

      // Apply scent knowledge.
      final scentGradient = getScent(dest) - scent;
      scores[i] += scentGradient * scentWeight;

      // Apply ideal pathfinding (if known).
      // TODO(bob): Could limit the path length that each breed is smart enough
      // to follow.
      if (path != -1) {
        final pathHere = game.level.getPath(dest.x, dest.y);
        if (pathHere != -1) {
          scores[i] += (path - pathHere) * Option.AI_WEIGHT_PATH;
        }
      }

      // Add some randomness to make the monster meander.
      scores[i] += rng.range(breed.meander * Option.AI_WEIGHT_MEANDER);
    }

    // Pick the best move.
    var bestScore = MIN_SCORE - 1;
    var bestIndexes;
    for (var i = 0; i < directions.length; i++) {
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
      return new MoveAction(new Vec(0, 0));
    }

    return new MoveAction(directions[rng.item(bestIndexes)]);

    /*
    // If it can see the hero, go straight towards him.
    if (canView(game.hero.pos)) {
      // TODO(bob): What about transparent obstacles?
      final x = sign(game.hero.x - pos.x);
      final y = sign(game.hero.y - pos.y);
      final move = new Vec(x, y);

      // TODO(bob): Should try adjacent directions if preferred one is blocked.
      final dest = pos + move;
      if (canOccupy(dest)) {
        // Don't hit another monster.
        final occupier = game.level.actorAt(dest);
        if (occupier == null || occupier == game.hero) {
          return new MoveAction(move);
        }
      }
    }
    */
  }

  Attack getAttack(Actor defender) => rng.item(breed.attacks);

  void takeHit(Hit hit) {
    // TODO(bob): Temp.
    hit.bindDefense(strike: 30);
  }
}

/// A [Monster]'s internal mental state.
class MonsterState {
  static final ASLEEP = const MonsterState(0);
  static final AWAKE  = const MonsterState(1);
  static final AFRAID = const MonsterState(2);

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

  Breed(this.name, this.gender, this.appearance, this.attacks,
      [this.maxHealth, this.olfaction, this.meander, this.speed]);

  Monster spawn(Game game, Vec pos) {
    return new Monster(game, this, pos.x, pos.y, maxHealth);
  }
}
