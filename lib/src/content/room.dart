import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'blob.dart';
import 'tiles.dart';

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
    _add(new BlobRoom(), 1);

//    octagon(int w, int h, int slope, {int rarity: 1}) {
//      // 4 * to make all octagonal rooms less common.
//      add(new OctagonRoom(w, h, slope), 4 * rarity);
//      if (w != h) add(new OctagonRoom(h, w, slope), 4 * rarity);
//    }
//
//    octagon(5, 5, 1);
//    octagon(5, 7, 1, rarity: 2);
//    octagon(7, 7, 2);
//    octagon(7, 9, 2, rarity: 2);
//    octagon(9, 9, 2);
//    octagon(9, 9, 3);
//    octagon(9, 11, 2, rarity: 2);
//    octagon(9, 11, 3, rarity: 2);
//    octagon(11, 11, 3, rarity: 2);
//
//    TemplateRoom.initialize();
  }

  final Array2D<TileType> tiles;

  Room(this.tiles);
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

    return new Room(tiles);
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

    return new Room(tiles);
  }
}

//class OctagonRoom extends RoomType {
//  final int width;
//  final int height;
//  final int slope;
//
//  OctagonRoom(this.width, this.height, this.slope);
//
//  void place(Dungeon dungeon, Rect room) {
//    for (var pos in room) {
//      // Fill in the corners.
//      if ((room.topLeft - pos).rookLength < slope ||
//          (room.topRight - pos).rookLength < slope + 1 ||
//          (room.bottomLeft - pos).rookLength < slope + 1 ||
//          (room.bottomRight - pos).rookLength < slope + 2) {
//        dungeon.setTile(pos, Tiles.wall);
//      }
//    }
//
//    // TODO: Decorate inside?
//
//    dungeon.addConnector(room.center.x, room.top - 1);
//    dungeon.addConnector(room.center.x, room.bottom);
//    dungeon.addConnector(room.left - 1, room.center.y);
//    dungeon.addConnector(room.right, room.center.y);
//
//    decorate(dungeon, room);
//  }
//}
