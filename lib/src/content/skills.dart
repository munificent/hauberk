import '../engine.dart';
import 'skill/archery.dart';
import 'skill/axe.dart';
import 'skill/school.dart';
import 'skill/spear.dart';
import 'skill/sword.dart';
import 'skill/whip.dart';

class Skills {
  static final archery = new Archery();
  static final axeMastery = new AxeMastery();
  static final spearMastery = new SpearMastery();
  static final swordfighting = new Swordfighting();
  static final whipMastery = new WhipMastery();
  static final sorcery = new Sorcery();
  static final icicle = new Icicle();

  /// All of the known skills.
  static final List<Skill> all = [
    Skill.might,
    Skill.flexibility,
    Skill.toughness,
    Skill.education,
    Skill.discipline,
    archery,
    axeMastery,
    spearMastery,
    swordfighting,
    whipMastery,
    sorcery,
    icicle,
  ];

  static final Map<String, Skill> _byName =
      new Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    assert(_byName.containsKey(name));
    return _byName[name];
  }
}
