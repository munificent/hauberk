// TODO: Spells aren't working right now.
/*
import '../../../engine.dart';
import '../../action/barrier.dart';
import '../../action/bolt.dart';
import '../../action/flow.dart';
import '../../action/ray.dart';
import '../../elements.dart';
import 'spell.dart';

List<Spell> sorcerySpells() {
  return [
    TargetSpell(
      "Icicle",
      description: "Launches a spear-like icicle.",
      complexity: 10,
      focus: 12,
      damage: 8,
      range: 8,
      (spell, game, level, target) {
        var attack = Attack(
          Noun("the icicle"),
          "pierce",
          spell.damage,
          spell.range,
          Elements.cold,
        );
        return BoltAction(target, attack.createHit());
      },
    ),
    TargetSpell(
      "Brilliant Beam",
      description: "Emits a blinding beam of radiance.",
      complexity: 14,
      focus: 24,
      damage: 10,
      range: 12,
      (spell, game, level, target) {
        var attack = Attack(
          Noun("the light"),
          "sear",
          spell.damage,
          spell.range,
          Elements.light,
        );
        return RayAction.cone(game.hero.pos, target, attack.createHit());
      },
    ),
    ActionSpell(
      "Windstorm",
      description: "Summons a blast of air, spreading out from the sorceror.",
      complexity: 18,
      focus: 36,
      damage: 10,
      range: 6,
      (spell, game, level) {
        var attack = Attack(
          Noun("the wind"),
          "blast",
          spell.damage,
          spell.range,
          Elements.air,
        );
        return FlowAction(
          game.hero.pos,
          attack.createHit(),
          Motility.flyAndWalk,
        );
      },
    ),
    TargetSpell(
      "Fire Barrier",
      description: "Creates a wall of fire.",
      complexity: 30,
      focus: 45,
      damage: 10,
      range: 8,
      (spell, game, level, target) {
        var attack = Attack(
          Noun("the fire"),
          "burn",
          spell.damage,
          spell.range,
          Elements.fire,
        );
        return BarrierAction(game.hero.pos, target, attack.createHit());
      },
    ),
    ActionSpell(
      "Tidal Wave",
      description: "Summons a giant tidal wave.",
      complexity: 40,
      focus: 70,
      damage: 50,
      range: 15,
      (spell, game, level) {
        var attack = Attack(
          Noun("the wave"),
          "inundate",
          spell.damage,
          spell.range,
          Elements.water,
        );
        return FlowAction(
          game.hero.pos,
          attack.createHit(),
          Motility.walk | Motility.door | Motility.swim,
          slowness: 2,
        );
      },
    ),
  ];
}
*/
