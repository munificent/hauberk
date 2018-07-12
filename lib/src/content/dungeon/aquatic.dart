import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'dungeon.dart';
import 'place.dart';
import 'dart:math' as math;

abstract class AquaticBiome extends Biome {
  final Dungeon _dungeon;

  AquaticBiome(this._dungeon);

  void _makePlace(int grottoes, List<Vec> cells) {
    for (var i = 0; i < grottoes; i++) {
      for (var i = 0; i < 200; i++) {
        var pos = rng.item(cells);
        // TODO: Handle different shore types.
        if (_dungeon.getTileAt(pos) == Tiles.grass &&
            _dungeon.hasCardinalNeighbor(pos, [Tiles.wall, Tiles.rock])) {
          // TODO: Different sizes and smoothness.
          _erode([pos], 30, 3, Tiles.grass, cells);
          break;
        }
      }
    }

    _dungeon.addPlace(AquaticPlace(cells));
  }

  /// Grows a randomly shaped blob starting at [start].
  ///
  /// Tries to add approximately [size] tiles of type [tile] that are directly
  /// attached to the starting tile. Only grows through tiles of [allowed]
  /// types. The larger [smoothing] is, the less jagged and spidery the blobs
  /// will be.
  void _erode(List<Vec> starts, int size, int smoothing, TileType tile,
      [List<Vec> cells]) {
    var edges = Set<Vec>();

    addNeighbors(Vec pos) {
      for (var dir in Direction.cardinal) {
        var neighbor = pos + dir;
        if (!_dungeon.safeBounds.contains(neighbor)) continue;

        // TODO: Allow passing in the tile types that can be grown into.
        var type = _dungeon.getTileAt(neighbor);
        if (type != Tiles.wall && type != Tiles.rock) continue;
        edges.add(neighbor);
      }
    }

    scorePos(Vec pos) {
      var score = 0;

      // Count straight neighbors higher to discourage diagonal growth.
      for (var dir in Direction.cardinal) {
        var neighbor = pos + dir;
        if (_dungeon.getTileAt(neighbor) == tile) score += 2;
      }

      for (var dir in Direction.intercardinal) {
        var neighbor = pos + dir;
        if (_dungeon.getTileAt(neighbor) == tile) score++;
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
      _dungeon.setTileAt(pos, tile);
      addNeighbors(pos);
      edges.remove(pos);

      if (cells != null) cells.add(pos);

      count--;
    }
  }
}

class RiverBiome extends AquaticBiome {
  final Set<Vec> _cells = Set();

  RiverBiome(Dungeon dungeon) : super(dungeon);

  Iterable<String> generate() sync* {
    // TODO: Rivers that flow into/from lakes?
    // TODO: Branching tributaries?

    yield "Carving river";

    // Pick the start and end points. Rivers always flow from one edge of the
    // dungeon to another.
    var startSide = rng.item(Direction.cardinal);
    var endSide = rng.item(Direction.cardinal.toList()..remove(startSide));

    // Midpoint displacement.
    var mid = _makePoint(Direction.none);
    _displace(_dungeon, _makePoint(startSide), mid);
    _displace(_dungeon, mid, _makePoint(endSide));

    yield "Placing bridges";
    _placeBridges();

    _makePlace(rng.taper(2, 4), _cells.toList());
  }

  /// Makes a random end- or midpoint for the river. If [side] is a cardinal
  /// direction, it picks a point on that side of the dungeon. If none, it
  /// picks a point near the center.
  _RiverPoint _makePoint(Direction side) {
    var x = rng.float(_dungeon.width * 0.25, _dungeon.width * 0.75);
    var y = rng.float(_dungeon.height * 0.25, _dungeon.height * 0.75);

    switch (side) {
      case Direction.none:
        return _RiverPoint(x, y);
      case Direction.n:
        return _RiverPoint(x, -2.0);
      case Direction.s:
        return _RiverPoint(x, _dungeon.height + 2.0);
      case Direction.e:
        return _RiverPoint(_dungeon.width + 2.0, y);
      case Direction.w:
        return _RiverPoint(-2.0, y);
    }

    throw "unreachable";
  }

  void _displace(Dungeon dungeon, _RiverPoint start, _RiverPoint end) {
    var h = start.x - end.x;
    var v = start.y - end.y;

    // Recursively subdivide if the segment is long enough.
    var length = math.sqrt(h * h + v * v);
    if (length > 1.0) {
      // TODO: Displace along the tangent line between start and end?
      var x = (start.x + end.x) / 2.0 + rng.float(length / 2.0) - length / 4.0;
      var y = (start.y + end.y) / 2.0 + rng.float(length / 2.0) - length / 4.0;
      var radius = (start.radius + end.radius) / 2.0;
      var mid = _RiverPoint(x, y, radius);
      _displace(dungeon, start, mid);
      _displace(dungeon, mid, end);
      return;
    }

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
    x1 = x1.clamp(1, dungeon.width - 2);
    y1 = y1.clamp(1, dungeon.height - 2);
    x2 = x2.clamp(1, dungeon.width - 2);
    y2 = y2.clamp(1, dungeon.height - 2);

    var radiusSquared = radius * radius;
    var shoreSquared = shoreRadius * shoreRadius;

    for (var y = y1; y <= y2; y++) {
      for (var x = x1; x <= x2; x++) {
        var xx = start.x - x;
        var yy = start.y - y;

        // TODO: Different types of river and shore: ice, slime, blood, lava,
        // etc.
        var lengthSquared = xx * xx + yy * yy;
        var pos = Vec(x, y);
        if (lengthSquared <= radiusSquared) {
          dungeon.setTileAt(pos, Tiles.water);
          _cells.add(pos);
        } else if (lengthSquared <= shoreSquared && dungeon.isRock(x, y)) {
          dungeon.setTileAt(pos, Tiles.grass);
          _cells.add(pos);
        }
      }
    }
  }

