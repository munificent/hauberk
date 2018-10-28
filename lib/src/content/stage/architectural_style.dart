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
    addStyle(
        {int min,
        int max,
        double frequency,
        String decor,
        double decorDensity,
        String monsters,
        double monsterDensity,
        Architecture Function() create,
        bool isAquatic}) {
      monsters ??= "monster";

      var style = ArchitecturalStyle(
          decor, decorDensity, monsters.split(" "), monsterDensity, create,
          isAquatic: isAquatic);
      _all.addRanged(style, minDepth: min, maxDepth: max, frequency: frequency);
    }

    // Generic default dungeon style.
    addStyle(
        min: 1,
        max: 100,
        frequency: 10.0,
        decor: "dungeon",
        create: () => Dungeon());

    // TODO: Monster groups are all temp.
    // TODO: Define more.
    // TODO: Tweak level ranges.
    addStyle(
        min: 1,
        max: 100,
        frequency: 2.0,
        decor: "glowing-moss",
        decorDensity: 0.2,
        monsters: "jelly bug",
        create: () => Catacomb());
    addStyle(
        min: 1,
        max: 100,
        frequency: 1.0,
        decor: "glowing-moss",
        decorDensity: 0.3,
        monsters: "goblin",
        create: () => Cavern());

    // TODO: Forest style that uses cavern-like CA to open an organic-shaped
    // area and then fills it with grass and trees. (Maybe just a specific
    // painter for Cavern?

    // TODO: Different liquid types including some that are dry.
    // TODO: Shore or islands?
    addStyle(
        min: 1,
        max: 100,
        decor: "water",
        decorDensity: 0.01,
        monsters: "animal",
        isAquatic: true,
        monsterDensity: 0.0,
        create: () => Lake());
    addStyle(
        min: 1,
        max: 100,
        decor: "water",
        decorDensity: 0.01,
        monsters: "animal",
        monsterDensity: 0.0,
        isAquatic: true,
        create: () => River());
  }

  final String decorTheme;
  final double decorDensity;
  final List<String> monsterGroups;
  final double monsterDensity;
  final Architecture Function() _factory;
  final bool isAquatic;

  ArchitecturalStyle(this.decorTheme, double decorDensity, this.monsterGroups,
      double monsterDensity, this._factory,
      {bool isAquatic})
      : decorDensity = decorDensity ?? 0.1,
        monsterDensity = monsterDensity ?? 1.0,
        isAquatic = isAquatic ?? false;

  Architecture create(Architect architect, Region region) {
    var architecture = _factory();
    architecture.bind(this, architect, region);
    return architecture;
  }
}
