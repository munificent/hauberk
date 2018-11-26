import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';

/// Generates random rooms.
class Room {
  static Array2D<RoomTile> create() {
    // TODO: Instead of picking from these randomly, different architectural
    // styles should prefer certain room shapes.
    // TODO: More room shapes:
    // - Plus
    // - T
    switch (rng.inclusive(10)) {
      case 0:
        return _diamond();
      case 1:
        return _octagon();
      case 2:
      case 3:
        return _angled();
      default:
        return _rectangle();
    }
  }

  static Array2D<RoomTile> _rectangle() {
    // Make a randomly-sized room but keep the aspect ratio reasonable.
    var short = rng.inclusive(3, 10);
    var long = rng.inclusive(short, math.min(16, short + 4));

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
    var short = rng.inclusive(4, 10);
    var long = rng.inclusive(short, math.min(16, short + 4));

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

  static Array2D<RoomTile> _diamond() {
    var size = rng.inclusive(5, 17);
    return _angledCorners(size, size ~/ 2);
  }

  static Array2D<RoomTile> _octagon() {
    var size = rng.inclusive(6, 13);
    var corner = rng.inclusive(2, size ~/ 2 - 1);

    return _angledCorners(size, corner);
  }

  static Array2D<RoomTile> _angledCorners(int size, int corner) {
    var tiles = Array2D<RoomTile>(size + 2, size + 2, RoomTile.unused);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (x + y < corner) continue;
        if (size - x - 1 + y < corner) continue;
        if (x + size - y - 1 < corner) continue;
        if (size - x - 1 + size - y - 1 < corner) continue;

        tiles.set(x + 1, y + 1, RoomTile.floor);
      }
    }

    // TODO: Temp. This is just a proof of concept of placing non-floor tiles
    // using RoomTile.
    var torch = RoomTile.tile(Tiles.wallTorch);
    tiles.set(size ~/ 2 + 1, size ~/ 2 + 1, torch);
    tiles.set((size - 1) ~/ 2 + 1, size ~/ 2 + 1, torch);
    tiles.set(size ~/ 2 + 1, (size - 1) ~/ 2 + 1, torch);
    tiles.set((size - 1) ~/ 2 + 1, (size - 1) ~/ 2 + 1, torch);

    _calculateEdges(tiles);
    return tiles;
  }

  /// Given a set of floor tiles, marks the boundary tiles as junctions or walls
  /// as appropriate.
  static void _calculateEdges(Array2D<RoomTile> room) {
    for (var pos in room.bounds) {
      if (!room[pos].isUnused) continue;

      isFloor(Direction dir) {
        var here = pos + dir;
        if (!room.bounds.contains(here)) return false;
        return room[here].isTile;
      }

      var cardinalFloors = Direction.cardinal.where(isFloor).toList();
      var hasCornerFloor = Direction.intercardinal.any(isFloor);

      if (cardinalFloors.length == 1) {
        // Place junctions next to floors.
        room[pos] = RoomTile.junction(cardinalFloors.single.rotate180);
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
  static final unused = RoomTile.junction(Direction.none);

  /// Room floor.
  static final floor = RoomTile.tile(Tiles.open);

  /// Room wall that cannot have a junction or passage through it. Used to
  /// prevent entrances to rooms in corners, which looks weird.
  static final wall = RoomTile.tile(Tiles.solid);

  final TileType tile;
  final Direction direction;

  RoomTile.junction(this.direction) : tile = null;
  RoomTile.tile(this.tile) : direction = Direction.none;

  const RoomTile._(this.tile, this.direction);

  bool get isUnused => tile == null && direction == Direction.none;

  /// Whether the room tile is a floor or other specific tile type.
  bool get isTile => !isUnused && !isWall && !isJunction;

  bool get isWall => tile == Tiles.solid;

  bool get isJunction => direction != Direction.none;
}
