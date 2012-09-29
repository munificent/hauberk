/// A [Move] is an action that a [Monster] can perform aside from the basic
/// walking and melee attack actions. Moves include things like spells, breaths,
/// and missiles.
class Move {
  /// Each move has a cost. Monsters have a limited amount of effort that they
  /// can spend on moves, which regenerates over time. This prevents monsters
  /// from using very powerful moves every single turn.
  final int cost;

  Move(this.cost);

  /// Gets the AI score for performing this move. The higher the score, the more
  /// likely the monster is to select this move over other options.
  abstract num getScore(Monster monster);

  /// Called when the [Monster] has selected this move. Returns an [Action] that
  /// performs the move.
  Action getAction(Monster monster) {
    monster.recharge += cost;
    return onGetAction(monster);
  }

  /// Create the [Action] to perform this move.
  abstract Action onGetAction(Monster monster);
}

class BoltMove extends Move {
  final Attack attack;

  BoltMove(int cost, this.attack)
    : super(cost);

  num getScore(Monster monster) {
    // TODO(bob): Should not always assume the hero is the target.
    final target = monster.game.hero.pos;

    // Don't fire if out of range.
    if ((target - monster.pos).kingLength > Option.MAX_BOLT_DISTANCE) return 0;

    // Don't fire a bolt if it's obstructed.
    // TODO(bob): Should probably only fire if there aren't any other monsters
    // in the way too, though friendly fire is pretty entertaining.
    if (!monster.canView(target)) return 0;

    // The farther it is, the more likely it is to use a bolt.
    return 100 * (target - monster.pos).kingLength / Option.MAX_BOLT_DISTANCE;
  }

  Action onGetAction(Monster monster) {
    // TODO(bob): Should not always assume the hero is the target.
    return new BoltAction(monster.pos, monster.game.hero.pos, attack);
  }
}

class HealMove extends Move {
  /// How much health to restore.
  final int amount;

  HealMove(int cost, this.amount) : super(cost);

  num getScore(Monster monster) {
    // The closer it is to death, the more it wants to heal.
    return 100 * (1 - (monster.health.current / monster.health.max));
  }

  Action onGetAction(Monster monster) {
    return new HealAction(amount);
  }
}

class InsultMove extends Move {
  InsultMove(int cost) : super(cost);

  num getScore(Monster monster) {
    // TODO(bob): Should not always assume the hero is the target.
    final target = monster.game.hero.pos;
    final distance = (target - monster.pos).kingLength;

    // Don't insult when in melee distance.
    if (distance <= 1) return 0;

    // Don't insult someone it can't see.
    if (!monster.canView(target)) return 0;

    // Randomly insult.
    return rng.range(80);
  }

  Action onGetAction(Monster monster) => new InsultAction(monster.game.hero);
}
