import '../../engine.dart';
import 'architect.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'dungeon.dart';
import 'keep.dart';
import 'lake.dart';
import 'pit.dart';
import 'river.dart';

class ArchitecturalStyle {
  static final ResourceSet<ArchitecturalStyle> _all = ResourceSet();

  static ResourceSet<ArchitecturalStyle> get all {
    if (_all.isEmpty) _initialize();
    return _all;
  }

  static void _initialize() {
    addStyle(
        {int start = 1,
        int end = 100,
        double frequency,
        String decor,
        double decorDensity,
        String monsters,
        double monsterDensity,
        double itemDensity,
        Architecture Function() create,
        bool canFill}) {
      monsters ??= "monster";

      var style = ArchitecturalStyle(decor, decorDensity, monsters.split(" "),
          monsterDensity, itemDensity, create,
          canFill: canFill);
      // TODO: Ramp frequencies?
      _all.addRanged(style, start: start, end: end, startFrequency: frequency);
    }

    // Generic default dungeon style.
    addStyle(
        frequency: 10.0,
        decor: "dungeon",
        decorDensity: 0.07,
        create: () => Dungeon());

    // Generic default dungeon style.
    addStyle(
        frequency: 5.0,
        decor: "keep",
        decorDensity: 0.07,
        create: () => Keep());

    // TODO: Define more.
    // TODO: Tweak level ranges.
    // TODO: Move catacomb styles with different tile types and tuned params.
    addStyle(
        frequency: 2.0,
        decor: "catacomb",
        decorDensity: 0.02,
        monsters: "bat bug humanoid natural",
        create: () => Catacomb());
    addStyle(
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
        decor: "water",
        decorDensity: 0.01,
        monsters: "animal herp",
        canFill: false,
        monsterDensity: 0.0,
        create: () => Lake());
    addStyle(
        decor: "water",
        decorDensity: 0.01,
        monsters: "animal herp",
        monsterDensity: 0.0,
        canFill: false,
        create: () => River());

    // Pits.
    pit(String monsterGroup, {int start, int end}) {
      addStyle(
          start: start,
          end: end,
          frequency: 0.2,
          // TODO: Different decor?
          decor: "glowing-moss",
          decorDensity: 0.05,
          canFill: false,
          create: () => Pit(monsterGroup));
    }

    pit("bug", start: 1, end: 40);
    pit("jelly", start: 5, end: 50);
    pit("bat", start: 10, end: 40);
    pit("rodent", start: 1, end: 50);
    pit("snake", start: 8, end: 60);
    pit("plant", start: 15, end: 40);
    pit("eye", start: 20, end: 100);
    pit("dragon", start: 60, end: 100);
  }

  final String decorTheme;
  final double decorDensity;
  final List<String> monsterGroups;
  final double monsterDensity;
  final double itemDensity;
  final Architecture Function() _factory;
  final bool canFill;

  ArchitecturalStyle(this.decorTheme, double decorDensity, this.monsterGroups,
      double monsterDensity, double itemDensity, this._factory,
      {bool canFill})
      : decorDensity = decorDensity ?? 0.1,
        monsterDensity = monsterDensity ?? 1.0,
        itemDensity = itemDensity ?? 1.0,
        canFill = canFill ?? true;

  Architecture create(Architect architect, Region region) {
    var architecture = _factory();
    architecture.bind(this, architect, region);
    return architecture;
  }
}
