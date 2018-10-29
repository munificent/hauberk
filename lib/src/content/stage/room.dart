import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

/// Generates random rooms.
class Room {
  static Array2D<RoomTile> create() {
    // TODO: More room shapes:
    // - Octangle (angled corners).
    // - Plus
    // - T
    if (rng.oneIn(3)) {
      return _angled();
    } else {
      return _rectangle();
    }
  }

  static Array2D<RoomTile> _rectangle() {
    // Make a randomly-sized room but keep the aspect ratio reasonable.
    var short = rng.inclusive(3, 8);
    var long = rng.inclusive(short, math.min(12, short + 4));

    var horizontal = rng.oneIn(2);
    var width = horizontal ? long : short;
    var height = horizontal ? short : long;

    var tiles = Array2D<RoomTile>(width + 2, height + 2, RoomTile.unused);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        tiles.set(x + 1, y + 1, RoomTile.floor);
      }
    }

    _calculateEdges(tiles);
    return tiles;
  }

  static Array2D<RoomTile> _angled() {
    // Make a randomly-sized room but keep the aspect ratio reasonable.
    var short = rng.inclusive(4, 9);
    var long = rng.inclusive(short, math.min(12, short + 4));

    var horizontal = rng.oneIn(2);
    var width = horizontal ? long : short;
    var height = horizontal ? short : long;

    var cutWidth = rng.inclusive(2, width - 2);
    var cutHeight = rng.inclusive(2, height - 2);

    var isTop = rng.oneIn(2);
    var isLeft = rng.oneIn(2);

    // Open the whole rect.
    var tiles = Array2D<RoomTile>(width + 2, height + 2, RoomTile.unused);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        tiles.set(x + 1, y + 1, RoomTile.floor);
      }
    }

    // Fill in the cut.
    var xMin = isLeft ? 0 : width - cutWidth;
    var xMax = isLeft ? cutWidth : width;
    var yMin = isTop ? 0 : height - cutHeight;
    var yMax = isTop ? cutHeight : height;
    for (var y = yMin; y < yMax; y++) {
      for (var x = xMin; x < xMax; x++) {
        tiles.set(x + 1, y + 1, RoomTile.unused);
      }
    }

    _calculateEdges(tiles);
    return tiles;
  }

  /// Given a set of floor tiles, marks the boundary tiles as junctions or walls
  /// as appropriate.
  static void _calculateEdges(Array2D<RoomTile> room) {
    for (var pos in room.bounds) {
      if (room[pos] != RoomTile.unused) continue;

      isFloor(Direction dir) {
        var here = pos + dir;
        if (!room.bounds.contains(here)) return false;
        return room[here] == RoomTile.floor;
      }

      var cardinalFloors = Direction.cardinal.where(isFloor).toList();
      var hasCornerFloor = Direction.intercardinal.any(isFloor);

      if (cardinalFloors.length == 1) {
        // Place junctions next to floors.
        room[pos] = RoomTile.junctionFor(cardinalFloors.single.rotate180);
      } else if (cardinalFloors.length > 1) {
        // Don't allow junctions at inside corners.
      } else if (hasCornerFloor) {
        // Don't allow passages at outside corners.
        room[pos] = RoomTile.wall;
      }
    }
  }
}

class RoomTile {
  /// Not part of the room.
  static const unused = RoomTile("unused", Direction.none);

  /// Room floor.
  static const floor = RoomTile("floor", Direction.none);

  /// Room wall that cannot have a junction or passage through it. Used to
  /// prevent entrances to rooms in corners, which looks weird.
  static const wall = RoomTile("wall", Direction.none);

  static const junctionN = RoomTile("junctionN", Direction.n);
  static const junctionS = RoomTile("junctionS", Direction.s);
  static const junctionE = RoomTile("junctionE", Direction.e);
  static const junctionW = RoomTile("junctionW", Direction.w);

  static RoomTile junctionFor(Direction dir) {
    switch (dir) {
      case Direction.n:
        return junctionN;
      case Direction.s:
        return junctionS;
      case Direction.e:
        return junctionE;
      case Direction.w:
        return junctionW;
      default:
        throw "Invalid direction.";
    }
  }

  final String name;
  final Direction direction;

  const RoomTile(this.name, this.direction);
}
