import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'blob.dart';

// TODO: This isn't used yet, but I'm leaving it here as a sketch so that I
// don't forget the idea. Brian Walker of Brogue pointed out that one way to
// generate a random path between two points is:
//
// 1. Fill the area between them with open space.
// 2. Randomly pick tiles. If filling in the tile doesn't cause one point to be
//    unreachable from the other, leave it filled. Otherwise leave it open.
// 3. Repeat with every open tile.
//
// At the end, you'll get a single, narrow meandering path.
//
// This generalizes to any number of points and creates a really cool, organic
// set of winding branching paths between them all. This could be useful for
// generating passages in a dungeon, or generating passages between caves in a
// cavern theme. Basically:
//
// 1. Fill the dungeon with open "fillable" tiles.
//
// 2. Place non-overlapping blobs. For each one, trace its outline and cut open
//    a couple of doors. Mark the floor as open but non-fillable.
//
// 3. Then randomly iterate through the fillable tiles. If filling it does not
//    make any cave unreachable from the others, leave it filled.
//
// This class here just draws a network of paths between 40 random points.
class Cavern {
  final Stage stage;

  int get width => stage.width;

  int get height => stage.height;

  Cavern(this.stage);

  Iterable<String> generate(Function(Vec) placeHero) sync* {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        _setTile(x, y, Tiles.grass);
      }
    }

    for (var x = 0; x < width; x++) {
      _setTile(x, 0, Tiles.rock);
      _setTile(x, height - 1, Tiles.rock);
    }

    for (var y = 0; y < height; y++) {
      _setTile(0, y, Tiles.rock);
      _setTile(width - 1, y, Tiles.rock);
    }

    for (var i = 0; i < 100; i++) {
      var cave = rng.oneIn(10) ? Blob.make32() : Blob.make16();
      for (var j = 0; j < 400; j++) {
        // Blobs tend to have unused space on the sides, so allow the position
        // to leak past the edge.
        var x = rng.range(-8, width - cave.width + 16);
        var y = rng.range(-8, height - cave.height + 16);

        if (_tryPlaceCave(cave, x, y)) {
          yield "cave";
          break;
        }
      }
    }

    var caveTiles = <Vec>[];
    var openTiles = <Vec>[];
    for (var pos in stage.bounds) {
      var tile = _getTileAt(pos);
      if (tile == Tiles.floor) {
        caveTiles.add(pos);
      } else if (tile == Tiles.grass) {
        openTiles.add(pos);
      }
    }

    rng.shuffle(caveTiles);
    rng.shuffle(openTiles);

    var start = caveTiles.first;
    placeHero(caveTiles.first);

    for (var pos in openTiles) {
      // We may have already processed it.
      if (_getTileAt(pos) != Tiles.grass) continue;

      // Try to fill this tile.
      _setTileAt(pos, Tiles.rock);

      // Simple optimization: A tile with 0, 1, 7, or 8 solid tiles next to it
      // can't possibly break a path.
      var solidNeighbors = 0;
      for (var dir in Direction.all) {
        if (!_getTileAt(pos + dir).isTraversable) {
          solidNeighbors++;
        }
      }

      // If there is zero or one solid neighbor, you can walk around the tile.
      if (solidNeighbors <= 1) continue;

      // If there are sever or eight solid neighbors, it's already a cul-de-sac.
      if (solidNeighbors >= 7) continue;

      // See if we can still reach all the cave tiles.
      var reachedCave = 0;
      var flow = CardinalFlow(stage, start);
      for (var reached in flow.reachable) {
        if (_getTileAt(reached) == Tiles.floor) {
          reachedCave++;
        }
      }

      // Make sure we can reach every other seed from the starting one.
      // -1 to not count the starting seed.
      if (reachedCave != caveTiles.length - 1) {
        _setTileAt(pos, Tiles.dirt);
      } else {
        // Optimization: Since we've already calculated the reachability to
        // everything, we can also eagerly fill in fillable regions that are
        // already cut off from the caves and passages.
        for (var pos in stage.bounds.inflate(-1)) {
          if (_getTileAt(pos) == Tiles.grass && flow.costAt(pos) == null) {
            _setTileAt(pos, Tiles.rock);
          }
        }
      }

      yield "$pos";
    }
  }

  bool _tryPlaceCave(Array2D<bool> cave, int x, int y) {
    for (var pos in cave.bounds) {
      var here = pos.offset(x, y);

      if (cave[pos]) {
        if (!stage.bounds.contains(here)) return false;
        if (_getTileAt(here) == Tiles.floor) return false;

        for (var dir in Direction.all) {
          var neighbor = here + dir;
          if (!stage.bounds.contains(neighbor)) return false;
          if (_getTileAt(neighbor) == Tiles.floor) return false;
        }
      }
    }

    for (var pos in cave.bounds) {
      if (cave[pos]) _setTile(pos.x + x, pos.y + y, Tiles.floor);
    }

    return true;
  }

  TileType _getTile(int x, int y) => stage.get(x, y).type;

  TileType _getTileAt(Vec pos) => stage[pos].type;

  void _setTile(int x, int y, TileType type) {
    stage.get(x, y).type = type;
  }

  void _setTileAt(Vec pos, TileType type) {
    stage[pos].type = type;
  }
}

/// A basic [Flow] implementation that flows through any tile permitting one of
/// a given [Motility].
class CardinalFlow extends Flow {
  bool get includeDiagonals => false;

  CardinalFlow(Stage stage, Vec start) : super(stage, start);

  /// The cost to enter [tile] at [pos] or `null` if the tile cannot be entered.
  int tileCost(int parentCost, Vec pos, Tile tile, bool isDiagonal) {
    // Can't enter impassable tiles.
    if (!tile.canEnter(Motility.walk)) return null;

    return 1;
  }
}
