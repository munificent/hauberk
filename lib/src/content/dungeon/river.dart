import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';
import 'place.dart';

class RiverBiome extends Biome {
  final Dungeon _dungeon;
  final Set<Vec> _cells = new Set();

  RiverBiome(this._dungeon);

  Iterable<String> generate() sync* {
    // TODO: Rivers that flow into/from lakes?

    // Midpoint displacement.
    // Consider also squig curves from: http://algorithmicbotany.org/papers/mountains.gi93.pdf.
    yield "Carving river";
    _RiverPoint start, end;
    if (rng.oneIn(2)) {
      start = new _RiverPoint(
          rng.float(_dungeon.width.toDouble()), -4.0, rng.float(1.0, 3.0));
      end = new _RiverPoint(rng.float(_dungeon.width.toDouble()),
          _dungeon.height + 4.0, rng.float(1.0, 3.0));
    } else {
      start = new _RiverPoint(
          -4.0, rng.float(_dungeon.height.toDouble()), rng.float(1.0, 3.0));
      end = new _RiverPoint(_dungeon.width + 4.0,
          rng.float(_dungeon.height.toDouble()), rng.float(1.0, 3.0));
    }

    var mid = new _RiverPoint(
        rng.float(_dungeon.width * 0.25, _dungeon.width * 0.75),
        rng.float(_dungeon.height * 0.25, _dungeon.height * 0.75),
        rng.float(1.0, 3.0));

    // TODO: Branching tributaries?

    var path = new Set<Vec>();
    _displace(_dungeon, start, mid, path);
    _displace(_dungeon, mid, end, path);

    // Try to place bridges.
    yield "Finding bridges";
    var bridges = <Rect>[];
    for (var pos in path) {
      // See if a horizontal bridge reaches both shores.
      var westShore = -1;
      for (var x = pos.x; x >= 0; x--) {
        if (_dungeon.getTile(x, pos.y) == Tiles.grass) {
          westShore = x + 1;
          break;
        }
      }

      var eastShore = -1;
      for (var x = pos.x; x < _dungeon.width; x++) {
        if (_dungeon.getTile(x, pos.y) == Tiles.grass) {
          eastShore = x;
          break;
        }
      }

      if (westShore != -1 && eastShore != -1) {
        bridges.add(new Rect(westShore, pos.y, eastShore - westShore, 1));
      }

      // See if a vertical bridge does.
      var northShore = -1;
      for (var y = pos.y; y >= 0; y--) {
        if (_dungeon.getTile(pos.x, y) == Tiles.grass) {
          northShore = y + 1;
          break;
        }
      }

      var southShore = -1;
      for (var y = pos.y; y < _dungeon.height; y++) {
        if (_dungeon.getTile(pos.x, y) == Tiles.grass) {
          southShore = y;
          break;
        }
      }

      if (northShore != -1 && southShore != -1) {
        bridges.add(new Rect(pos.x, northShore, 1, southShore - northShore));
      }
    }

    // TODO: If there are no places we can put a bridge, the river can't be
    // crossed. Is that OK?
    yield "Placing bridges";
    if (bridges.isNotEmpty) {
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

          if (shortest == null || bridge.area < shortest.area)
            shortest = bridge;
        }

        if (shortest == null) continue;

        // TODO: It's possible for the bridge to not *cross* the river by going
        // along a bend. Fix that?

        for (var pos in shortest) {
          _dungeon.setTile(pos.x, pos.y, Tiles.bridge);
        }
      }
    }

    // TODO: What about piers that extend into the river but don't cross?
    // TODO: Bridges over lakes?

    // TODO: Better tiles at edge of dungeon?

    _dungeon.addPlace(new AquaticPlace(_cells.toList()));
  }

  void _displace(
      Dungeon dungeon, _RiverPoint start, _RiverPoint end, Set<Vec> path) {
    var h = start.x - end.x;
    var v = start.y - end.y;
    var length = math.sqrt(h * h + v * v);
    if (length > 1.0) {
      // TODO: Displace along the tangent line between start and end?
      var x = (start.x + end.x) / 2.0 + rng.float(length / 2.0) - length / 4.0;
      var y = (start.y + end.y) / 2.0 + rng.float(length / 2.0) - length / 4.0;
      var radius = (start.radius + end.radius) /
          2.0; //+ rng.float(length / 10.0) - length - 20.0;
      var mid = new _RiverPoint(x, y, radius);
      _displace(dungeon, start, mid, path);
      _displace(dungeon, mid, end, path);
    } else {
      // Keep track of the middle of the river. We'll use this for placing
      // bridges.
      var center = new Vec(start.x.toInt(), start.y.toInt());
      if (dungeon.safeBounds.contains(center)) path.add(center);

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
  }
}

class _RiverPoint {
  final double x;
  final double y;
  final double radius;

  _RiverPoint(this.x, this.y, this.radius);

  String toString() => "$x,$y ($radius)";
}
