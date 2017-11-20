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
          rarity: 2,
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

      var rockRarity = 1 + i ~/ 10;
      floorDrop(
          depth: i,
          rarity: rockRarity,
          location: SpawnLocation.corner,
          drop: parseDrop("Rock", i));
    }

    // TODO: Other stuff.
  }

  static FloorDrop choose(int depth) => _floorDrops.tryChoose(depth, "drop");
}

class FloorDrop {
  final SpawnLocation location;
  final Drop drop;

  FloorDrop(this.location, this.drop);
}

void floorDrop({int depth, int rarity, SpawnLocation location, Drop drop}) {
  var encounter = new FloorDrop(location, drop);
  _floorDrops.addUnnamed(encounter, depth, rarity ?? 1, "drop");
}
