import '../../../engine.dart';
import '../../action/barrier.dart';
import '../../action/bolt.dart';
import '../../action/flow.dart';
import '../../action/ray.dart';
import '../../elements.dart';
import '../../skill/spell_school.dart';
import 'spell.dart';

// TODO: Spells should get stronger as sorcery level increases.

List<Spell> sorcerySpells() {
  return [
    TargetSpell(
      "Icicle",
      SpellSchool.sorcery,
      description: "Launches a spear-like icicle.",
      spellLevel: 1,
      focus: 12,
      range: 8,
      (spell, game, target) {
        var attack = Attack(
          Prop("icicle"),
          "pierce",
          8,
          range: spell.range,
          element: Elements.cold,
        );
        return BoltAction(target, attack.createHit());
      },
    ),
    TargetSpell(
      "Brilliant Beam",
      SpellSchool.sorcery,
      description: "Emits a blinding beam of radiance.",
      spellLevel: 2,
      focus: 24,
      range: 12,
      (spell, game, target) {
        var attack = Attack(
          Prop("light"),
          "sear",
          10,
          range: spell.range,
          element: Elements.light,
        );
        return RayAction.narrowCone(game.hero.pos, target, attack.createHit());
      },
    ),
    ActionSpell(
      "Windstorm",
      SpellSchool.sorcery,
      description: "Summons a blast of air, spreading out from the sorceror.",
      spellLevel: 3,
      focus: 36,
      (spell, game) {
        var attack = Attack(
          Prop("wind"),
          "blast",
          10,
          range: 6,
          element: Elements.air,
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
      SpellSchool.sorcery,
      description: "Creates a wall of fire.",
      spellLevel: 4,
      focus: 45,
      range: 8,
      (spell, game, target) {
        var attack = Attack(
          Prop("fire"),
          "burn",
          10,
          range: spell.range,
          element: Elements.fire,
        );
        return BarrierAction(game.hero.pos, target, attack.createHit());
      },
    ),
    ActionSpell(
      "Tidal Wave",
      SpellSchool.sorcery,
      description: "Summons a giant tidal wave.",
      spellLevel: 5,
      focus: 70,
      (spell, game) {
        var attack = Attack(
          Prop("wave"),
          "inundate",
          50,
          range: 15,
          element: Elements.water,
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
