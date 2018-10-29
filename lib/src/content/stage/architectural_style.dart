import '../../engine.dart';
import 'architect.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'keep.dart';
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
        double itemDensity,
        Architecture Function() create,
        bool isAquatic}) {
      monsters ??= "monster";

      var style = ArchitecturalStyle(decor, decorDensity, monsters.split(" "),
          monsterDensity, itemDensity, create,
          isAquatic: isAquatic);
      _all.addRanged(style, minDepth: min, maxDepth: max, frequency: frequency);
    }

    // Generic default dungeon style.
    addStyle(
        min: 1,
        max: 100,
        frequency: 10.0,
        decor: "keep",
        decorDensity: 0.05,
        create: () => Keep());

    // TODO: Define more.
    // TODO: Tweak level ranges.
    // TODO: Move catacomb styles with different tile types and tuned params.
    addStyle(
        min: 1,
        max: 100,
        frequency: 2.0,
        decor: "glowing-moss",
        decorDensity: 0.2,
        monsters: "animal bat bug natural",
        create: () => Catacomb());
    addStyle(
        min: 1,
        max: 100,
        frequency: 1.0,
        decor: "glowing-moss",
        decorDensity: 0.3,
        monsters: "animal bat bug natural",
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
        monsters: "animal herp",
        isAquatic: true,
        monsterDensity: 0.0,
        create: () => Lake());
    addStyle(
        min: 1,
        max: 100,
        decor: "water",
        decorDensity: 0.01,
        monsters: "animal herp",
        monsterDensity: 0.0,
        isAquatic: true,
        create: () => River());
  }

  final String decorTheme;
  final double decorDensity;
  final List<String> monsterGroups;
  final double monsterDensity;
  final double itemDensity;
  final Architecture Function() _factory;
  final bool isAquatic;

  ArchitecturalStyle(this.decorTheme, double decorDensity, this.monsterGroups,
      double monsterDensity, double itemDensity, this._factory,
      {bool isAquatic})
      : decorDensity = decorDensity ?? 0.1,
        monsterDensity = monsterDensity ?? 1.0,
        itemDensity = itemDensity ?? 1.0,
        isAquatic = isAquatic ?? false;

  Architecture create(Architect architect, Region region) {
    var architecture = _factory();
    architecture.bind(this, architect, region);
    return architecture;
  }
}
