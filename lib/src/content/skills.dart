import '../engine.dart';
import 'skill/archery.dart';
import 'skill/axe.dart';
import 'skill/sorcery.dart';
import 'skill/spear.dart';
import 'skill/sword.dart';
import 'skill/whip.dart';

class Skills {
  /// All of the known skills.
  static final List<Skill> all = [
    new Archery(),
    new AxeMastery(),
    new SpearMastery(),
    new Swordfighting(),
    new WhipMastery(),
    new Icicle(),
    new Windstorm(),
  ];

  static final Map<String, Skill> _byName =
      new Map.fromIterable(all, key: (skill) => skill.name);

  static Skill find(String name) {
    assert(_byName.containsKey(name));
    return _byName[name];
  }
}
