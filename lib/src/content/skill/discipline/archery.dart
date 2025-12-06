import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';

class Archery extends Skill with UsableSkill, TargetSkill {
  // TODO: Tune.
  @override
  int get maxLevel => 20;

  static double _strikeScale(int level) => lerpDouble(level, 1, 20, 0.7, 2.0);

  @override
  String get name => "Archery";

  @override
  String get description =>
      "Kill your foe without risking harm to yourself by unleashing a volley "
      "of arrows from far away.";

  @override
  String levelDescription(int level) =>
      "Scales strike by ${(_strikeScale(level) * 100).toInt()}%.";

  @override
  String? unusableReason(Game game) {
    if (_hasBow(game.hero)) return null;

    return "No bow equipped.";
  }

  bool _hasBow(Hero hero) =>
      hero.equipment.weapons.any((item) => item.type.weaponType == "bow");

  /// Focus cost goes down with level.
  @override
  int focusCost(HeroSave hero, int level) => 21 - level;

  @override
  int getRange(Game game) {
    var hit = game.hero.createRangedHit();
    var level = game.hero.skills.level(this);
    hit.scaleStrike(_strikeScale(level), 'archery');
    return hit.range;
  }

  @override
  Action onGetTargetAction(Game game, int level, Vec target) {
    var hit = game.hero.createRangedHit();
    return BoltAction(target, hit, canMiss: true);
  }
}
