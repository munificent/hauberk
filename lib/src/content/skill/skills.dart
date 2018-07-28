import '../../engine.dart';
import '../monster/builder.dart';
import 'discipline/archery.dart';
import 'discipline/axe.dart';
import 'discipline/battle_hardening.dart';
import 'discipline/club.dart';
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
    assert(_byName.containsKey(name));
    return _byName[name];
  }

  static List<Skill> _generateSkills() {
    var skills = <Skill>[BattleHardening()];

    // Masteries.
    skills.addAll([
      Archery(),
      AxeMastery(),
      ClubMastery(),
      SpearMastery(),
      Swordfighting(),
      WhipMastery()
    ]);

    // Slays.
    for (var group in breedGroups.values) {
      var slay = SlayDiscipline(group);
      group.slaySkill = slay;
      skills.add(slay);
    }

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
