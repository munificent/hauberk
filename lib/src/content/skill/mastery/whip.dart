import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';
import 'mastery.dart';

class WhipMastery extends MasterySkill {
  // TODO: Tune.
  static double _whipScale(int level) =>
      lerpDouble(level, 1, Skill.maxLevel, 1.0, 3.0);

  // TODO: Better name.
  @override
  String get name => "Whip Mastery";

  @override
  String get description =>
      "Whips and flails are difficult to use well, but deadly even at a "
      "distance when mastered.";

  @override
  String get weaponType => "whip";

  // TODO: Having to make this late to plumb the skill through is gross.
  @override
  late final Ability ability = WhipCrackAbility(this);

  @override
  String levelDescription(int level) {
    var damage = (_whipScale(level) * 100).toInt();
    return "${super.levelDescription(level)} Ranged whip attacks inflict "
        "$damage% of the damage of a regular attack.";
  }
}

// TODO: Probably want to make this more powerful and give it a focus cost.
class WhipCrackAbility extends MasteryAbility with TargetAbility {
  @override
  final Skill skill;

  WhipCrackAbility(this.skill);

  @override
  String get name => "Whip Crack";

  @override
  String get weaponType => "whip";

  @override
  int getRange(Game game) => 3;

  @override
  Action onGetTargetAction(Game game, int level, Vec target) {
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

    hit.scaleDamage(WhipMastery._whipScale(level), "whip mastery");

    // TODO: Better effect.
    return BoltAction(target, hit, range: getRange(game), canMiss: true);
  }
}
