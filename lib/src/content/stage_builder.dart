library hauberk.content.stage_builder;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
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

  /// Randomly turns some [wall] tiles into [floor] and vice versa.
  void erode(int iterations, {TileType floor, TileType wall}) {
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