  void _placeBridges() {
    // Divide the shore tiles into two sets so we can test that a bridge does
    // correct cross the river instead of just connecting the same side to
    // itself.
    var shortStart =
        _cells.firstWhere((pos) => _dungeon.getTileAt(pos) == Tiles.grass);
    var flow = MotilityFlow(_dungeon.stage, shortStart, Motility.walk);
    var shore1 = flow.reachable.toSet();
    var shore2 = _cells
        .where((pos) =>
            _dungeon.getTileAt(pos) == Tiles.grass && !shore1.contains(pos))
        .toSet();

    // TODO: Could do this lazily if it's a perf problem.
    // Find every valid bridge.
    var bridges = <Rect>[];
    for (var pos in shore1) {
      for (var dir in Direction.cardinal) {
        var here = pos + dir;

        // Don't allow bridges straight into rock.
        if (_dungeon.getTileAt(here) != Tiles.water) continue;

        while (_dungeon.getTileAt(here) == Tiles.water) here += dir;

        // If we didn't reach the other shore, we went along a bend. Don't
        // place a bridge for that.
        if (!shore2.contains(here)) continue;

        Rect bridge;
        switch (dir) {
          case Direction.n:
            bridge = Rect.column(here.x, here.y, pos.y - here.y);
            break;
          case Direction.s:
            bridge = Rect.column(pos.x, pos.y, here.y - pos.y);
            break;
          case Direction.e:
            bridge = Rect.row(pos.x, pos.y, here.x - pos.x);
            break;
          case Direction.w:
            bridge = Rect.row(here.x, here.y, pos.x - here.x);
            break;
        }
        bridges.add(bridge);
      }
    }

    // Hack. In rare cases where a river is too close to the edge of the
    // dungeon and one "shore" is a little isolated patch of grass, it's
    // possible to end up not finding and bridges. Instead of crashing, just
    // don't place any.
    // TODO: Look for isolated patches of grass or water and remove them before
    // placing bridges.
    if (bridges.isEmpty) return;

    var placed = <Rect>[];

    // Place a couple of bridges.
    var count = math.min(bridges.length, rng.taper(1, 4));
    for (var i = 0; i < count; i++) {
      // Pick a couple of locations and take the shortest path across the
      // river that doesn't touch an existing bridge.
      Rect shortest;
      for (var i = 0; i < 5; i++) {
        var bridge = rng.item(bridges);

        // Don't overlap an existing bridge.
        if (placed.contains(bridge) ||
            placed.any((previous) =>
                Rect.intersect(previous.inflate(1), bridge).isNotEmpty)) {
          continue;
        }

        if (shortest == null || bridge.area < shortest.area) {
          shortest = bridge;
        }
      }

      // If every try hit an existing bridge, just skip it.
      if (shortest == null) continue;

      for (var pos in shortest) {
        _dungeon.setTile(pos.x, pos.y, Tiles.bridge);
      }
    }
  }
}

class _RiverPoint {
  final double x;
  final double y;
  final double radius;

  _RiverPoint(this.x, this.y, [double radius])
      : radius = radius ?? rng.float(1.0, 3.0);

  String toString() => "$x,$y ($radius)";
}

class LakeBiome extends AquaticBiome {
  final Array2D<bool> _blob;

  LakeBiome(Dungeon dungeon, this._blob) : super(dungeon);

  Iterable<String> generate() sync* {
    // TODO: Lakes sometimes have unreachable islands in the middle. Should
    // either fill those in, add bridges, give players a way to traverse water,
    // or at least ensure nothing is spawned on them.

    // Try to find a place to drop the lake.
    for (var i = 0; i < 100; i++) {
      var x = rng.range(0, _dungeon.width - _blob.width);
      var y = rng.range(0, _dungeon.height - _blob.height);

      // See if the lake overlaps anything.
      var canPlace = true;
      for (var pos in _blob.bounds) {
        if (_blob[pos]) {
          if (!_dungeon.isRockAt(pos.offset(x, y))) {
            canPlace = false;
            break;
          }
        }
      }

      if (!canPlace) continue;

      // We found a spot, carve the water.
      var cells = <Vec>[];
      for (var pos in _blob.bounds) {
        if (_blob[pos]) {
          var absolute = pos.offset(x, y);
          _dungeon.setTileAt(absolute, Tiles.water);
          cells.add(absolute);
        }
      }

      // Grow a shoreline.
      var edges = <Vec>[];
      var shoreBounds =
          Rect.intersect(_blob.bounds.offset(x, y), _dungeon.safeBounds);
      for (var pos in shoreBounds) {
        if (_dungeon.isRockAt(pos) && _dungeon.hasNeighbor(pos, Tiles.water)) {
          _dungeon.setTileAt(pos, Tiles.grass);
          edges.add(pos);

          cells.add(pos);
        }
      }

      // Carve out the entire shoreline.
      _erode(edges, edges.length, 4, Tiles.grass, cells);
      _makePlace(rng.countFromFloat(edges.length / 80.0), cells);
      return;
    }
  }
}
