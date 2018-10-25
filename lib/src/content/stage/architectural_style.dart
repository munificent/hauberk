import '../../engine.dart';
import 'architect.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'dungeon.dart';
import 'lake.dart';
import 'river.dart';

class ArchitecturalStyle {
  static final ResourceSet<ArchitecturalStyle> _all = ResourceSet();

  static ResourceSet<ArchitecturalStyle> get all {
    if (_all.isEmpty) _initialize();
    return _all;
  }

  static void _initialize() {
    _all.defineTags("style");

    addStyle(
        {int depth,
        double frequency,
        String decor,
        String monsters,
        double monsterDensity,
        Architecture Function() create,
        bool isAquatic}) {
      monsters ??= "monster";

      var style = ArchitecturalStyle(
          decor, monsters.split(" "), monsterDensity, create,
          isAquatic: isAquatic);
      _all.addUnnamed(style, depth, frequency, "style");
    }

    // TODO: Monster groups are all temp.
    // TODO: Define more.
    addStyle(
        depth: 1,
        frequency: 2.0,
        decor: "glowing-moss",
        monsters: "jelly bug",
        create: () => Catacomb());
    addStyle(
        depth: 1,
        frequency: 1.0,
        decor: "glowing-moss",
        monsters: "goblin",
        create: () => Cavern());

    addStyle(
        depth: 1,
        frequency: 10.0,
        decor: "dungeon",
        monsters: "fae",
        create: () => Dungeon());
    // TODO: Forest style that uses cavern-like CA to open an organic-shaped
    // area and then fills it with grass and trees. (Maybe just a specific
    // painter for Cavern?

    // TODO: Different liquid types including some that are dry.
    // TODO: Shore or islands?
    addStyle(
        depth: 1,
        frequency: 1.0,
        decor: "water",
        monsters: "animal",
        isAquatic: true,
        monsterDensity: 0.0,
        create: () => Lake());
    addStyle(
        depth: 1,
        frequency: 1.0,
        decor: "water",
        monsters: "animal",
        monsterDensity: 0.0,
        isAquatic: true,
        create: () => River());
  }

  final String decorTheme;
  final List<String> monsterGroups;
  final double monsterDensity;
  final Architecture Function() _factory;
  final bool isAquatic;

  ArchitecturalStyle(
      this.decorTheme, this.monsterGroups, double monsterDensity, this._factory,
      {bool isAquatic})
      : monsterDensity = monsterDensity ?? 1.0,
        isAquatic = isAquatic ?? false;

  Architecture create(Architect architect, Region region) {
    var architecture = _factory();
    architecture.bind(this, architect, region);
    return architecture;
  }
}
