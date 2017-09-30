import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'blob.dart';
import 'lakes.dart';
import 'rivers.dart';
import 'room.dart';
import 'tiles.dart';

enum TileState {
  /// Nothing has been placed on the tile.
  unused,

  /// A natural formation is here, but the dungeon hasn't reached it yet.
  natural,

  /// The tile has been used and is reachable from the starting room.
  reached
}

/// The methods that the various dungeon mixins have access to.
abstract class DungeonBase {
  int get depth;
  int get width;
  int get height;

  Rect get bounds;
  Rect get safeBounds;

  Stage get stage;

  TileType getTile(int x, int y);
  TileType getTileAt(Vec pos);
  void setTile(int x, int y, TileType type, TileState state);

  TileState getState(int x, int y);
  TileState getStateAt(Vec pos);
  bool isUnused(int x, int y);
  void setStateAt(Vec pos, TileState state);

  bool hasCardinalNeighbor(Vec pos, List<TileType> tiles);
  bool hasNeighbor(Vec pos, TileType tile);
}

abstract class Region {
  double intensity(int x, int y);
}

class WaterRegion extends Region {
  static const _maxDistance = 20;

  Array2D<int> _tiles;

  WaterRegion(Stage stage)
      : _tiles = new Array2D(stage.width, stage.height, _maxDistance);

  Iterable<String> generateNature(Dungeon2 dungeon) sync* {
    var hasWater = false;

    if (rng.oneIn(3)) {
      // TODO: Move addRiver() and addLake() into WaterRegion?
      yield* dungeon.addRiver();
      hasWater = true;
    }

    // TODO: Lakes sometimes have unreachable islands in the middle. Should
    // either fill those in, add bridges, give players a way to traverse water,
    // or at least ensure nothing is spawned on them.

    // TODO: Rivers that flow into/from lakes?

    if (hasWater && rng.oneIn(10) || !hasWater && rng.oneIn(5)) {
      yield "Pouring big lake";
      // TODO: 64 is pretty big. Might want to make these a little smaller, but
      // not all the way down to 32.
      dungeon.addLake(Blob.make64());
      hasWater = true;
    }

    if (!hasWater || rng.oneIn(10)) {
      yield "Pouring lake";
      dungeon.addLake(Blob.make32());
      hasWater = true;
    }

    if (rng.oneIn(5)) {
      var ponds = rng.taper(0, 3);
      for (var i = 0; i < ponds; i++) {
        yield "Pouring pond $i/$ponds";
        dungeon.addLake(Blob.make16());
      }
    }

    // Run breadth-first search to find out how far each tile is from water.
    // TODO: This leads to a sort of diamond-like region around the water. An
    // actual blur convolution might work better.
    var queue = new Queue<Vec>();

    for (var pos in dungeon.bounds) {
      // TODO: Handle other kinds of water.
      if (dungeon.getTileAt(pos) == Tiles.water ||
          dungeon.getTileAt(pos) == Tiles.grass) {
        queue.add(pos);
        _tiles[pos] = 0;
      }
    }

    while (queue.isNotEmpty) {
      var pos = queue.removeFirst();
      var distance = _tiles[pos] + 1;
      if (distance >= _maxDistance) continue;

      for (var dir in Direction.cardinal) {
        var neighbor = pos + dir;

        if (!dungeon.bounds.contains(neighbor)) continue;
        if (_tiles[neighbor] != _maxDistance) continue;

        _tiles[neighbor] = distance;
        queue.add(neighbor);
      }
    }

    Dungeon2.region = new Array2D<double>(dungeon.width, dungeon.height, 0.0);
    for (var pos in Dungeon2.region.bounds) {
      Dungeon2.region[pos] = intensity(pos.x, pos.y);
    }
  }

  double intensity(int x, int y) {
    var distance = _tiles.get(x, y);
    if (distance == 0) return 1.0;

    return ((20 - distance) / 20.0).clamp(0.0, 1.0);
  }
}

class Dungeon2 extends Object with Lakes, Rivers, Rooms {
  // TODO: Hack temp. Static so that dungeon_test can access these while it's
  // being generated.
  static Array2D<TileState> currentStates;
  static List<Junction> currentJunctions;

  static Array2D<double> region;

  final Stage stage;
  final int depth;

  final Array2D<TileState> _states;

  Vec _heroPos;

  Rect get bounds => stage.bounds;
  Rect get safeBounds => stage.bounds.inflate(-1);

  int get width => stage.width;
  int get height => stage.height;

  Dungeon2(this.stage, this.depth)
      : _states = new Array2D(stage.width, stage.height, TileState.unused);

  Iterable<String> generate(Function(Vec) placeHero) sync* {
    currentStates = _states;
    currentJunctions = null;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        setTile(x, y, Tiles.rock, TileState.unused);
      }
    }

    // TODO: Random regions based on depth.
    var region = new WaterRegion(stage);
    yield* region.generateNature(this);

    // TODO: Add grottoes other places than just on shores.
    // TODO: Integrate this into regions?
    // Add some old grottoes that eroded before the dungeon was built.
    yield* addGrottoes(rng.taper(2, 3));

    yield* addRooms();

    // Add a few grottoes that have collapsed after rooms. Unlike the above,
    // these may erode into rooms.
    // TODO: It looks weird that these don't place grass on the room floor
    // itself. Probably want to apply grass after everything is carved based on
    // humidity or something.
    // TODO: Should these be flood-filled for reachability?
    yield* addGrottoes(rng.taper(0, 3));

    _heroPos = stage.findOpenTile();
    placeHero(_heroPos);
  }

  TileType getTile(int x, int y) => stage.get(x, y).type;

  TileType getTileAt(Vec pos) => stage[pos].type;

  void setTile(int x, int y, TileType type, TileState state) {
    stage.get(x, y).type = type;
    _states.set(x, y, state);
  }

  TileState getState(int x, int y) => _states.get(x, y);
  TileState getStateAt(Vec pos) => _states[pos];

  bool isUnused(int x, int y) => _states.get(x, y) == TileState.unused;

  void setStateAt(Vec pos, TileState state) {
    _states[pos] = state;
  }

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
}
