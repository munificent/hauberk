import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

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
  static final ResourceSet<ArchitecturalStyle> _styles = ResourceSet();

  static ResourceSet<ArchitecturalStyle> get styles {
    if (_styles.isEmpty) _initialize();
    return _styles;
  }

  static List<ArchitecturalStyle> pick(int depth) {
    if (_styles.isEmpty) _initialize();

    var result = <ArchitecturalStyle>[];

    // TODO: Change count range based on depth?
    var count = math.min(rng.taper(1, 10), 5);
    var hasFillable = false;

    while (!hasFillable || result.length < count) {
      var style = _styles.tryChoose(depth);

      // Make sure there's at least one style that can fill the entire stage.
      if (style.canFill) hasFillable = true;

      if (!result.contains(style)) result.add(style);
    }

    return result;
  }

  static void _initialize() {
    addStyle(String name,
        {int start = 1,
        int end = 100,
        double startFrequency,
        double endFrequency,
        String decor,
        double decorDensity,
        String monsters,
        double monsterDensity,
        double itemDensity,
        Architecture Function() create,
        bool canFill}) {
      monsters ??= "monster";

      var style = ArchitecturalStyle(name, decor, decorDensity,
          monsters.split(" "), monsterDensity, itemDensity, create,
          canFill: canFill);
      // TODO: Ramp frequencies?
      _styles.addRanged(style,
          start: start,
          end: end,
          startFrequency: startFrequency,
          endFrequency: endFrequency);
    }

    // Generic default dungeon style.
    addStyle("dungeon",
        startFrequency: 10.0,
        decor: "dungeon",
        decorDensity: 0.09,
        create: () => Dungeon());

    // TODO: Decide if we should ever do full-size keeps anymore.
    // Generic default dungeon style.
//    addStyle("keep",
//        startFrequency: 2.0,
//        endFrequency: 5.0,
//        decor: "keep",
//        decorDensity: 0.07,
//        create: () => Keep());

    // TODO: Define more.
    // TODO: More catacomb styles with different tile types and tuned params.
    addStyle("catacomb",
        startFrequency: 1.0,
        endFrequency: 2.0,
        decor: "catacomb",
        decorDensity: 0.02,
        monsters: "bat bug humanoid natural",
        create: () => Catacomb());
    addStyle("cavern",
        startFrequency: 0.2,
        endFrequency: 1.0,
        decor: "glowing-moss",
        decorDensity: 0.3,
        monsters: "animal bat bug natural",
        create: () => Cavern());

    // TODO: Forest style that uses cavern-like CA to open an organic-shaped
    // area and then fills it with grass and trees. (Maybe just a specific
    // painter for Cavern?

    // TODO: Different liquid types including some that are dry.
    // TODO: Shore or islands?
    addStyle("lake",
        decor: "water",
        decorDensity: 0.01,
        monsters: "animal herp",
        canFill: false,
        monsterDensity: 0.0,
        create: () => Lake());
    addStyle("river",
        decor: "water",
        decorDensity: 0.01,
        monsters: "animal herp",
        monsterDensity: 0.0,
        canFill: false,
        create: () => River());

    // Pits.
    pit(String monsterGroup, {int start, int end}) {
      addStyle("$monsterGroup pit",
          start: start,
          end: end,
          startFrequency: 0.2,
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

    // Keeps.
    keep(String monsters, {int start, int end}) {
      addStyle("$monsters keep",
          start: start,
          end: end,
          startFrequency: 2.0,
          decor: "keep",
          decorDensity: 0.07,
          monsters: monsters,
          // Keep spawns monsters itself.
          monsterDensity: 0.0,
          itemDensity: 1.5,
          canFill: false,
          create: () => Keep(5));
    }

    keep("goblin", start: 3, end: 16);
    // TODO: More.
  }

  final String name;
  final String decorTheme;
  final double decorDensity;
  final List<String> monsterGroups;
  final double monsterDensity;
  final double itemDensity;
  final Architecture Function() _factory;
  final bool canFill;

  ArchitecturalStyle(
      this.name,
      this.decorTheme,
      double decorDensity,
      this.monsterGroups,
      double monsterDensity,
      double itemDensity,
      this._factory,
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
