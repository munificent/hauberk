import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';

class Archery extends Discipline with TargetSkill {
  // TODO: Tune.
  int get maxLevel => 20;

  static double _strikeScale(int level) => lerpDouble(level, 1, 20, 0.7, 2.0);

  String get name => "Archery";

  String get description =>
      "Kill your foe without risking harm to yourself by unleashing a volley "
      "of arrows from far away.";

  String levelDescription(int level) =>
      "Scales strike by ${(_strikeScale(level) * 100).toInt().toString()}%.";

  String unusableReason(Game game) {
    if (_hasBow(game.hero)) return null;

    return "No bow equipped.";
  }

  bool _hasBow(Hero hero) =>
      hero.equipment.weapons.any((item) => item.type.weaponType == "bow");

  // TODO: Tune.
  int baseTrainingNeeded(int level) {
    // Reach level 1 immediately so that the hero can begin using the bow.
    level--;

    return 100 * level * level * level;
  }

  int getRange(Game game) {
    var hit = game.hero.createRangedHit();
    var level = game.hero.skills.level(this);
    hit.scaleStrike(_strikeScale(level));
    return hit.range;
  }

  Action getTargetAction(Game game, int level, Vec target) {
    var hit = game.hero.createRangedHit();
    return ArrowAction(this, target, hit);
  }
}

/// Fires a bolt, a straight line of an elemental attack that stops at the
/// first [Actor] is hits or opaque tile.
class ArrowAction extends BoltAction {
  final Archery _skill;

  ArrowAction(this._skill, Vec target, Hit hit)
      : super(target, hit, canMiss: true);

  bool onHitActor(Vec pos, Actor target) {
    super.onHitActor(pos, target);

    var monster = target as Monster;
    hero.skills.earnPoints(_skill, (monster.experience / 1000).ceil());
    hero.refreshSkill(_skill);
    return true;
  }
}
