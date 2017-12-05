import 'package:piecemeal/src/vec.dart';

import '../../engine.dart';

import '../action/bolt.dart';
import '../elements.dart';
import '../skills.dart';

/// Base class for spell school skills.
abstract class SchoolSkill extends Skill {
  // TODO: Tune.
  static double focusScale(int level) => lerpDouble(level, 1, 20, 1.0, 0.2);

  // TODO: Tune.
  int get maxLevel => 20;

  Skill get prerequisite => Skill.education;

  @override
  String levelDescription(int level) {
    var percent = ((1.0 - focusScale(level)) * 100).toInt();
    return "Reduce the focus cost of $name spells by $percent%.";
  }
}

class Sorcery extends SchoolSkill {
  String get name => "Sorcery";

  String get description =>
      "Harness the power of raw elemental forces of nature.";
}

class Icicle extends Skill {
  String get description => "Launches a spear-like icicle.";

  @override
  String levelDescription(int level) {
    // TODO: Better description and damage.
    return "Does $level damage.";
  }

  int get maxLevel => 20;

  String get name => "Icicle";

  Skill get prerequisite => Skills.sorcery;

  Command get command => new IcicleCommand();
}

class IcicleCommand extends TargetCommand {
  num getRange(Game game) => 10;

  Action getTargetAction(Game game, Vec target) {
    // TODO: Damage based on level.
    var attack =
        new Attack(new Noun("the icicle"), "pierce[s]", 20, 10, Elements.cold);
    // TODO: Hero modify hit?
    return new BoltAction(target, attack.createHit());
  }

  String get name => "Icicle";
}
