import '../engine.dart';
import 'skill/archery.dart';
import 'skill/axe.dart';
import 'skill/spear.dart';

class Skills {
  static final archery = new Archery();
  static final axeMastery = new AxeMastery();
  static final spearMastery = new SpearMastery();

  /// All of the known skills.
  static final List<Skill> all = [
    Skill.strength,
    Skill.agility,
    Skill.fortitude,
    Skill.intellect,
    Skill.will,
    archery,
    axeMastery,
    spearMastery,
  ];

  static final Map<String, Skill> _byName =
      new Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    assert(_byName.containsKey(name));
    return _byName[name];
  }
}
