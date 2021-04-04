import '../../engine.dart';
import 'discipline/archery.dart';
import 'discipline/axe.dart';
import 'discipline/battle_hardening.dart';
import 'discipline/club.dart';
import 'discipline/dual_wield.dart';
import 'discipline/slay.dart';
import 'discipline/spear.dart';
import 'discipline/sword.dart';
import 'discipline/whip.dart';
import 'spell/conjuring.dart';
import 'spell/divination.dart';
import 'spell/sorcery.dart';

class Skills {
  /// All of the known skills.
  static final List<Skill> all = [
    // Disciplines.
    ...[
      BattleHardening(),
      DualWield(),

      // Masteries.
      Archery(),
      AxeMastery(),
      ClubMastery(),
      SpearMastery(),
      Swordfighting(),
      WhipMastery(),

      // Slays.
      SlayDiscipline("Animals", "animal"),
      SlayDiscipline("Bugs", "bug"),
      SlayDiscipline("Dragons", "dragon"),
      SlayDiscipline("Fae Folk", "fae"),
      SlayDiscipline("Goblins", "goblin"),
      SlayDiscipline("Humans", "human"),
      SlayDiscipline("Jellies", "jelly"),
      SlayDiscipline("Kobolds", "kobold"),
      SlayDiscipline("Plants", "plant"),
      SlayDiscipline("Saurians", "saurian"),
      SlayDiscipline("Undead", "undead"),
    ],

    // Spells.
    ...[
      // Divination.
      SenseItems(),

      // Conjuring.
      Flee(),
      Escape(),
      Disappear(),

      // Sorcery.
      Icicle(),
      BrilliantBeam(),
      Windstorm(),
      FireBarrier(),
      TidalWave(),
    ]
  ];

  static final Map<String, Skill> _byName = {
    for (var skill in all) skill.name: skill
  };

  static Skill find(String name) {
    var skill = _byName[name];
    if (skill == null) throw ArgumentError("Unknown skill '$name'.");
    return skill;
  }
}
