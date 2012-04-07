/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    final attack = actor.getAttack(defender);
    final hit = new Hit(attack);
    defender.takeHit(hit);

    final damage = rng.triangleInt(attack.damage, attack.damage ~/ 2);
    defender.health.current -= damage;

    if (defender.health.current == 0) {
      game.log.add('{1} kill[s] {2}.', actor, defender);

      addEvent(new Event.kill(defender));

      if (defender is! Hero) {
        game.level.actors.remove(defender);
      }
    } else {
      final health = defender.health;
      game.log.add('{1} ${attack.verb} {2}.', actor, defender);

      addEvent(new Event.hit(defender, damage));
    }

    return succeed();
  }

  bool get noise() => Option.NOISE_HIT;

  String toString() => '$actor attacks $defender';
}

class BoltAction extends Action {
  final Iterator<Los> los;

  BoltAction(Vec from, Vec to)
  : los = new Los(from, to).iterator();

  ActionResult onPerform() {
    final pos = los.next();

    // Stop if we hit a wall.
    if (!game.level[pos].isTransparent) return succeed();

    addEvent(new Event.bolt(pos));

    return los.hasNext() ? ActionResult.NOT_DONE : ActionResult.SUCCESS;
  }
}
