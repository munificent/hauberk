import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'dungeon2.dart';
import 'tiles.dart';

/// Mixin for [Dungeon2] that adds support for lakes, ponds, and grottoes.
abstract class Lakes implements DungeonBase {
  Iterable<String> addGrottoes(int count) sync* {
    if (count == 0) return;

    for (var i = 0; i < 200; i++) {
      var pos = rng.vecInRect(safeBounds);
      // TODO: Handle different shore types.
      if (getTileAt(pos) == Tiles.grass &&
          hasCardinalNeighbor(pos, [Tiles.wall, Tiles.rock])) {
        yield "Carving grotto";
        // TODO: Different sizes and smoothness.
        _growSeed([pos], 30, 3, Tiles.grass);
        if (--count == 0) break;
      }
    }
  }

  void addLake(Array2D<bool> cells) {
    // Try to find a place to drop it.
    for (var i = 0; i < 100; i++) {
      var x = rng.range(0, width - cells.width);
      var y = rng.range(0, height - cells.height);

      // See if the lake overlaps anything.
      var canPlace = true;
      for (var pos in cells.bounds) {
        if (cells[pos]) {
          if (!isUnused(pos.x + x, pos.y + y)) {
            canPlace = false;
            break;
          }
        }
      }

      if (!canPlace) continue;

      // We found a spot, carve the water.
      for (var pos in cells.bounds) {
        if (cells[pos]) {
          setTile(pos.x + x, pos.y + y, Tiles.water, TileState.natural);
        }
      }

      // Grow a shoreline.
      var edges = <Vec>[];
      var shoreBounds =
      Rect.intersect(cells.bounds.offset(x, y), safeBounds);
      for (var pos in shoreBounds) {
        if (isUnused(pos.x, pos.y) && hasNeighbor(pos, Tiles.water)) {
          setTile(pos.x, pos.y, Tiles.grass, TileState.natural);
          edges.add(pos);
        }
      }

      _growSeed(edges, edges.length, 4, Tiles.grass);
      return;
    }
  }

  /// Grows a randomly shaped blob starting at [start].
  ///
  /// Tries to add approximately [size] tiles of type [tile] that are directly
  /// attached to the starting tile. Only grows through tiles of [allowed]
  /// types. The larger [smoothing] is, the less jagged and spidery the blobs
  /// will be.
  void _growSeed(List<Vec> starts, int size, int smoothing, TileType tile) {
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
    var hack = 0;
    while (edges.isNotEmpty && count > 0) {
      if (hack++ > 1000) break;

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
      // TODO: Should be reached if start is reached.
      setTile(pos.x, pos.y, tile, TileState.natural);
      addNeighbors(pos);
      edges.remove(pos);

      count--;
    }
  }
}
