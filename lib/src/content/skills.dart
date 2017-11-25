import '../engine.dart';
import 'skill/archery.dart';

class Skills {
  static final archery = new Archery();

  /// All of the known skills.
  static final List<Skill> all = [
    Skill.strength,
    Skill.agility,
    Skill.fortitude,
    Skill.intellect,
    Skill.will,
    archery
  ];

  static final Map<String, Skill> _byName =
      new Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    assert(_byName.containsKey(name));
    return _byName[name];
  }
}
