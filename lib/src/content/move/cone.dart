import 'package:piecemeal/piecemeal.dart';

import '../../debug.dart';
import '../../engine.dart';
import '../action/ray.dart';

class ConeMove extends Move {
  final Attack attack;
  @override
  int get range => attack.range;

  @override
  num get experience =>
      attack.damage * 3.0 * attack.element.experience * (1.0 + range / 10.0);

  ConeMove(super.rate, this.attack);

  @override
  bool shouldUse(Game game, Monster monster) {
    if (monster.isBlinded && rng.float(1.0) < monster.sightReliance) {
      var chance =
          lerpDouble(monster.sightReliance, 0.0, 1.0, 0.0, 70.0).toInt();
      if (rng.percent(chance)) return false;
    }

    var target = game.hero.pos;

    // Don't fire if out of range.
    var toTarget = target - monster.pos;
    if (toTarget > range) {
      Debug.monsterLog(monster, "cone move too far");
      return false;
    }

    // TODO: Should minimize friendly fire.
    if (!monster.canView(target)) {
      Debug.monsterLog(monster, "cone move can't target");
      return false;
    }

    Debug.monsterLog(monster, "cone move OK");
    return true;
  }

  @override
  Action onGetAction(Game game, Monster monster) =>
      RayAction.cone(monster.pos, game.hero.pos, attack.createHit());

  @override
  String toString() => "Cone $attack rate: $rate";
}
