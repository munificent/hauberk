import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'place.dart';
import 'room.dart';

class RoomPlace extends Place {
  final Room _room;

  RoomPlace(this._room, List<Vec> cells, {bool hasHero = false})
      : super(cells, 0.05, 0.05, hasHero: hasHero);

  /// Picks a theme based on the shape and size of the room.
  void applyThemes() {
    // TODO: take passages into account when looking to see which neighboring
    // rooms are dead ends.

    // TODO: Make RoomStyle affect monster and item density.

    // TODO: This isn't quite there yet:
    //
    // * The way parents filter out room styles means a room may fail to match
    //   which would succeed later after a neighbor gets placed as a parent.
    //   Consider doing this iteratively or otherwise trying multiple times.
    //
    // * It still generates nearby rooms that don't make sense. You can get a
    //   chamber that leads to a kitchen, etc.
    //
    // Maybe it should be bottom-up. Start with the dead-end rooms and pick
    // themes for those: closet, larder, etc. Then look for rooms whose
    // neighbors have those and place kitchen, etc.?
    var styles = RoomStyle.all.where((style) => style.matches(this)).toList();
    if (styles.isNotEmpty) {
      // TODO: Use ResourceSet and tune frequencies and depth.
      // TODO: Let each theme have its own intensity so that more interesting
      // themes like "laboratory" spread more.
      addTheme(rng.item(styles).theme, 1.0);
    } else {
      addTheme("room", 1.0, spread: false);
    }
  }
}

class PassagePlace extends Place {
  PassagePlace(List<Vec> cells) : super(cells, 0.04, 0.02);

  void applyThemes() {
    addTheme("passage", 10.0, spread: false);
  }
}

class RoomStyle {
  static final _all = <RoomStyle>[];

  RoomStyle(this.theme,
      {List<String> parents = const [],
      this.minExits = 0,
      this.maxExits = 100,
      this.minNarrow = 0,
      this.maxNarrow = 100,
      this.minWide = 0,
      this.maxWide = 100}) {
    this.parents.addAll(parents);
  }

  static List<RoomStyle> get all {
    if (_all.isEmpty) _initialize();
    return _all;
  }

  static void _initialize() {
    // TODO: Validate that these all exist in themes.dart?
    _room("great-hall", minExits: 3, minNarrow: 5, minWide: 7);
    _room("kitchen",
        maxExits: 4, minExits: 2, maxWide: 7, parents: ["great-hall"]);
    _room("larder", maxExits: 2, maxWide: 8, parents: ["kitchen"]);
    _room("pantry", maxExits: 1, maxWide: 6, parents: ["kitchen"]);
    _room("chamber", minExits: 2, maxExits: 2, maxWide: 7);
    _room("laboratory", maxExits: 2, minWide: 5, maxWide: 8);
    _room("closet",
        maxExits: 1,
        maxWide: 4,
        parents: ["chamber", "great-hall", "laboratory"]);
    _room("storeroom", maxExits: 1, maxWide: 5);
    // TODO: More.
  }

  static void _room(String name,
      {List<String> parents = const [],
      int minExits = 0,
      int maxExits = 100,
      int minNarrow = 0,
      int maxNarrow = 100,
      int minWide = 0,
      int maxWide = 100}) {
    _all.add(new RoomStyle(name,
        parents: parents,
        minExits: minExits,
        maxExits: maxExits,
        minNarrow: minNarrow,
        maxNarrow: maxNarrow,
        minWide: minWide,
        maxWide: maxWide));
  }

  final String theme;
  final int minExits;
  final int maxExits;

  final int minNarrow;

  final int maxNarrow;

  final int minWide;

  final int maxWide;

  final Set<String> parents = new Set();

  bool matches(RoomPlace place) {
    if (place.neighbors.length < minExits) return false;
    if (place.neighbors.length > maxExits) return false;

    var tiles = place._room.tiles;
    var shortest = math.min(tiles.width - 2, tiles.height - 2);
    var longest = math.max(tiles.width - 2, tiles.height - 2);
    if (shortest < minNarrow) return false;
    if (shortest > maxNarrow) return false;
    if (longest < minWide) return false;
    if (longest > maxWide) return false;

    if (parents.isEmpty) return true;

    var neighborThemes = new Set<String>();
    for (var neighbor in place.neighbors) {
      neighborThemes.addAll(neighbor.themes.keys);
    }

    return parents.intersection(neighborThemes).isNotEmpty;
  }
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
//  int get minExits => 1;
//
//  int get maxExits => 1;
//
//  int get minNarrowDimension => 3;
//
//  int get maxNarrowDimension => 3;
//
//  int get minWideDimension => 3;
//
//  int get maxWideDimension => 7;
//
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
