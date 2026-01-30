import '../../engine.dart';
import '../action/barrier.dart';
import '../action/bolt.dart';
import '../action/flow.dart';
import '../action/ray.dart';
import '../elements.dart';
import '../spells.dart';

// TODO: Spells should get stronger as sorcery level increases.

List<Spell> sorcerySpells(Skill sorcerySkill) {
  return [
    TargetSpell(
      sorcerySkill,
      "Icicle",
      description: "Launches a spear-like icicle.",
      spellLevel: 1,
      focus: 12,
      range: 8,
      (spell, game, level, target) {
        var attack = Attack(
          Prop("icicle"),
          "pierce",
          8,
          spell.range,
          Elements.cold,
        );
        return BoltAction(target, attack.createHit());
      },
    ),
    TargetSpell(
      sorcerySkill,
      "Brilliant Beam",
      description: "Emits a blinding beam of radiance.",
      spellLevel: 2,
      focus: 24,
      range: 12,
      (spell, game, level, target) {
        var attack = Attack(
          Prop("light"),
          "sear",
          10,
          spell.range,
          Elements.light,
        );
        return RayAction.cone(game.hero.pos, target, attack.createHit());
      },
    ),
    ActionSpell(
      sorcerySkill,
      "Windstorm",
      description: "Summons a blast of air, spreading out from the sorceror.",
      spellLevel: 3,
      focus: 36,
      (spell, game, level) {
        var attack = Attack(Prop("wind"), "blast", 10, 6, Elements.air);
        return FlowAction(
          game.hero.pos,
          attack.createHit(),
          Motility.flyAndWalk,
        );
      },
    ),
    TargetSpell(
      sorcerySkill,
      "Fire Barrier",
      description: "Creates a wall of fire.",
      spellLevel: 4,
      focus: 45,
      range: 8,
      (spell, game, level, target) {
        var attack = Attack(
          Prop("fire"),
          "burn",
          10,
          spell.range,
          Elements.fire,
        );
        return BarrierAction(game.hero.pos, target, attack.createHit());
      },
    ),
    ActionSpell(
      sorcerySkill,
      "Tidal Wave",
      description: "Summons a giant tidal wave.",
      spellLevel: 5,
      focus: 70,
      (spell, game, level) {
        var attack = Attack(Prop("wave"), "inundate", 50, 15, Elements.water);
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
