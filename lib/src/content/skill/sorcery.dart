import 'package:piecemeal/src/vec.dart';

import '../../engine.dart';

import '../action/bolt.dart';
import '../action/ray.dart';
import '../elements.dart';

class Icicle extends Spell implements TargetSkill {
  String get description => "Launches a spear-like icicle.";

  @override
  String levelDescription(int level) {
    // TODO: Better description.
    return "Does ${_damage(level)} damage and ${_range(level)} range.";
  }

  int get maxLevel => 20;

  String get name => "Icicle";

  int get complexity => 11;

  int get focusCost => 200;

  bool canUse(Game game) => true;

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

class Windstorm extends Spell implements ActionSkill {
  String get description =>
      "Summons a blast of air, spreading out from the sorceror.";

  @override
  String levelDescription(int level) {
    // TODO: Better description.
    return "Does ${_damage(level)} damage and ${_range(level)} range.";
  }

  int get maxLevel => 20;

  String get name => "Windstorm";

  int get complexity => 14;

  int get focusCost => 400;

  bool canUse(Game game) => true;

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
