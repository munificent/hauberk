import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'drops.dart';
import 'dungeon/dungeon.dart';

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

      // TODO: Rarer at greater depths?
      var rockRarity = 1 + i ~/ 10;
      floorDrop(
          depth: i,
          rarity: rockRarity,
          location: SpawnLocation.corner,
          drop: parseDrop("Rock", i));
      floorDrop(
          depth: i,
          rarity: rockRarity,
          location: SpawnLocation.grass,
          drop: parseDrop("Rock", i));
    }

    // TODO: Other stuff.
  }

  static FloorDrop choose(int depth) => _floorDrops.tryChoose(depth, "drop");
}

class FloorDrop {
  final SpawnLocation _location;
  final Drop _drop;

  FloorDrop(this._location, this._drop);

  void spawn(Dungeon dungeon) {
    var encounterPos = dungeon.findSpawnTile(_location);

    // TODO: Mostly copied from Monster.onDied(). Refactor.
    // Try to keep dropped items from overlapping.
    var flow = new Flow(dungeon.stage, encounterPos,
        canOpenDoors: false, ignoreActors: true);

    _drop.spawnDrop((item) {
      var itemPos = encounterPos;
      if (dungeon.stage.isItemAt(itemPos)) {
        itemPos = flow.nearestWhere((pos) {
          if (rng.oneIn(5)) return true;
          return !dungeon.stage.isItemAt(pos);
        });

        if (itemPos == null) itemPos = encounterPos;
      }

      dungeon.stage.addItem(item, itemPos);
    });
  }
}

void floorDrop({int depth, int rarity, SpawnLocation location, Drop drop}) {
  var encounter = new FloorDrop(location, drop);
  _floorDrops.addUnnamed(encounter, depth, rarity ?? 1, "drop");
}
