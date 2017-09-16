import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
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
    }

    // TODO: Temp hack so the hero can be placed.
    for (var y = 1; y < 7; y++) {
      for (var x = 1; x < 7; x++) {
        setTile(x, y, Tiles.floor);
      }
    }
  }

  void setTile(int x, int y, TileType type) {
    stage.get(x, y).type = type;
  }

  bool isWall(int x, int y) => stage.get(x, y).type == Tiles.wall;

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
        new RiverPoint(rng.float(width.toDouble()), -4.0, rng.float(1.0, 4.0));
    var end = new RiverPoint(
        rng.float(width.toDouble()), height + 4.0, rng.float(1.0, 4.0));
    var mid = new RiverPoint(rng.float(width * 0.25, width * 0.75),
        rng.float(height * 0.25, height * 0.75), rng.float(1.0, 4.0));
    _displace(start, mid);
    _displace(mid, end);

    // TODO: Figure out how to handle the edge of the dungeon.
  }
}

class RiverPoint {
  final double x;
  final double y;
  final double radius;

  RiverPoint(this.x, this.y, this.radius);

  String toString() => "$x,$y ($radius)";
}
