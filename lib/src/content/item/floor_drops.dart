import '../../engine.dart';
import '../themes.dart';
import 'drops.dart';

final ResourceSet<FloorDrop> _floorDrops = ResourceSet();

/// Items that are spawned on the ground when a dungeon is first generated.
class FloorDrops {
  static void initialize() {
    Themes.defineTags(_floorDrops, "drop");

    // Add generic stuff at every depth.

    // TODO: Tune this.
    floorDrop(
        startFrequency: 2.0,
        location: SpawnLocation.wall,
        drop: dropAllOf([
          percentDrop(60, "Skull"),
          percentDrop(40, "treasure"),
          percentDrop(30, "weapon"),
          percentDrop(30, "armor"),
          percentDrop(30, "armor"),
          percentDrop(20, "magic"),
          percentDrop(20, "magic"),
          percentDrop(20, "magic")
        ]));

    floorDrop(
        startFrequency: 20.0,
        location: SpawnLocation.wall,
        drop: percentDrop(30, "magic"));

    floorDrop(startFrequency: 10.0, endFrequency: 1.0, drop: parseDrop("food"));

    floorDrop(
        startFrequency: 5.0,
        endFrequency: 0.01,
        location: SpawnLocation.corner,
        drop: parseDrop("Rock"));

    floorDrop(startFrequency: 10.0, drop: parseDrop("treasure"));

    floorDrop(startFrequency: 4.0, endFrequency: 0.1, drop: parseDrop("light"));

    floorDrop(
        startFrequency: 10.0,
        endFrequency: 0.0,
        location: SpawnLocation.anywhere,
        drop: parseDrop("item"));

    // TODO: Other stuff.
  }

  static FloorDrop choose(int depth) => _floorDrops.tryChoose(depth);
}

class FloorDrop {
  final SpawnLocation location;
  final Drop drop;

  FloorDrop(this.location, this.drop);
}

void floorDrop(
    {double startFrequency,
    double endFrequency,
    SpawnLocation location,
    Drop drop}) {
  location ??= SpawnLocation.anywhere;
  var floorDrop = FloorDrop(location, drop);
  _floorDrops.addRanged(floorDrop,
      start: 1,
      end: 100,
      startFrequency: startFrequency,
      endFrequency: endFrequency);
}
