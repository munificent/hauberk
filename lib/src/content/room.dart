import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'blob.dart';
import 'tiles.dart';

class Junction {
  /// Points from the first room towards where the new room should be attached.
  ///
  /// A room must have an opposing junction in order to match.
  final Direction direction;

  /// The location of the junction.
  ///
  /// For a placed room, this is in absolute coordinates. For a room yet to be
  /// placed, it's relative to the room's tile array.
  final Vec position;

  Junction(this.direction, this.position);
}

class Room {
  static ResourceSet<RoomType> _allTypes = new ResourceSet();

  // TODO: Hacky. ResourceSet assumes resources are named and have unique names.
  // Relax that constraint?
  static int _nextNameId = 0;

  static Room create(int depth) {
    if (_allTypes.isEmpty) _initializeRoomTypes();

    // TODO: Take depth into account somehow.
    var type = _allTypes.tryChoose(1, "room");
    return type.create();
  }

  static void _add(RoomType type, int rarity) {
    _allTypes.add("room_${_nextNameId++}", type, 1, rarity, "room");
  }

  static void _initializeRoomTypes() {
    _allTypes.defineTags("room");

    // Rectangular rooms of various sizes.
    for (var width = 3; width <= 11; width++) {
      for (var height = 3; height <= 11; height++) {
        // Don't make them too big.
        if (width * height > 80) continue;

        // Don't make them too oblong.
        if ((width - height).abs() > math.min(width, height)) continue;

        // Middle-sized rooms are most common.
        var rarity = 1;
        if (math.max(width, height) <= 4) {
          rarity = 3;
        } else if (math.max(width, height) <= 5) {
          rarity = 2;
        } else if (math.min(width, height) >= 9) {
          rarity = 3;
        } else if (math.min(width, height) >= 7) {
          rarity = 2;
        }

        _add(new RectangleRoom(width, height), rarity * 10);
      }
    }

    // Blob-shaped rooms.
    // TODO: Get blobs working with junctions.
//    _add(new BlobRoom(), 1);

    // TODO: Other room shapes: L, T, cross, etc.
    // TODO: Passageways.
  }

  final Array2D<TileType> tiles;
  final List<Junction> junctions;

  Room(this.tiles, this.junctions);
}

abstract class RoomType {
  Room create();
}

class RectangleRoom extends RoomType {
  final int width;
  final int height;

  RectangleRoom(this.width, this.height);

  Room create() {
    // TODO: Cache this with the type?
    var tiles = new Array2D<TileType>(width + 2, height + 2, Tiles.floor);

    for (var y = 0; y < tiles.height; y++) {
      tiles.set(0, y, Tiles.wall);
      tiles.set(tiles.width - 1, y, Tiles.wall);
    }

    for (var x = 0; x < tiles.width; x++) {
      tiles.set(x, 0, Tiles.wall);
      tiles.set(x, tiles.height - 1, Tiles.wall);
    }

    var junctions = <Junction>[];
    _placeJunctions(width, (i) {
      junctions.add(new Junction(Direction.n, new Vec(i + 1, 0)));
    });

    _placeJunctions(width, (i) {
      junctions.add(new Junction(Direction.s, new Vec(i + 1, height + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(new Junction(Direction.w, new Vec(0, i + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(new Junction(Direction.e, new Vec(width + 1, i + 1)));
    });

    return new Room(tiles, junctions);
  }

  /// Walks along [length], invoking [callback] at values where a junction
  /// should be placed.
  ///
  /// Ensures two junctions are not placed next to each other.
  void _placeJunctions(int length, void Function(int) callback) {
    var start = rng.oneIn(2) ? 0 : 1;
    for (var i = start; i < length; i++) {
      // TODO: Make chances tunable.
      if (rng.range(100) < 40) {
        callback(i);

        // Don't allow two junctions right next to each other.
        i++;
      }
    }
  }
}

class BlobRoom extends RoomType {
  Room create() {
    // TODO: Other size blobs.
    var blob = Blob.make16();
    // Note: Assumes the blob never has open cells at the very edge.
    var tiles = new Array2D<TileType>(blob.width, blob.height);
    for (var pos in tiles.bounds.inflate(-1)) {
      if (blob[pos]) {
        tiles[pos] = Tiles.floor;

        // If this cell is at the edge of the blob, ensure there is a ring of
        // wall around it.
        for (var dir in Direction.all) {
          var neighbor = pos + dir;
          if (tiles[neighbor] != Tiles.floor) {
            tiles[neighbor] = Tiles.wall;
          }
        }
      }
    }

    // TODO: Place junctions.
    return new Room(tiles, []);
  }
}
