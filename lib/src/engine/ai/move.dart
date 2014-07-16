library hauberk.engine.move;

import '../action_base.dart';
import '../action_combat.dart';
import '../action_magic.dart';
import '../melee.dart';
import '../monster.dart';

/// A [Move] is an action that a [Monster] can perform aside from the basic
/// walking and melee attack actions. Moves include things like spells, breaths,
/// and missiles.
abstract class Move {
  /// Each move has a cost. Monsters have a limited amount of effort that they
  /// can spend on moves, which regenerates over time. This prevents monsters
  /// from using very powerful moves every single turn.
  final int cost;

  /// The range of this move if it's a ranged one, or `0` otherwise.
  int get range => 0;

  Move(this.cost);

  /// Returns `true` if the monster would reasonably perform this move right
  /// now.
  bool shouldUse(Monster monster) => true;

  /// Called when the [Monster] has selected this move. Returns an [Action] that
  /// performs the move.
  Action getAction(Monster monster) {
    monster.spendCharge(cost);
    return onGetAction(monster);
  }

  /// Create the [Action] to perform this move.
  Action onGetAction(Monster monster);
}

class BoltMove extends Move {
  final Attack attack;

  int get range => attack.range;

  BoltMove(int cost, this.attack)
    : super(cost);

  bool shouldUse(Monster monster) {
    // TODO: Should not always assume the hero is the target.
    var target = monster.game.hero.pos;

    // Don't fire if out of range.
    var toTarget = target - monster.pos;
    if (toTarget > range) return false;
    if (toTarget < 1.5) return false;

    // Don't fire a bolt if it's obstructed.
    if (!monster.canTarget(target)) return false;

    // The farther it is, the more likely it is to use a bolt.
    return true;
  }

  Action onGetAction(Monster monster) {
    // TODO: Should not always assume the hero is the target.
    return new BoltAction(monster.pos, monster.game.hero.pos, attack);
  }

  String toString() => "Bolt $attack cost: $cost";
}

class HealMove extends Move {
  /// How much health to restore.
  final int _amount;

  HealMove(int cost, this._amount) : super(cost);

  bool shouldUse(Monster monster) {
    // Heal if it could heal the full amount, or it's getting close to death.
    return (monster.health.current / monster.health.max < 0.25) ||
           (monster.health.max - monster.health.current >= _amount);
  }

  Action onGetAction(Monster monster) {
    return new HealAction(_amount);
  }

  String toString() => "Heal $_amount cost: $cost";
}

class InsultMove extends Move {
  InsultMove(int cost) : super(cost);

  bool get isRanged => true;

  bool shouldUse(Monster monster) {
    // TODO: Should not always assume the hero is the target.
    var target = monster.game.hero.pos;
    var distance = (target - monster.pos).kingLength;

    // Don't insult when in melee distance.
    if (distance <= 1) return false;

    // Don't insult someone it can't see.
    return monster.canView(target);
  }

  Action onGetAction(Monster monster) => new InsultAction(monster.game.hero);

  String toString() => "Insult cost: $cost";
}

class HasteMove extends Move {
  final int _duration;
  final int _speed;

  HasteMove(int cost, this._duration, this._speed) : super(cost);

  bool shouldUse(Monster monster) {
    // Don't use if already hasted.
    return !monster.haste.isActive;
  }

  Action onGetAction(Monster monster) => new HasteAction(_duration, _speed);

  String toString() => "Haste $_speed for $_duration turns cost: $cost";
}

/// Teleports the [Monster] randomly from its current position.
class TeleportMove extends Move {
  final int _range;

  TeleportMove(int cost, this._range) : super(cost);

  Action onGetAction(Monster monster) => new TeleportAction(_range);
}
