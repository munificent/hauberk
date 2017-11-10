import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/bolt.dart';
import '../game.dart';
import '../hero/command.dart';
import 'skill.dart';

class Archery extends Skill {
  // TODO: Tune.
  static int focusCost(int level) => lerpInt(level, 1, 20, 300, 1);

  int get maxLevel => 20;

  String get name => "Archery";

  Skill get prerequisite => Skill.strength;

  Command get command => new ArcheryCommand();
}

class ArcheryCommand extends TargetCommand {
  String get name => "Archery";

  num getRange(Game game) {
    var hit = game.hero.createRangedHit();
    return hit.range;
  }

  bool canUse(Game game) {
    // Get the equipped ranged weapon, if any.
    var weapon = game.hero.equipment.weapon;
    return weapon != null && weapon.attack.isRanged;
  }

  Action getTargetAction(Game game, Vec target) {
    var hit = game.hero.createRangedHit();
    var focus = Archery.focusCost(game.hero.skills[Skill.archery]);
    return new FocusAction(focus, new BoltAction(target, hit, canMiss: true));
  }
}
