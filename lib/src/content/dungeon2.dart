import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'blob.dart';
import 'tiles.dart';

class Dungeon2 {
  final Stage stage;
  final int depth;

  Rect get bounds => stage.bounds;
  int get width => stage.width;
  int get height => stage.height;

  Dungeon2(this.stage, this.depth);

  Iterable<String> generate() sync* {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        setTile(x, y, Tiles.wall);
      }
    }

    // TODO: Change the odds based on depth.
    if (rng.oneIn(3)) {
      yield "Carving river";
      _addRiver();
    } else {
      // TODO: Temp hack so the hero can be placed.
      for (var y = 1; y < 7; y++) {
        for (var x = 1; x < 7; x++) {
          setTile(x, y, Tiles.floor);
        }
      }
    }

    if (rng.oneIn(5)) {
      yield "Pouring big lake";
      // TODO: 64 is pretty big. Might want to make these a little smaller, but
      // not all the way down to 32.
      _addLake(Blob.make64());
    } else if (rng.oneIn(2)) {
      yield "Pouring lake";
      _addLake(Blob.make32());
    }

    var ponds = rng.taper(0, 3);
    for (var i = 0; i < ponds; i++) {
      yield "Pouring pond $i/$ponds";
      _addLake(Blob.make16());
    }

    // TODO: Add grottoes other places than just on rivers.
    yield* _addGrottoes();
  }

  void setTile(int x, int y, TileType type) {
    stage.get(x, y).type = type;
  }

  bool isWall(int x, int y) => stage.get(x, y).type == Tiles.wall;

  /// Returns `true` if the cell at [pos] has at least one adjacent tile with
  /// type [tile].
  bool hasCardinalNeighbor(Vec pos, TileType tile) {
    for (var dir in Direction.cardinal) {
      var neighbor = pos + dir;
      if (!stage.bounds.inflate(-1).contains(neighbor)) continue;

      // TODO: Allow passing in the tile types that can be grown into.
      if (stage[neighbor].type == tile) return true;
    }

    return false;
  }

  /// Returns `true` if the cell at [pos] has at least one adjacent tile with
  /// type [tile].
  bool hasNeighbor(Vec pos, TileType tile) {
    for (var dir in Direction.all) {
      var neighbor = pos + dir;
      if (!stage.bounds.inflate(-1).contains(neighbor)) continue;

      // TODO: Allow passing in the tile types that can be grown into.
      if (stage[neighbor].type == tile) return true;
    }

    return false;
  }

  void _displace(RiverPoint start, RiverPoint end) {
    var h = start.x - end.x;
    var v = start.y - end.y;
    var length = math.sqrt(h * h + v * v);
    if (length > 1.0) {
      // TODO: Displace along the tangent line between start and end?
      var x = (start.x + end.x) / 2.0 + rng.float(length / 2.0) - length / 4.0;
      var y = (start.y + end.y) / 2.0 + rng.float(length / 2.0) - length / 4.0;
      var radius = (start.radius + end.radius) /
          2.0; //+ rng.float(length / 10.0) - length - 20.0;
      var mid = new RiverPoint(x, y, radius);
      _displace(start, mid);
      _displace(mid, end);
    } else {
      var radius = start.radius;
      var shoreRadius = radius + rng.float(1.0, 3.0);

      var x1 = (start.x - shoreRadius).floor();
      var y1 = (start.y - shoreRadius).floor();
      var x2 = (start.x + shoreRadius).ceil();
      var y2 = (start.y + shoreRadius).ceil();

      // Don't go off the edge of the level. In fact, inset one inside it so
      // that we don't carve walkable tiles up to the edge.
      // TODO: Some sort of different tile types at the edge of the level to
      // look better than the river just stopping?
      x1 = x1.clamp(1, width - 2);
      y1 = y1.clamp(1, height - 2);
      x2 = x2.clamp(1, width - 2);
      y2 = y2.clamp(1, height - 2);

      var radiusSquared = radius * radius;
      var shoreSquared = shoreRadius * shoreRadius;

      for (var y = y1; y <= y2; y++) {
        for (var x = x1; x <= x2; x++) {
          var xx = start.x - x;
          var yy = start.y - y;

          // TODO: Different types of river and shore: ice, slime, blood, lava,
          // etc.
          var lengthSquared = xx * xx + yy * yy;
          if (lengthSquared <= radiusSquared) {
            setTile(x, y, Tiles.water);
          } else if (lengthSquared <= shoreSquared) {
            if (isWall(x, y)) setTile(x, y, Tiles.grass);
          }
        }
      }
    }
  }

  void _addRiver() {
    // Midpoint displacement.
    // Consider also squig curves from: http://algorithmicbotany.org/papers/mountains.gi93.pdf.
    var start =
        new RiverPoint(rng.float(width.toDouble()), -4.0, rng.float(1.0, 3.0));
    var end = new RiverPoint(
        rng.float(width.toDouble()), height + 4.0, rng.float(1.0, 3.0));
    var mid = new RiverPoint(rng.float(width * 0.25, width * 0.75),
        rng.float(height * 0.25, height * 0.75), rng.float(1.0, 3.0));

    if (rng.oneIn(2)) {
      // Horizontal instead of vertical.
      start = new RiverPoint(start.y, start.x, start.radius);
      end = new RiverPoint(end.y, end.x, end.radius);
    }

    // TODO: Branching tributaries?

    _displace(start, mid);
    _displace(mid, end);

    // TODO: Figure out how to handle the edge of the dungeon.
  }

  Iterable<String> _addGrottoes() sync* {
    var count = rng.taper(2, 3);
    for (var i = 0; i < 200; i++) {
      var pos = rng.vecInRect(bounds.inflate(-1));
      // TODO: Handle different shore types.
      if (stage[pos].type == Tiles.grass &&
          hasCardinalNeighbor(pos, Tiles.wall)) {
        yield "Carving grotto";
        // TODO: Different sizes and smoothness.
        _growSeed([pos], 30, 3, Tiles.grass);
        if (--count == 0) break;
      }
    }
  }

  void _addLake(Array2D<bool> cells) {
    // Try to find a place to drop it.
    for (var i = 0; i < 100; i++) {
      var x = rng.range(0, width - cells.width);
      var y = rng.range(0, height - cells.height);

      // See if the lake overlaps anything.
      var canPlace = true;
      for (var pos in cells.bounds) {
        if (cells[pos]) {
          if (!isWall(pos.x + x, pos.y + y)) {
            canPlace = false;
            break;
          }
        }
      }

      if (!canPlace) continue;

      // We found a spot, carve the water.
      for (var pos in cells.bounds) {
        if (cells[pos]) {
          setTile(pos.x + x, pos.y + y, Tiles.water);
        }
      }

      // Grow a shoreline.
      var edges = <Vec>[];
      var shoreBounds =
          Rect.intersect(cells.bounds.offset(x, y).inflate(1), bounds);
      for (var pos in shoreBounds) {
        if (isWall(pos.x, pos.y) && hasNeighbor(pos, Tiles.water)) {
          setTile(pos.x, pos.y, Tiles.grass);
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
        if (!stage.bounds.inflate(-1).contains(neighbor)) continue;

        // TODO: Allow passing in the tile types that can be grown into.
        if (stage[neighbor].type != Tiles.wall) continue;
        edges.add(neighbor);
      }
    }

    scorePos(Vec pos) {
      var score = 0;

      // Count straight neighbors higher to discourage diagonal growth.
      for (var dir in Direction.cardinal) {
        var neighbor = pos + dir;
        if (stage[neighbor].type == tile) score += 2;
      }

      for (var dir in Direction.intercardinal) {
        var neighbor = pos + dir;
        if (stage[neighbor].type == tile) score++;
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
      stage[pos].type = tile;
      addNeighbors(pos);
      edges.remove(pos);

      count--;
    }
  }
}

class RiverPoint {
  final double x;
  final double y;
  final double radius;

  RiverPoint(this.x, this.y, this.radius);

  String toString() => "$x,$y ($radius)";
}
