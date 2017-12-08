import 'package:piecemeal/src/vec.dart';

import '../../engine.dart';

import '../action/bolt.dart';
import '../action/ray.dart';
import '../elements.dart';
import '../skills.dart';
import 'spell.dart';

class Sorcery extends SchoolSkill {
  String get name => "Sorcery";

  String get description =>
      "Harness the power of raw elemental forces of nature.";
}

class Icicle extends TargetSkill with SpellSkill {
  String get description => "Launches a spear-like icicle.";

  @override
  String levelDescription(int level) {
    // TODO: Better description.
    return "Does ${_damage(level)} damage and ${_range(level)} range.";
  }

  int get maxLevel => 20;

  String get name => "Icicle";

  Skill get prerequisite => Skills.sorcery;

  int get complexity => 11;

  int get focusCost => 200;

  num getRange(Game game) => _range(game.hero.skills[this]);

  Action onGetTargetAction(Game game, int level, Vec target) {
    var attack = new Attack(new Noun("the icicle"), "pierce", _damage(level),
        _range(level), Elements.cold);

    var hit = attack.createHit();
    // TODO: Should the hero modify the hit?
    hit.scaleDamage(effectiveness(game));
    return new BoltAction(target, hit);
  }

  int _damage(int level) => 5 + level;
  int _range(int level) => 7 + level ~/ 4;
}

class Windstorm extends ActionSkill with SpellSkill {
  String get description => "Summons a blast of air, spreading out from the sorceror.";

  @override
  String levelDescription(int level) {
    // TODO: Better description.
    return "Does ${_damage(level)} damage and ${_range(level)} range.";
  }

  int get maxLevel => 20;

  String get name => "Windstorm";

  Skill get prerequisite => Skills.sorcery;

  int get complexity => 14;

  int get focusCost => 400;

  Action onGetAction(Game game, int level) {
    var attack = new Attack(new Noun("the wind"), "blast", _damage(level),
        _range(level), Elements.air);

    var hit = attack.createHit();
    // TODO: Should the hero modify the hit?
    hit.scaleDamage(effectiveness(game));
    return new RayAction.ring(game.hero.pos, hit);
  }

  int _damage(int level) => 4 + level;
  int _range(int level) => 6 + level ~/ 3;
}
