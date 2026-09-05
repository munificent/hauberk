import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';
import '../../skill/mastery.dart';
import '../mastery.dart';

// TODO: Probably want to make this more powerful and give it a focus cost.
class WhipCrackAbility extends Ability with TargetAbility {
  // TODO: Tune.
  static double _whipScale(int level) =>
      lerpDouble(level, 1, Skill.modifiedMax, 1.0, 3.0);

  @override
  String get name => "Whip Crack";

  @override
  final List<Requirement> requirements = [WeaponTypeRequirement("whip")];

  @override
  int getRange(Game game) => 3;

  @override
  Action onGetTargetAction(Game game, Vec target) {
    var defender = game.stage.actorAt(target);

    // Find which hand has a whip. If both do, just pick the first.
    // TODO: Is this the best way to handle dual-wielded whips?
    var weapons = game.hero.equipment.weapons.toList();
    var hits = game.hero.createMeleeHits(defender);
    assert(weapons.length == hits.length);

    // Should have at least one whip wielded.
    late Hit hit;
    for (var i = 0; i < weapons.length; i++) {
      if (weapons[i].type.weaponType != "whip") continue;

      hit = hits[i];
      break;
    }

    var level = game.hero.save.skills.level(WhipMastery.instance);
    hit.scaleDamage(_whipScale(level), "whip mastery");

    // TODO: Better effect.
    return BoltAction(target, hit, range: getRange(game), canMiss: true);
  }
}
