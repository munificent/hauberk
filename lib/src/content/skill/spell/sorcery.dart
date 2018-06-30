import 'package:piecemeal/src/vec.dart';

import '../../../engine.dart';

import '../../action/barrier.dart';
import '../../action/bolt.dart';
import '../../action/flow.dart';
import '../../action/ray.dart';
import '../../elements.dart';

class Icicle extends Spell implements TargetSkill {
  String get name => "Icicle";
  String get description => "Launches a spear-like icicle.";
  int get baseComplexity => 10;
  int get baseFocusCost => 8;
  int get damage => 8;
  int get range => 8;

  Action onGetTargetAction(Game game, Vec target) {
    var attack = new Attack(
        new Noun("the icicle"), "pierce", damage, range, Elements.cold);
    return new BoltAction(target, attack.createHit());
  }
}

class BrilliantBeam extends Spell implements TargetSkill {
  String get name => "Brilliant Beam";
  String get description => "Emits a blinding beam of radiance.";
  int get baseComplexity => 14;
  int get baseFocusCost => 20;
  int get damage => 10;
  int get range => 12;

  Action onGetTargetAction(Game game, Vec target) {
    var attack = new Attack(
        new Noun("the light"), "sear", damage, range, Elements.light);
    return new RayAction.cone(game.hero.pos, target, attack.createHit());
  }
}

class Windstorm extends Spell implements ActionSkill {
  String get name => "Windstorm";
  String get description =>
      "Summons a blast of air, spreading out from the sorceror.";
  int get baseComplexity => 18;
  int get baseFocusCost => 26;
  int get damage => 10;
  int get range => 6;

  Action onGetAction(Game game) {
    var attack =
        new Attack(new Noun("the wind"), "blast", damage, range, Elements.air);
    return new FlowAction(
        game.hero.pos, attack.createHit(), MotilitySet.flyAndWalk);
  }
}

class FireBarrier extends Spell implements TargetSkill {
  String get name => "Fire Barrier";
  String get description => "Creates a wall of fire.";
  int get baseComplexity => 30;
  int get baseFocusCost => 60;
  int get damage => 10;
  int get range => 8;

  Action onGetTargetAction(Game game, Vec target) {
    var attack =
        new Attack(new Noun("the fire"), "burn", damage, range, Elements.fire);
    return new BarrierAction(game.hero.pos, target, attack.createHit());
  }
}

class TidalWave extends Spell implements ActionSkill {
  String get name => "Tidal Wave";
  String get description => "Summons a giant tidal wave.";
  int get baseComplexity => 40;
  int get baseFocusCost => 200;
  int get damage => 50;
  int get range => 15;

  Action onGetAction(Game game) {
    var attack = new Attack(
        new Noun("the wave"), "inundate", damage, range, Elements.water);
    return new FlowAction(game.hero.pos, attack.createHit(),
        new MotilitySet([Motility.walk, Motility.door, Motility.swim]),
        slowness: 2);
  }
}
