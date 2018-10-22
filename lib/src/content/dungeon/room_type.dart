import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../stage/blob.dart';
import '../tiles.dart';
import 'architecture.dart';
import 'junction.dart';
import 'rooms.dart';

abstract class RoomType {
  final String theme;

  RoomType(this.theme);

  // TODO: Should arch be passed in or part of the room type itself?
  Room create(Architecture architecture);
}

/// A simple rectangular room type with junctions randomly spaced around it.
class RectangleRoom extends RoomType {
  final int _maxDimension;

  RectangleRoom(String theme, this._maxDimension) : super(theme);

  Room create(Architecture architecture) {
    // TODO: Constrain aspect ratio?
    var width = rng.inclusive(3, _maxDimension);
    var height = rng.inclusive(3, _maxDimension);
    if (rng.oneIn(2)) {
      var temp = width;
      width = height;
      height = temp;
    }

    var tiles = Array2D<TileType>(width + 2, height + 2, Tiles.floor);

    for (var y = 0; y < tiles.height; y++) {
      tiles.set(0, y, Tiles.wall);
      tiles.set(tiles.width - 1, y, Tiles.wall);
    }

    for (var x = 0; x < tiles.width; x++) {
      tiles.set(x, 0, Tiles.wall);
      tiles.set(x, tiles.height - 1, Tiles.wall);
    }

    // TODO: Consider placing the junctions symmetrically sometimes.
    var junctions = <Junction>[];
    _placeJunctions(width, (i) {
      junctions.add(Junction(architecture, Direction.n, Vec(i + 1, 0)));
    });

    _placeJunctions(width, (i) {
      junctions
          .add(Junction(architecture, Direction.s, Vec(i + 1, height + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(architecture, Direction.w, Vec(0, i + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(architecture, Direction.e, Vec(width + 1, i + 1)));
    });

    return Room(this, tiles, junctions);
  }

  /// Walks along [length], invoking [callback] at values where a junction
  /// should be placed.
  ///
  /// Ensures two junctions are not placed next to each other.
  void _placeJunctions(int length, void Function(int) callback) {
    var start = rng.oneIn(2) ? 0 : 1;
    for (var i = start; i < length; i++) {
      // TODO: Make chances tunable.
      if (rng.percent(40)) {
        callback(i);

        // Don't allow two junctions right next to each other.
        i++;
      }
    }
  }
}

class BlobRoom extends RoomType {
  BlobRoom(String theme) : super(theme);

  Room create(Architecture architecture) {
    // TODO: This is quite slow. Consider reusing blob rooms that couldn't be
    // successfully placed in one location.
    Array2D<bool> blob;
    if (rng.oneIn(4)) {
      blob = Blob.make32();
    } else {
      blob = Blob.make16();
    }

    // Note: Assumes the blob never has open cells at the very edge.
    var tiles = new Array2D<TileType>(blob.width, blob.height);
    for (var pos in tiles.bounds.inflate(-1)) {
      if (blob[pos]) {
        tiles[pos] = Tiles.floor;

        // If this cell is at the edge of the blob, ensure there is a ring of
        // wall around it.
        for (var neighbor in pos.neighbors) {
          if (tiles[neighbor] != Tiles.floor) {
            // TODO: Instead of walls, should do rock.
            tiles[neighbor] = Tiles.wall;
          }
        }
      }
    }

    var junctions = <Junction>[];
    for (var pos in tiles.bounds.inflate(-1)) {
      if (tiles[pos] != Tiles.wall) continue;

      for (var dir in Direction.cardinal) {
        // Must point past the edge of the room.
        var ahead = pos + dir;
        if (tiles.bounds.contains(ahead) && tiles[ahead] != null) continue;

        // And come from the floor.
        var back = pos - dir;
        if (!tiles.bounds.contains(back) || tiles[back] != Tiles.floor) {
          continue;
        }

        // With walls on either side.
        var left = pos + dir.rotateLeft90;
        if (!tiles.bounds.contains(left) || tiles[left] != Tiles.wall) {
          continue;
        }

        var right = pos + dir.rotateRight90;
        if (!tiles.bounds.contains(right) || tiles[right] != Tiles.wall) {
          continue;
        }

        junctions.add(Junction(architecture, dir, pos));
      }
    }

    return new Room(this, tiles, junctions);
  }
}

/// Used to see if there is already a path between two points in the dungeon
/// before adding an extra door between two areas.
class CyclePathfinder extends Pathfinder<bool> {
  final int _maxLength;

  CyclePathfinder(Stage stage, Vec start, Vec end, this._maxLength)
      : super(stage, start, end);

  bool processStep(Path path) {
    if (path.length >= _maxLength) return false;

    return null;
  }

  bool reachedGoal(Path path) => true;

  int stepCost(Vec pos, Tile tile) {
    if (tile.canEnter(Motility.doorAndWalk)) return 1;

    return null;
  }

  bool unreachableGoal() => false;
}

// TODO: Delete. Figure out what to do with stair room and wall torch code.
//class PlainRoom extends RoomStyle {
//  void decorate(RoomPlace place, Dungeon dungeon) {
//    _tryPlaceDoorTorches(place, dungeon);
//  }
//
//  /// Try to place some torches around doors.
//  void _tryPlaceDoorTorches(RoomPlace place, Dungeon dungeon) {
//    // TODO: Make these more strategic.
//    canPlaceTorchAt(int x, int y) {
//      if (dungeon.getTile(x, y) != Tiles.wall) return false;
//
//      return true;
//    }
//
//    for (var junction in place._room.junctions) {
//      var pos = junction.position + place._pos;
//
//      if (dungeon.getTileAt(pos) != Tiles.closedDoor) continue;
//      if (!rng.oneIn(5)) continue;
//
//      if (canPlaceTorchAt(pos.x - 1, pos.y) &&
//          canPlaceTorchAt(pos.x + 1, pos.y)) {
//        dungeon.setTile(pos.x - 1, pos.y, Tiles.wallTorch);
//        dungeon.setTile(pos.x + 1, pos.y, Tiles.wallTorch);
//      } else if (canPlaceTorchAt(pos.x, pos.y - 1) &&
//          canPlaceTorchAt(pos.x, pos.y + 1)) {
//        dungeon.setTile(pos.x, pos.y - 1, Tiles.wallTorch);
//        dungeon.setTile(pos.x, pos.y + 1, Tiles.wallTorch);
//      }
//    }
//  }
//}
//
//class SmallStairRoom extends RoomStyle {
//  void decorate(RoomPlace place, Dungeon dungeon) {
//    var bounds =
//        place._room.tiles.bounds.inflate(-1).offset(place._pos.x, place._pos.y);
//
//    // Place the stairs in the middle.
//    var stairs = rng.vecInRect(bounds.inflate(-1));
//    dungeon.setTileAt(stairs, Tiles.stairs);
//
//    if (rng.oneIn(3)) _addTorches(bounds, place, dungeon);
//  }
//
//  void _addTorches(Rect bounds, RoomPlace place, Dungeon dungeon) {
//    // Find out which corners permit torches.
//    var left = bounds.left;
//    var right = bounds.right - 1;
//    var top = bounds.top;
//    var bottom = bounds.bottom - 1;
//
//    var canTopLeft = dungeon.getTile(left - 1, top) == Tiles.wall &&
//        dungeon.getTile(left, top - 1) == Tiles.wall;
//
//    var canTopRight = dungeon.getTile(right + 1, top) == Tiles.wall &&
//        dungeon.getTile(right, top - 1) == Tiles.wall;
//
//    var canBottomLeft = dungeon.getTile(left - 1, bottom) == Tiles.wall &&
//        dungeon.getTile(left, bottom + 1) == Tiles.wall;
//
//    var canBottomRight = dungeon.getTile(right + 1, bottom) == Tiles.wall &&
//        dungeon.getTile(right, bottom + 1) == Tiles.wall;
//
//    // Place torches in the corners when we can do adjacent pairs.
//    if (canTopLeft && canTopRight) {
//      dungeon.setTile(left, top, Tiles.wallTorch);
//      dungeon.setTile(right, top, Tiles.wallTorch);
//    }
//
//    if (canBottomLeft && canBottomRight) {
//      dungeon.setTile(left, bottom, Tiles.wallTorch);
//      dungeon.setTile(right, bottom, Tiles.wallTorch);
//    }
//
//    if (canTopLeft && canBottomLeft) {
//      dungeon.setTile(left, top, Tiles.wallTorch);
//      dungeon.setTile(left, bottom, Tiles.wallTorch);
//    }
//
//    if (canTopRight && canBottomRight) {
//      dungeon.setTile(right, top, Tiles.wallTorch);
//      dungeon.setTile(right, bottom, Tiles.wallTorch);
//    }
//  }
//}
