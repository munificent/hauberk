import '../engine.dart';
import 'skill/archery.dart';
import 'skill/axe.dart';
import 'skill/spear.dart';
import 'skill/sword.dart';
import 'skill/whip.dart';

class Skills {
  static final archery = new Archery();
  static final axeMastery = new AxeMastery();
  static final spearMastery = new SpearMastery();
  static final swordfighting = new Swordfighting();
  static final whipMastery = new WhipMastery();

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
    // TODO: Polearm skill similar to spear mastery but longer range (but maybe
    // does not hit the adjacent tile?)
    swordfighting,
    whipMastery
  ];

  static final Map<String, Skill> _byName =
      new Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    assert(_byName.containsKey(name));
    return _byName[name];
  }
}
