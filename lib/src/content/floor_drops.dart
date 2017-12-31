import 'dart:math' as math;

import '../engine.dart';
import 'drops.dart';

final ResourceSet<FloorDrop> _floorDrops = new ResourceSet();

/// Items that are spawned on the ground when a dungeon is first generated.
class FloorDrops {
  static void initialize() {
    _floorDrops.defineTags("drop");

    // Add generic stuff at every depth.
    for (var i = 1; i <= 100; i++) {
      // TODO: Tune this.
      floorDrop(
          depth: i,
          frequency: 2.0,
          location: SpawnLocation.wall,
          drop: dropAllOf([
            percentDrop(60, "Skull", i),
            percentDrop(30, "weapon", i),
            percentDrop(30, "armor", i),
            percentDrop(30, "armor", i),
            percentDrop(30, "magic", i),
            percentDrop(30, "magic", i),
            percentDrop(30, "magic", i)
          ]));

      var rockFrequency = 10.0 / (1.0 + i);
      floorDrop(
          depth: i,
          frequency: rockFrequency,
          location: SpawnLocation.corner,
          drop: parseDrop("Rock", i));

      var lightFrequency = math.max(2.0, 10.0 - i / 4);
      floorDrop(
          depth: i,
          frequency: lightFrequency,
          drop: parseDrop("light", i));
    }

    floorDrop(
        depth: 1,
        frequency: 50.0,
        location: SpawnLocation.anywhere,
        drop: parseDrop("item", 1));

    // TODO: Other stuff.
  }

  static FloorDrop choose(int depth) => _floorDrops.tryChoose(depth, "drop");
}

class FloorDrop {
  final SpawnLocation location;
  final Drop drop;

  FloorDrop(this.location, this.drop);
}

void floorDrop(
    {int depth, double frequency, SpawnLocation location, Drop drop}) {
  var encounter = new FloorDrop(location ?? SpawnLocation.anywhere, drop);
  _floorDrops.addUnnamed(encounter, depth, frequency ?? 1.0, "drop");
}
