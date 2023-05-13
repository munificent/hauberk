import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'architect.dart';
import 'builder.dart';
import 'room.dart';

class ArchitecturalStyle {
  static final ResourceSet<ArchitecturalStyle> styles = ResourceSet();

  static void initialize() {
    // Generic default dungeon styles.
    dungeon(RoomShapes.rectangular, frequency: 6.0);
    dungeon(RoomShapes.octagonal, frequency: 1.0);
    dungeon(RoomShapes.any, frequency: 3.0);

    // TODO: Decide if we should ever do full-size keeps anymore.
//    addStyle("keep",
//        startFrequency: 2.0,
//        endFrequency: 5.0,
//        decor: "keep",
//        decorDensity: 0.07,
//        create: () => Keep());

    // TODO: Define more.
    // TODO: More catacomb styles with different tile types and tuned params.
    catacomb("bat bug humanoid natural",
        startFrequency: 1.0, endFrequency: 2.0);
    cavern("animal bat bug natural", startFrequency: 0.2, endFrequency: 1.0);

    // TODO: Forest style that uses cavern-like CA to open an organic-shaped
    // area and then fills it with grass and trees. (Maybe just a specific
    // painter for Cavern?

    // TODO: Different liquid types including some that are dry.
    // TODO: Shore or islands?
    lake("animal herp", start: 1, end: 100);
    river("animal herp", start: 1, end: 100);

    // Pits.
    pit("bug", start: 1, end: 40);
    pit("jelly", start: 5, end: 50);
    pit("bat", start: 10, end: 40);
    pit("rodent", start: 1, end: 50);
    pit("snake", start: 8, end: 60);
    pit("plant", start: 15, end: 40);
    pit("eye", start: 20, end: 100);
    pit("dragon", start: 60, end: 100);

    // Keeps.
    keep("kobold", start: 2, end: 16);
    keep("goblin", start: 5, end: 23);
    keep("saurian", start: 10, end: 30);
    keep("orc", start: 28, end: 40);
    // TODO: More.
  }

  static List<ArchitecturalStyle> pick(int depth) {
    var result = <ArchitecturalStyle>[];

    // TODO: Change count range based on depth?
    var count = math.min(rng.taper(1, 10), 5);
    var hasFillable = false;

    while (!hasFillable || result.length < count) {
      var style = styles.tryChoose(depth)!;

      // Make sure there's at least one style that can fill the entire stage.
      if (style.canFill) hasFillable = true;

      if (!result.contains(style)) result.add(style);
    }

    return result;
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
      double? decorDensity,
      this.monsterGroups,
      double? monsterDensity,
      double? itemDensity,
      this._factory,
      {bool? canFill})
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
