import '../../engine.dart';
import '../themes.dart';
import 'drops.dart';

final ResourceSet<FloorDrop> _floorDrops = ResourceSet();

/// Items that are spawned on the ground when a dungeon is first generated.
class FloorDrops {
  static void initialize() {
    Themes.defineTags(_floorDrops, "drop");

    // Add generic stuff at every depth.
    for (var i = 1; i <= Option.maxDepth; i++) {
      // TODO: Tune this.
      floorDrop(
          depth: i,
          frequency: 2.0,
          location: SpawnLocation.wall,
          drop: dropAllOf([
            percentDrop(60, "Skull", i),
            percentDrop(40, "treasure", i),
            percentDrop(30, "weapon", i),
            percentDrop(30, "armor", i),
            percentDrop(30, "armor", i),
            percentDrop(20, "magic", i),
            percentDrop(20, "magic", i),
            percentDrop(20, "magic", i)
          ]));

      floorDrop(
          theme: "laboratory",
          depth: i,
          frequency: 20.0,
          location: SpawnLocation.wall,
          drop: percentDrop(30, "magic", i));

      floorDrop(
          theme: "food",
          depth: i,
          frequency: lerpDouble(i, 1, 100, 10.0, 1.0),
          drop: parseDrop("food", i));

      floorDrop(
          depth: i,
          frequency: lerpDouble(i, 1, 100, 5.0, 0.01),
          location: SpawnLocation.corner,
          drop: parseDrop("Rock", i));

      floorDrop(
          depth: i,
          frequency: 10.0,
          drop: parseDrop("treasure", i));

      floorDrop(
          depth: i,
          frequency: lerpDouble(i, 1, 100, 4.0, 0.1),
          drop: parseDrop("light", i));
    }

    floorDrop(
        depth: 1,
        frequency: 50.0,
        location: SpawnLocation.anywhere,
        drop: parseDrop("item", 1));

    // TODO: Other stuff.
  }

  static FloorDrop choose(String theme, int depth) =>
      _floorDrops.tryChoose(depth, theme);
}

class FloorDrop {
  final SpawnLocation location;
  final Drop drop;

  FloorDrop(this.location, this.drop);
}

void floorDrop(
    {String theme,
    int depth,
    double frequency,
    SpawnLocation location,
    Drop drop}) {
  theme ??= "drop";
  frequency ??= 1.0;
  location ??= SpawnLocation.anywhere;
  var floorDrop = FloorDrop(location, drop);
  _floorDrops.addUnnamed(floorDrop, depth, frequency, theme);
}
