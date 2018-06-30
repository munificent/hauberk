import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'dungeon.dart';
import 'place.dart';

class RiverBiome extends Biome {
  final Dungeon _dungeon;
  final Set<Vec> _cells = new Set();

  RiverBiome(this._dungeon);

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

    _dungeon.addPlace(new AquaticPlace(_cells.toList()));
  }

  /// Makes a random end- or midpoint for the river. If [side] is a cardinal
  /// direction, it picks a point on that side of the dungeon. If none, it
  /// picks a point near the center.
  _RiverPoint _makePoint(Direction side) {
    var x = rng.float(_dungeon.width * 0.25, _dungeon.width * 0.75);
    var y = rng.float(_dungeon.height * 0.25, _dungeon.height * 0.75);

    switch (side) {
      case Direction.none:
        return new _RiverPoint(x, y);
      case Direction.n:
        return new _RiverPoint(x, -2.0);
      case Direction.s:
        return new _RiverPoint(x, _dungeon.height + 2.0);
      case Direction.e:
        return new _RiverPoint(_dungeon.width + 2.0, y);
      case Direction.w:
        return new _RiverPoint(-2.0, y);
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
      var mid = new _RiverPoint(x, y, radius);
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
        var pos = new Vec(x, y);
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
    var flow = new MotilityFlow(_dungeon.stage, shortStart, MotilitySet.walk);
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
            bridge = new Rect.column(here.x, here.y, pos.y - here.y);
            break;
          case Direction.s:
            bridge = new Rect.column(pos.x, pos.y, here.y - pos.y);
            break;
          case Direction.e:
            bridge = new Rect.row(pos.x, pos.y, here.x - pos.x);
            break;
          case Direction.w:
            bridge = new Rect.row(here.x, here.y, pos.x - here.x);
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
