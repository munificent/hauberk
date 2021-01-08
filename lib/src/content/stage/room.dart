import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';

// TODO: Different kinds of lights.
// TODO: Different architectural styles should lean towards certain lighting
// arrangements.
// TODO: More things to light rooms with:
// - candles on tables
// - candles on floor?
// - torches embedded in wall
// - fireplaces
// - freestanding torches?
// - fire pit

/// Generates random rooms.
class Room {
  static Array2D<RoomTile> create(int depth) {
    // TODO: Instead of picking from these randomly, different architectural
    // styles should prefer certain room shapes.
    // TODO: More room shapes:
    // - Plus
    // - T
    switch (rng.inclusive(10)) {
      case 0:
        return _diamond(depth);
      case 1:
        return _octagon(depth);
      case 2:
      case 3:
        return _angled(depth);
      default:
        return _rectangle(depth);
    }
  }

  static Array2D<RoomTile> _rectangle(int depth) {
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

    var lights = <List<Vec>>[];

    // Center.
    if (short <= 9 && width.isOdd && height.isOdd) {
      lights.add([Vec(width ~/ 2 + 1, height ~/ 2 + 1)]);
    }

    // Braziers in corners.
    if (long >= 5) {
      for (var i = 0; i < (short - 1) ~/ 2; i++) {
        lights.add([
          Vec(1 + i, 1 + i),
          Vec(width - i, 1 + i),
          Vec(1 + i, height - i),
          Vec(width - i, height - i)
        ]);
      }
    }

    // TODO: Row of braziers down center of long axis.

    _addLights(depth, tiles, lights);
    _calculateEdges(tiles);
    return tiles;
  }

  static Array2D<RoomTile> _angled(int depth) {
    // Make a randomly-sized room but keep the aspect ratio reasonable.
    var short = rng.inclusive(5, 10);
    var long = rng.inclusive(short, math.min(16, short + 4));

    var horizontal = rng.oneIn(2);
    var width = horizontal ? long : short;
    var height = horizontal ? short : long;

    var cutWidth = rng.inclusive(2, width - 3);
    var cutHeight = rng.inclusive(2, height - 3);

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

    var lights = <List<Vec>>[];

    // Braziers in corners.
    var narrowest = math.min(width - cutWidth, height - cutHeight);
    for (var i = 0; i < (narrowest - 1) ~/ 2; i++) {
      var cornerLights = <Vec>[];
      lights.add(cornerLights);
      if (!isTop || !isLeft) cornerLights.add(Vec(1 + i, 1 + i));
      if (!isTop || isLeft) cornerLights.add(Vec(width - i, 1 + i));
      if (isTop || !isLeft) cornerLights.add(Vec(1 + i, height - i));
      if (isTop || isLeft) cornerLights.add(Vec(width - i, height - i));

      if (isTop) {
        if (isLeft) {
          cornerLights.add(Vec(cutWidth + 1 + i, 1 + i));
          cornerLights.add(Vec(1 + i, cutHeight + 1 + i));
        } else {
          cornerLights.add(Vec(width - cutWidth - i, 1 + i));
          cornerLights.add(Vec(width - i, cutHeight + 1 + i));
        }
      } else {
        if (isLeft) {
          cornerLights.add(Vec(cutWidth + 1 + i, height - i));
          cornerLights.add(Vec(1 + i, height - cutHeight - i));
        } else {
          cornerLights.add(Vec(width - i, height - cutHeight - i));
          cornerLights.add(Vec(width - cutWidth - i, height - i));
        }
      }
    }

    _addLights(depth, tiles, lights);
    _calculateEdges(tiles);
    return tiles;
  }

  static Array2D<RoomTile> _diamond(int depth) {
    var size = rng.inclusive(5, 17);
    return _angledCorners(size, (size - 1) ~/ 2, depth);
  }

  static Array2D<RoomTile> _octagon(int depth) {
    var size = rng.inclusive(6, 13);
    var corner = rng.inclusive(2, size ~/ 2 - 1);

    return _angledCorners(size, corner, depth);
  }

  static Array2D<RoomTile> _angledCorners(int size, int corner, int depth) {
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

    var lights = <List<Vec>>[];

    // Center.
    if (size <= 9 && size.isOdd) {
      lights.add([Vec(size ~/ 2 + 1, size ~/ 2 + 1)]);
    }

    // Diamonds.
    if (size.isOdd) {
      for (var i = 2; i < size ~/ 2 - 1; i++) {
        lights.add([
          Vec(size ~/ 2 + 1, size ~/ 2 + 1 - i),
          Vec(size ~/ 2 + 1 + i, size ~/ 2 + 1),
          Vec(size ~/ 2 + 1, size ~/ 2 + 1 + i),
          Vec(size ~/ 2 + 1 - i, size ~/ 2 + 1)
        ]);
      }
    }

    // Squares.
    var maxSquare = (size + 1) ~/ 2 - (corner + 1) ~/ 2 - 3;
    for (var i = 0; i <= maxSquare; i++) {
      lights.add([
        Vec((size - 1) ~/ 2 - i, (size - 1) ~/ 2 - i),
        Vec((size + 4) ~/ 2 + i, (size - 1) ~/ 2 - i),
        Vec((size - 1) ~/ 2 - i, (size + 4) ~/ 2 + i),
        Vec((size + 4) ~/ 2 + i, (size + 4) ~/ 2 + i),
      ]);
    }

    _addLights(depth, tiles, lights);
    _calculateEdges(tiles);
    return tiles;
  }

  /// Given a set of floor tiles, marks the boundary tiles as junctions or walls
  /// as appropriate.
  static void _calculateEdges(Array2D<RoomTile> room) {
    for (var pos in room.bounds) {
      if (!room[pos].isUnused) continue;

      bool isFloor(Direction dir) {
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

  // TODO: This is kind of inefficient because it goes through the trouble to
  // generate every possible lighting setup for a room before picking one or
  // even deciding if the room should be lit.
  static void _addLights(
      int depth, Array2D<RoomTile> room, List<List<Vec>> lights) {
    if (lights.isEmpty) return;

    if (!rng.percent(lerpInt(depth, 1, Option.maxDepth, 90, 20))) return;

    for (var light in rng.item(lights)) {
      room[light] = RoomTile.tile(rng.item(Tiles.braziers));
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

  bool get isUnused => tile == null && direction == Direction.none;

  /// Whether the room tile is a floor or other specific tile type.
  bool get isTile => !isUnused && !isWall && !isJunction;

  bool get isWall => tile == Tiles.solid;

  bool get isJunction => direction != Direction.none;
}
