import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';

import '../../action/barrier.dart';
import '../../action/bolt.dart';
import '../../action/flow.dart';
import '../../action/ray.dart';
import '../../elements.dart';

class Icicle extends Spell with TargetSkill {
  @override
  String get name => "Icicle";
  @override
  String get description => "Launches a spear-like icicle.";
  @override
  int get baseComplexity => 10;
  @override
  int get baseFocusCost => 12;
  @override
  int get damage => 8;
  @override
  int get range => 8;

  @override
  Action onGetTargetAction(Game game, int level, Vec target) {
    var attack =
        Attack(Noun("the icicle"), "pierce", damage, range, Elements.cold);
    return BoltAction(target, attack.createHit());
  }
}

class BrilliantBeam extends Spell with TargetSkill {
  @override
  String get name => "Brilliant Beam";
  @override
  String get description => "Emits a blinding beam of radiance.";
  @override
  int get baseComplexity => 14;
  @override
  int get baseFocusCost => 24;
  @override
  int get damage => 10;
  @override
  int get range => 12;

  @override
  Action onGetTargetAction(Game game, int level, Vec target) {
    var attack =
        Attack(Noun("the light"), "sear", damage, range, Elements.light);
    return RayAction.cone(game.hero.pos, target, attack.createHit());
  }
}

class Windstorm extends Spell with ActionSkill {
  @override
  String get name => "Windstorm";
  @override
  String get description =>
      "Summons a blast of air, spreading out from the sorceror.";
  @override
  int get baseComplexity => 18;
  @override
  int get baseFocusCost => 36;
  @override
  int get damage => 10;
  @override
  int get range => 6;

  @override
  Action onGetAction(Game game, int level) {
    var attack = Attack(Noun("the wind"), "blast", damage, range, Elements.air);
    return FlowAction(game.hero.pos, attack.createHit(), Motility.flyAndWalk);
  }
}

class FireBarrier extends Spell with TargetSkill {
  @override
  String get name => "Fire Barrier";
  @override
  String get description => "Creates a wall of fire.";
  @override
  int get baseComplexity => 30;
  @override
  int get baseFocusCost => 45;
  @override
  int get damage => 10;
  @override
  int get range => 8;

  @override
  Action onGetTargetAction(Game game, int level, Vec target) {
    var attack = Attack(Noun("the fire"), "burn", damage, range, Elements.fire);
    return BarrierAction(game.hero.pos, target, attack.createHit());
  }
}

class TidalWave extends Spell with ActionSkill {
  @override
  String get name => "Tidal Wave";
  @override
  String get description => "Summons a giant tidal wave.";
  @override
  int get baseComplexity => 40;
  @override
  int get baseFocusCost => 70;
  @override
  int get damage => 50;
  @override
  int get range => 15;

  @override
  Action onGetAction(Game game, int level) {
    var attack =
        Attack(Noun("the wave"), "inundate", damage, range, Elements.water);
    return FlowAction(game.hero.pos, attack.createHit(),
        Motility.walk | Motility.door | Motility.swim,
        slowness: 2);
  }
}
