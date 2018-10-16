import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';

/// Uses a cellular automata to carve out rounded open cavernous areas.
class River extends Architecture {
  Iterable<String> build(Region region) sync* {
    // TODO: Branching tributaries?

    // Pick the start and end points. Rivers always flow from one edge of the
    // dungeon to another.
    var startSide = rng.item(Direction.cardinal);
    var endSide = rng.item(Direction.cardinal.toList()..remove(startSide));

    // Midpoint displacement.
    var mid = _makePoint(Direction.none);
    _displace(_makePoint(startSide), mid);
    _displace(mid, _makePoint(endSide));
  }

  /// Makes a random end- or midpoint for the river. If [side] is a cardinal
  /// direction, it picks a point on that side of the dungeon. If none, it
  /// picks a point near the center.
  _RiverPoint _makePoint(Direction side) {
    var x = rng.float(width * 0.25, width * 0.75);
    var y = rng.float(height * 0.25, height * 0.75);

    switch (side) {
      case Direction.none:
        return _RiverPoint(x, y);
      case Direction.n:
        return _RiverPoint(x, -2.0);
      case Direction.s:
        return _RiverPoint(x, height + 2.0);
      case Direction.e:
        return _RiverPoint(width + 2.0, y);
      case Direction.w:
        return _RiverPoint(-2.0, y);
    }

    throw "unreachable";
  }

  void _displace(_RiverPoint start, _RiverPoint end) {
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
      _displace(start, mid);
      _displace(mid, end);
      return;
    }

    var x1 = (start.x - start.radius).floor();
    var y1 = (start.y - start.radius).floor();
    var x2 = (start.x + start.radius).ceil();
    var y2 = (start.y + start.radius).ceil();

    // Don't go off the edge of the level. In fact, inset one inside it so
    // that we don't carve walkable tiles up to the edge.
    // TODO: Some sort of different tile types at the edge of the level to
    // look better than the river just stopping?
    x1 = x1.clamp(1, width - 2);
    y1 = y1.clamp(1, height - 2);
    x2 = x2.clamp(1, width - 2);
    y2 = y2.clamp(1, height - 2);

    var radiusSquared = start.radius * start.radius;

    for (var y = y1; y <= y2; y++) {
      for (var x = x1; x <= x2; x++) {
        var xx = start.x - x;
        var yy = start.y - y;

        var lengthSquared = xx * xx + yy * yy;
        var pos = Vec(x, y);
        if (lengthSquared <= radiusSquared) placeWater(pos);
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
