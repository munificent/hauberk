import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'blob.dart';
import 'grotto.dart';
import 'lake.dart';
import 'river.dart';
import 'room.dart';

abstract class Biome {
  Iterable<String> generate(Dungeon dungeon);
}

// TODO: Figure out how we want to do the region stuff around water.
//class WaterBiome extends Biome {
//  static const _maxDistance = 20;
//
//  Array2D<int> _tiles;
//
//    // Run breadth-first search to find out how far each tile is from water.
//    // TODO: This leads to a sort of diamond-like region around the water. An
//    // actual blur convolution might work better.
//    var queue = new Queue<Vec>();
//
//    for (var pos in dungeon.bounds) {
//      // TODO: Handle other kinds of water.
//      if (dungeon.getTileAt(pos) == Tiles.water ||
//          dungeon.getTileAt(pos) == Tiles.grass) {
//        queue.add(pos);
//        _tiles[pos] = 0;
//      }
//    }
//
//    while (queue.isNotEmpty) {
//      var pos = queue.removeFirst();
//      var distance = _tiles[pos] + 1;
//      if (distance >= _maxDistance) continue;
//
//      for (var dir in Direction.cardinal) {
//        var neighbor = pos + dir;
//
//        if (!dungeon.bounds.contains(neighbor)) continue;
//        if (_tiles[neighbor] != _maxDistance) continue;
//
//        _tiles[neighbor] = distance;
//        queue.add(neighbor);
//      }
//    }
//  }
//
//  double intensity(int x, int y) {
//    var distance = _tiles.get(x, y);
//    if (distance == 0) return 1.0;
//
//    return ((20 - distance) / 20.0).clamp(0.0, 1.0);
//  }
//}

class Dungeon {
  // TODO: Hack temp. Static so that dungeon_test can access these while it's
  // being generated.
  static List<Junction> debugJunctions;

  final Stage stage;
  final int depth;

  final List<Biome> _biomes = [];

  Vec _heroPos;

  Rect get bounds => stage.bounds;
  Rect get safeBounds => stage.bounds.inflate(-1);

  int get width => stage.width;
  int get height => stage.height;

  Dungeon(this.stage, this.depth);

  Iterable<String> generate(Function(Vec) placeHero) sync* {
    debugJunctions = null;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        setTile(x, y, Tiles.rock);
      }
    }

    _chooseBiomes();

    for (var biome in _biomes) {
      yield* biome.generate(this);
    }

    // If a biome didn't place the hero, do it now.
    if (_heroPos == null) _heroPos = stage.findOpenTile();
    placeHero(_heroPos);
  }

  TileType getTile(int x, int y) => stage.get(x, y).type;

  TileType getTileAt(Vec pos) => stage[pos].type;

  void setTile(int x, int y, TileType type) {
    stage.get(x, y).type = type;
  }

  void setTileAt(Vec pos, TileType type) {
    stage[pos].type = type;
  }

  bool isRock(int x, int y) => stage.get(x, y).type == Tiles.rock;
  bool isRockAt(Vec pos) => stage[pos].type == Tiles.rock;

  /// Returns `true` if the cell at [pos] has at least one adjacent tile with
  /// type [tile].
  bool hasCardinalNeighbor(Vec pos, List<TileType> tiles) {
    for (var dir in Direction.cardinal) {
      var neighbor = pos + dir;
      if (!safeBounds.contains(neighbor)) continue;

      if (tiles.contains(stage[neighbor].type)) return true;
    }

    return false;
  }

  /// Returns `true` if the cell at [pos] has at least one adjacent tile with
  /// type [tile].
  bool hasNeighbor(Vec pos, TileType tile) {
    for (var dir in Direction.all) {
      var neighbor = pos + dir;
      if (!safeBounds.contains(neighbor)) continue;

      if (stage[neighbor].type == tile) return true;
    }

    return false;
  }

  void placeHero(Vec pos) {
    assert(_heroPos == null, "Should only place the hero once.");
    _heroPos = pos;
  }

  /// Grows a randomly shaped blob starting at [start].
  ///
  /// Tries to add approximately [size] tiles of type [tile] that are directly
  /// attached to the starting tile. Only grows through tiles of [allowed]
  /// types. The larger [smoothing] is, the less jagged and spidery the blobs
  /// will be.
  void growSeed(List<Vec> starts, int size, int smoothing, TileType tile) {
    var edges = new Set<Vec>();

    addNeighbors(Vec pos) {
      for (var dir in Direction.cardinal) {
        var neighbor = pos + dir;
        if (!safeBounds.contains(neighbor)) continue;

        // TODO: Allow passing in the tile types that can be grown into.
        var type = getTileAt(neighbor);
        if (type != Tiles.wall && type != Tiles.rock) continue;
        edges.add(neighbor);
      }
    }

    scorePos(Vec pos) {
      var score = 0;

      // Count straight neighbors higher to discourage diagonal growth.
      for (var dir in Direction.cardinal) {
        var neighbor = pos + dir;
        if (getTileAt(neighbor) == tile) score += 2;
      }

      for (var dir in Direction.intercardinal) {
        var neighbor = pos + dir;
        if (getTileAt(neighbor) == tile) score++;
      }

      return score;
    }

    starts.forEach(addNeighbors);

    var count = rng.triangleInt(size, size ~/ 2);
    while (edges.isNotEmpty && count > 0) {
      var edgeList = edges.toList();
      var best = <Vec>[];
      var bestScore = -1;

      // Pick a number of potential tiles to grow into and choose the least
      // jagged option -- the one with the most neighbors that are already
      // grown.
      for (var i = 0; i < smoothing; i++) {
        var pos = rng.item(edgeList);
        var score = scorePos(pos);

        if (score > bestScore) {
          best = [pos];
          bestScore = score;
        } else if (score == bestScore) {
          best.add(pos);
        }
      }

      var pos = rng.item(best);
      setTile(pos.x, pos.y, tile);
      addNeighbors(pos);
      edges.remove(pos);

      count--;
    }
  }

  void _chooseBiomes() {
    // TODO: Take depth into account?
    var hasWater = false;

    if (rng.oneIn(3)) {
      _biomes.add(new RiverBiome());
      hasWater = true;
    }

    if (hasWater && rng.oneIn(20) || !hasWater && rng.oneIn(10)) {
      // TODO: 64 is pretty big. Might want to make these a little smaller, but
      // not all the way down to 32.
      _biomes.add(new LakeBiome(Blob.make64()));
      hasWater = true;
    }

    if (hasWater && rng.oneIn(10) || !hasWater && rng.oneIn(5)) {
      _biomes.add(new LakeBiome(Blob.make32()));
      hasWater = true;
    }

    if (rng.oneIn(5)) {
      var ponds = rng.taper(0, 3);
      for (var i = 0; i < ponds; i++) {
        _biomes.add(new LakeBiome(Blob.make16()));
      }
    }

    // TODO: Add grottoes other places than just on shores.
    // Add some old grottoes that eroded before the dungeon was built.
    if (hasWater) _biomes.add(new GrottoBiome(rng.taper(2, 3)));

    _biomes.add(new RoomBiome(this));

    // Add a few grottoes that have collapsed after rooms. Unlike the above,
    // these may erode into rooms.
    // TODO: It looks weird that these don't place grass on the room floor
    // itself. Probably want to apply grass after everything is carved based on
    // humidity or something.
    // TODO: Should these be flood-filled for reachability?
    if (hasWater && rng.oneIn(3)) {
      _biomes.add(new GrottoBiome(rng.taper(1, 3)));
    }
  }
}
