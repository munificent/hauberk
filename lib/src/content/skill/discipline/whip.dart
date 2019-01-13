import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';
import 'mastery.dart';

class WhipMastery extends MasteryDiscipline with TargetSkill {
  // TODO: Tune.
  static double _whipScale(int level) => lerpDouble(level, 1, 10, 0.5, 1.0);

  // TODO: Better name.
  String get name => "Whip Mastery";
  String get useName => "Whip Crack";
  String get description =>
      "Whips and flails are difficult to use well, but deadly even at a "
      "distance when mastered.";
  String get weaponType => "whip";

  String levelDescription(int level) {
    var damage = (_whipScale(level) * 100).toInt();
    return super.levelDescription(level) +
        " Ranged whip attacks inflict $damage% of the damage of a regular "
        "attack.";
  }

  int getRange(Game game) => 3;

  Action getTargetAction(Game game, int level, Vec target) {
    var defender = game.stage.actorAt(target);

    // Find which hand has a whip. If both do, just pick the first.
    // TODO: Is this the best way to handle dual-wielded whips?
    var weapons = game.hero.equipment.weapons.toList();
    var hits = game.hero.createMeleeHits(defender);
    assert(weapons.length == hits.length);

    Hit hit;
    for (var i = 0; i < weapons.length; i++) {
      if (weapons[i].type.weaponType != "whip") continue;

      hit = hits[i];
      break;
    }

    assert(hit != null, "Should have at least one whip wielded.");
    hit.scaleDamage(WhipMastery._whipScale(level));

    // TODO: Better effect.
    return BoltAction(target, hit, range: getRange(game), canMiss: true);
  }
}
