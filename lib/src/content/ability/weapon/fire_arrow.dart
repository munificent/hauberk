import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';
import '../../skill/archery.dart';
import '../mastery.dart';

class FireArrowAbility extends Ability with TargetAbility {
  @override
  String get name => "Fire Arrow";

  @override
  final List<Requirement> requirements = [WeaponTypeRequirement("bow")];

  /// Focus cost goes down with level.
  @override
  int focusCost(HeroSave save) {
    var level = save.skills.level(Archery.instance);
    return 21 - level;
  }

  @override
  int getRange(Game game) {
    return game.hero.createRangedHit().range;
  }

  @override
  Action onGetTargetAction(Game game, Vec target) {
    var hit = game.hero.createRangedHit();
    return BoltAction(target, hit, canMiss: true);
  }
}
