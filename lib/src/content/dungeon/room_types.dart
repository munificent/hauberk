import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../themes.dart';
import '../tiles.dart';
import 'junction.dart';
import 'rooms.dart';

class RoomTypes {
  static RoomType tryChoose(int depth, String theme) {
    if (_resources.isEmpty) _initialize();

    return _resources.tryChoose(depth, theme);
  }

  static final ResourceSet<RoomType> _resources = ResourceSet();

  static void _initialize() {
    Themes.defineTags(_resources);

    // Special tag to mark rooms that can be starting rooms.
    _resources.defineTags("starting");

    // TODO: Tune frequencies.
    add(
        RectangleRoom("great-hall",
            spread: true, minWide: 8, maxWide: 16, minNarrow: 6, maxNarrow: 10),
        from: "chamber hall nature starting");
    add(
        RectangleRoom("kitchen",
            minWide: 4, maxWide: 7, minNarrow: 6, maxNarrow: 12),
        from: "great-hall");
    add(RectangleRoom("larder", maxWide: 6, maxNarrow: 5),
        frequency: 0.2, from: "kitchen");
    add(RectangleRoom("pantry", maxWide: 5, maxNarrow: 4),
        frequency: 0.1, from: "kitchen larder storeroom");

    add(RectangleRoom("chamber", minWide: 4, maxWide: 8, maxNarrow: 7),
        from: "chamber great-hall hall nature");

    add(RectangleRoom("closet", maxWide: 5, maxNarrow: 4),
        frequency: 0.1, from: "chamber laboratory storeroom");

    add(
        RectangleRoom("laboratory",
            spread: true, minWide: 4, maxWide: 10, maxNarrow: 8),
        from: "hall laboratory");

    add(
        RectangleRoom("storeroom",
            spread: true, minWide: 4, maxWide: 10, minNarrow: 4, maxNarrow: 10),
        from: "hall");

    add(
        RectangleRoom("hall",
            minWide: 6, maxWide: 16, minNarrow: 2, maxNarrow: 4),
        from: "nature passage starting storeroom");

    add(
        RectangleRoom("boss-chamber",
            monsterDensity: 2.0,
            monsterDepthOffset: 5,
            minWide: 8,
            maxWide: 16,
            minNarrow: 6,
            maxNarrow: 10),
        frequency: 0.3,
        from: "great-hall passage");

    add(
        RectangleRoom("treasure-room",
            monsterDensity: 0.5,
            itemDensity: 10.0,
            itemDepthOffset: 5,
            minWide: 4,
            maxWide: 12,
            minNarrow: 4,
            maxNarrow: 10),
        frequency: 0.3,
        from: "boss-chamber");

    // TODO: Custom classes for certain rooms:
    // - Great halls should usually have a big centered table, symmetric doors.
    // - Halls should have evenly placed doors.
    // - Etc.
    // TODO: Secret passages from closets.
  }

  /// Adds [type] to the set of room types. A room of this type can be created
  /// and attached to any existing room whose type is one of the
  /// space-separated names in [from].
  static void add(RoomType type, {double frequency, String from}) {
    // TODO: Different room types at different depths.
    _resources.add(type.theme, type, 1, frequency ?? 1.0, from);
  }
}

abstract class RoomType {
  // TODO: Use "theme" and "type" consistently.
  final String theme;
  final bool spread;
  final double monsterDensity;
  final int monsterDepthOffset;
  final double itemDensity;
  final int itemDepthOffset;

  RoomType(this.theme,
      {double monsterDensity,
      int monsterDepthOffset,
      double itemDensity,
      int itemDepthOffset,
      bool spread})
      : spread = spread ?? false,
        monsterDensity = monsterDensity ?? 1.0,
        monsterDepthOffset = monsterDepthOffset ?? 0,
        itemDensity = itemDensity ?? 1.0,
        itemDepthOffset = itemDepthOffset ?? 0;

  Room create();
}

/// A simple rectangular room type with junctions randomly spaced around it.
class RectangleRoom extends RoomType {
  final int minWide;
  final int maxWide;
  final int minNarrow;
  final int maxNarrow;

  RectangleRoom(String theme,
      {double monsterDensity,
      int monsterDepthOffset,
      double itemDensity,
      int itemDepthOffset,
      bool spread,
      int minWide,
      int maxWide,
      int minNarrow,
      int maxNarrow})
      : minWide = minWide ?? 3,
        maxWide = maxWide ?? 8,
        minNarrow = minNarrow ?? 3,
        maxNarrow = maxNarrow ?? 8,
        super(theme,
            monsterDensity: monsterDensity,
            monsterDepthOffset: monsterDepthOffset,
            itemDensity: itemDensity,
            itemDepthOffset: itemDepthOffset,
            spread: spread);

  Room create() {
    var width = rng.inclusive(minWide, maxWide);
    var height = rng.inclusive(minNarrow, maxNarrow);
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
      junctions.add(Junction(theme, Direction.n, Vec(i + 1, 0)));
    });

    _placeJunctions(width, (i) {
      junctions.add(Junction(theme, Direction.s, Vec(i + 1, height + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(theme, Direction.w, Vec(0, i + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(theme, Direction.e, Vec(width + 1, i + 1)));
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

// TODO: Maybe use blob rooms for things like worm pits?
//class BlobRoom extends RoomType {
//  Room create(RoomTheme theme) {
//    // TODO: Other size blobs.
//    var blob = Blob.make16();
//    // Note: Assumes the blob never has open cells at the very edge.
//    var tiles = new Array2D<TileType>(blob.width, blob.height);
//    for (var pos in tiles.bounds.inflate(-1)) {
//      if (blob[pos]) {
//        tiles[pos] = Tiles.floor;
//
//        // If this cell is at the edge of the blob, ensure there is a ring of
//        // wall around it.
//        for (var dir in Direction.all) {
//          var neighbor = pos + dir;
//          if (tiles[neighbor] != Tiles.floor) {
//            tiles[neighbor] = Tiles.wall;
//          }
//        }
//      }
//    }
//
//    // TODO: Place junctions.
//    return new Room(theme, tiles, []);
//  }
//}
