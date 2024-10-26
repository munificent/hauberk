import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';

/// Uses a cellular automata to carve out rounded open cavernous areas.
class River extends Architecture {
  @override
  Iterable<String> build() sync* {
    // TODO: Branching tributaries?

    // Pick a direction for the river. A river always begins and ends at the
    // edge of the dungeon. It may either go across opposing sides, or make a
    // roughly 90° turn and enter and exit on adjacent sides. In the latter
    // case, we want to make sure the river doesn't have too tight of a turn,
    // so we skew the endpoints away from the side that the curve towards.

    var north = -2.0;
    var south = height + 2.0;
    var east = width + 2.0;
    var west = -2.0;

    double northish() => rng.float(height * 0.2, height * 0.4);
    double southish() => rng.float(height * 0.6, height * 0.8);
    double eastish() => rng.float(width * 0.6, width * 0.8);
    double westish() => rng.float(width * 0.2, width * 0.4);
    double northSouth() => rng.float(height * 0.2, height * 0.8);
    double eastWest() => rng.float(width * 0.2, width * 0.8);

    var (start, end) = switch (rng.range(6)) {
      // East to west.
      0 => (_RiverPoint(west, northSouth()), _RiverPoint(east, northSouth())),
      // North to south.
      1 => (_RiverPoint(eastWest(), north), _RiverPoint(eastWest(), south)),
      // North to east.
      2 => (_RiverPoint(westish(), north), _RiverPoint(east, southish())),
      // East to south.
      3 => (_RiverPoint(east, northish()), _RiverPoint(westish(), south)),
      // South to west.
      4 => (_RiverPoint(eastish(), south), _RiverPoint(west, northish())),
      // West to north.
      5 => (_RiverPoint(west, southish()), _RiverPoint(eastish(), north)),
      _ => throw StateError("Unreachable"),
    };

    var mid = _RiverPoint(rng.float(width * 0.4, width * 0.6),
        rng.float(height * 0.4, height * 0.6));

    _displace(start, mid);
    _displace(mid, end);
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
      // TODO: Add some randomness.

      var shoreRandomness = math.min(2.0, length / 4.0);
      var shoreRadius = (start.shoreRadius + end.shoreRadius) / 2.0 +
          rng.float(-shoreRandomness, shoreRandomness);
      shoreRadius = shoreRadius.clamp(0.0, 4.0);

      var waterRadius = (start.waterRadius + end.waterRadius) / 2.0;
      var mid = _RiverPoint(x, y, shoreRadius, waterRadius);
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

    var shoreRadiusSquared = start.radius * start.radius;
    var waterRadiusSquared = start.waterRadius * start.waterRadius;

    for (var y = y1; y <= y2; y++) {
      for (var x = x1; x <= x2; x++) {
        var xx = start.x - x;
        var yy = start.y - y;

        var lengthSquared = xx * xx + yy * yy;
        var pos = Vec(x, y);
        if (lengthSquared <= waterRadiusSquared) {
          placeWater(pos);
        } else if (lengthSquared <= shoreRadiusSquared) {
          placeShore(pos);
        }
      }
    }
  }
}

class _RiverPoint {
  final double x;
  final double y;
  final double shoreRadius;
  final double waterRadius;

  double get radius => shoreRadius + waterRadius;

  _RiverPoint(this.x, this.y, [double? shoreRadius, double? waterRadius])
      : shoreRadius = shoreRadius ?? rng.float(1.0, 3.0),
        waterRadius = waterRadius ?? rng.float(1.0, 3.0);

  @override
  String toString() => "$x,$y ($waterRadius)";
}
