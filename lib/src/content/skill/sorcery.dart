import 'package:piecemeal/src/vec.dart';

import '../../engine.dart';

import '../action/bolt.dart';
import '../action/ray.dart';
import '../elements.dart';

class Icicle extends Spell implements TargetSkill {
  String get description => "Launches a spear-like icicle.";

  @override
  String onExpertiseDescription(int expertise) {
    // TODO: Better description.
    return "Does ${_damage(expertise)} damage and ${_range(expertise)} range.";
  }

  String get name => "Icicle";

  int get complexity => 11;

  int get focusCost => 200;

  num getRange(Game game) => _range(game.hero.skills[this]);

  Action onGetTargetAction(Game game, int level, Vec target) {
    var attack = new Attack(new Noun("the icicle"), "pierce", _damage(level),
        _range(level), Elements.cold);

    var hit = attack.createHit();
    // TODO: Tune.
    return new BoltAction(target, hit);
  }

  int _damage(int expertise) => 5 + expertise ~/ 3;
  int _range(int expertise) => 7 + expertise ~/ 6;
}

class Windstorm extends Spell implements ActionSkill {
  String get description =>
      "Summons a blast of air, spreading out from the sorceror.";

  @override
  String onExpertiseDescription(int expertise) {
    // TODO: Better description.
    return "Does ${_damage(expertise)} damage and ${_range(expertise)} range.";
  }

  String get name => "Windstorm";

  int get complexity => 14;

  int get focusCost => 400;

  bool canUse(Game game) => true;

  Action onGetAction(Game game, int level) {
    var attack = new Attack(new Noun("the wind"), "blast", _damage(level),
        _range(level), Elements.air);

    var hit = attack.createHit();
    // TODO: Tune.
    hit.addDamage(expertise(game.hero) ~/ 2);
    return new RayAction.ring(game.hero.pos, hit);
  }

  int _damage(int expertise) => 4 + expertise ~/ 4;
  int _range(int expertise) => 6 + expertise ~/ 3;
}
