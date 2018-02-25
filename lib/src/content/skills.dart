import '../engine.dart';
import 'monster/builder.dart';
import 'skill/discipline/archery.dart';
import 'skill/discipline/axe.dart';
import 'skill/discipline/slay.dart';
import 'skill/discipline/spear.dart';
import 'skill/discipline/sword.dart';
import 'skill/discipline/whip.dart';
import 'skill/sorcery.dart';

class Skills {
  /// All of the known skills.
  static final List<Skill> all = _generateSkills();

  static final Map<String, Skill> _byName =
      new Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    assert(_byName.containsKey(name));
    return _byName[name];
  }

  static List<Skill> _generateSkills() {
    var skills = <Skill>[
      // Masteries.
      new Archery(),
      new AxeMastery(),
      new SpearMastery(),
      new Swordfighting(),
      new WhipMastery()
    ];

    // Slays.
    for (var group in breedGroups.values) {
      var slay = new SlayDiscipline(group);
      group.slaySkill = slay;
      skills.add(slay);
    }

    // Sorcery spells.
    skills.addAll([new Icicle(), new Windstorm()]);

    return skills;
  }
}
