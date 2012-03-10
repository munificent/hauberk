/// An active entity in the game. Includes monsters and the hero.
class Actor implements Noun {
  final Game game;
  int energy;
  Vec _pos;

  Vec get pos() => _pos;
  void set pos(Vec value) {
    if (value != _pos) _pos = changePosition(value);
  }

  int get x() => pos.x;
  void set x(int value) => pos = new Vec(value, y);

  int get y() => pos.y;
  void set y(int value) => pos = new Vec(x, value);

  Actor(this.game, int x, int y)
  : _pos = new Vec(x, y),
    energy = new Energy(Energy.NORMAL_SPEED);

  get appearance() {
    assert(false); // Abstract.
  }

  bool get needsInput() => false;

  Action getAction() {
    // Do nothing.
  }

  bool canOccupy(Vec pos) {
    if (pos.x < 0) return false;
    if (pos.x >= game.level.width) return false;
    if (pos.y < 0) return false;
    if (pos.y >= game.level.height) return false;

    return game.level[pos].type == TileType.FLOOR;
  }

  /// Called when the actor's position is about to change to [pos]. Override
  /// to do stuff when the position changes. Returns the new position.
  Vec changePosition(Vec pos) => pos;

  String get nounText() {
    assert(false); // Abstract.
  }

  int get person() {
    assert(false); // Abstract.
  }

  Gender get gender() {
    assert(false); // Abstract.
  }
}

class Monster extends Actor {
  final Breed breed;

  Monster(Game game, this.breed, int x, int y) : super(game, x, y);

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

    final scent = game.level.getScent(pos.x, pos.y);

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

      // Apply scent knowledge.
      final gradient = game.level.getScent(dest.x, dest.y) - scent;
      if (gradient.abs() > breed.minScent) {
        // TODO(bob): Could apply a breed-specific weight here to control how
        // much the monster relies on their sense of smell.
        scores[i] += gradient;
      }

      // TODO(bob): Other pathfinding logic. If the monster is within a certain
      // distance and can see the hero, should use ideal pathfinding.

      // TODO(bob): Should add a random amount to each score based on how
      // erratic the breed is.
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
}

/// A single kind of [Monster] in the game.
class Breed {
  final Gender gender;
  final String name;

  /// Untyped so the engine isn't coupled to how monsters appear.
  final appearance;

  /// The minimum scent strength that the monster can detect. Zero means any
  /// scent can be picked up, 1.0 means the monster has no sense of smell.
  final num minScent;

  Breed(this.name, this.gender, this.appearance, [this.minScent]);
}
