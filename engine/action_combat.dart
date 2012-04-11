/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    // Get all of the melee information from the participants.
    final attack = actor.getAttack(defender);
    final hit = new Hit(attack);
    defender.takeHit(hit);

    // Roll for damage.
    final damage = hit.rollDamage();

    if (damage == 0) {
      // Armor cancelled out all damage.
      return succeed('{1} miss[es] {2}.', actor, defender);
    }

    defender.health.current -= damage;

    if (defender.health.current == 0) {
      addEvent(new Event.kill(defender));

      defender.onDied(actor);
      actor.onKilled(defender);

      if (defender is! Hero) {
        game.level.actors.remove(defender);
      }
      return succeed('{1} kill[s] {2}.', actor, defender);
    }

    addEvent(new Event.hit(defender, damage));
    return succeed('{1} ${attack.verb} {2}.', actor, defender);
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

class EatAction extends Action {
  final int amount;

  EatAction(this.amount);

  ActionResult onPerform() {
    if (hero.hunger < amount) {
      hero.hunger = 0;
      return succeed('{1} [are|is] stuffed.', actor);
    } else {
      hero.hunger -= amount;
      return succeed('{1} feel[s] less hungry.', actor);
    }
  }
}

class HealAction extends Action {
  final int amount;

  HealAction(this.amount);

  ActionResult onPerform() {
    if (actor.health.isMax) {
      return succeed("{1} [don't|doesn't] feel any different.", actor);
    } else {
      actor.health.current += amount;
      return succeed('{1} feel[s] better.', actor);
    }
  }
}

class QuestAction extends Action {
  ActionResult onPerform() {
    game.completeQuest();
    return succeed();
  }
}
