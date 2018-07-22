import '../../debug.dart';
import '../../engine.dart';
import '../action/bolt.dart';

class BoltMove extends RangedMove {
  num get experience =>
      attack.damage * attack.element.experience * (1.0 + range / 20.0);

  BoltMove(num rate, Attack attack) : super(rate, attack);

  bool shouldUse(Monster monster) {
    var target = monster.game.hero.pos;

    // Don't fire if out of range.
    var toTarget = target - monster.pos;
    if (toTarget > range) {
      Debug.monsterLog(monster, "bolt move too far");
      return false;
    }
    if (toTarget < 1.5) {
      Debug.monsterLog(monster, "bolt move too close");
      return false;
    }

    // Don't fire a bolt if it's obstructed.
    if (!monster.canTarget(target)) {
      Debug.monsterLog(monster, "bolt move can't target");
      return false;
    }

    Debug.monsterLog(monster, "bolt move OK");
    return true;
  }

  Action onGetAction(Monster monster) =>
      BoltAction(monster.game.hero.pos, attack.createHit());

  String toString() => "Bolt $attack rate: $rate";
}
