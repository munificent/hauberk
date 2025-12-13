import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';

class Archery extends Skill {
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

  // TODO: Having to make this late to plumb the skill through is gross.
  @override
  late final Ability ability = FireArrowAbility(this);

  @override
  void modifyRangedHit(Hero hero, Item? weapon, Hit hit, int level) {
    if (weapon != null && weapon.type.weaponType == 'bow') {
      hit.scaleStrike(_strikeScale(level), 'archery');
    }
  }
}

class FireArrowAbility extends Ability with TargetAbility {
  @override
  final Skill skill;

  FireArrowAbility(this.skill);

  @override
  String get name => "Fire Arrow";

  @override
  String? unusableReason(Game game) {
    if (!_hasBow(game.hero)) return "No bow equipped";
    return null;
  }

  /// Focus cost goes down with level.
  @override
  int focusCost(HeroSave hero, int level) => 21 - level;

  @override
  int getRange(Game game) {
    return game.hero.createRangedHit().range;
  }

  @override
  Action onGetTargetAction(Game game, int level, Vec target) {
    var hit = game.hero.createRangedHit();
    return BoltAction(target, hit, canMiss: true);
  }

  bool _hasBow(Hero hero) =>
      hero.equipment.weapons.any((item) => item.type.weaponType == "bow");
}
