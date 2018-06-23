import '../../engine.dart';
import '../monster/builder.dart';
import 'discipline/archery.dart';
import 'discipline/axe.dart';
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
      new ClubMastery(),
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

    // Spells.
    skills.addAll([
      // Divination.
      new SenseItems(),
      // Conjuring.
      new Flee(),
      new Escape(),
      new Disappear(),
      // Sorcery.
      new Icicle(),
      new BrilliantBeam(),
      new Windstorm(),
      new FireBarrier(),
      new TidalWave()
    ]);

    return skills;
  }
}
