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
  static final List<Skill> all = _generateSkills();

  static final Map<String, Skill> _byName =
      Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    if (!_byName.containsKey(name)) {
      throw ArgumentError("Unknown skill '$name'.");
    }

    return _byName[name];
  }

  static List<Skill> _generateSkills() {
    var skills = <Skill>[
      BattleHardening(),
      DualWield(),
    ];

    // Masteries.
    skills.addAll([
      Archery(),
      AxeMastery(),
      ClubMastery(),
      SpearMastery(),
      Swordfighting(),
      WhipMastery(),
    ]);

    // Slays.
    skills.addAll([
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
    ]);

    // Spells.
    skills.addAll([
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
      TidalWave()
    ]);

    return skills;
  }
}
