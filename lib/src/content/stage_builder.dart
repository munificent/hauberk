library content.stage_builder;

import '../engine.dart';
import '../util.dart';
import 'tiles.dart';

abstract class StageBuilder {
  Stage stage;

  void generate(Stage stage);

  void bindStage(Stage stage) {
    this.stage = stage;
  }

  TileType getTile(Vec pos) => stage[pos].type;

  void setTile(Vec pos, TileType type) {
    stage[pos].type = type;
  }

  void fill(TileType tile) {
    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        setTile(new Vec(x, y), tile);
      }
    }
  }

  /// Randomly turns some [floor] tiles into [wall] and vice versa. Does so
  /// while maintaining the reachability invariant of the dungeon.
  void erode(int iterations, {TileType floor, TileType wall}) {
    if (floor == null) floor = Tiles.floor;
    if (wall == null) wall = Tiles.wall;

    final bounds = stage.bounds.inflate(-1);
    for (var i = 0; i < iterations; i++) {
      final pos = rng.vecInRect(bounds);

      final here = getTile(pos);
      if (here != floor && here != wall) continue;

      bool canChange = true;

      // Keep track of how many walls we're adjacent too. We will only fill in
      // if we are directly next to a wall.
      var walls = 0;

      // As we go around the tile's neighbors, keep track of how many times we
      // switch from wall to floor. We can fill in a tile only if it is next to
      // a single unbroken expanse of walls. If it is next to two
      // non-contiguous wall sections, then filling it in may break the
      // reachability of the dungeon.
      var inWall;
      var transitions = 0;

      for (var dir in Direction.ALL) {
        var tile = getTile(pos + dir);
        if (tile == floor) {
          if (inWall == true) transitions++;
          inWall = false;
        } else if (tile == wall) {
          walls++;
          if (inWall == false) transitions++;
          inWall = true;
        } else {
          // Don't modify next to "special" features.
          canChange = false;
          break;
        }

        if (transitions > 2) {
          canChange = false;
          break;
        }
      }

      if (!canChange) continue;

      if (here == floor) {
        if (walls > 3 ||
            (walls == 3 && rng.oneIn(4)) ||
            (walls == 2 && rng.oneIn(8))) setTile(pos, wall);
      } else {
        if (walls < 5 ||
            (walls == 5 && rng.oneIn(4)) ||
            (walls == 6 && rng.oneIn(8))) setTile(pos, floor);
      }
    }
  }

  /// Randomly turns some [wall] tiles into [floor] and vice versa.
  void erodeWalls(int iterations, {TileType floor, TileType wall}) {
    if (floor == null) floor = Tiles.floor;
    if (wall == null) wall = Tiles.wall;

    final bounds = stage.bounds.inflate(-1);
    for (var i = 0; i < iterations; i++) {
      final pos = rng.vecInRect(bounds);

      final here = getTile(pos);
      if (here != wall) continue;

      // Keep track of how many floors we're adjacent too. We will only erode
      // if we are directly next to a floor.
      var floors = 0;

      for (var dir in Direction.ALL) {
        var tile = getTile(pos + dir);
        if (tile == floor) floors++;
      }

      if (floors == 0) continue;

      // Prefer not to erode tiles that are only touching a single floor so we
      // don't get lots of narrow cracks.
      if (floors > 1 || rng.oneIn(4)) {
        setTile(pos, floor);
      }
    }
  }
}
