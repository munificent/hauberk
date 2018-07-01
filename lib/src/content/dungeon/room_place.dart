import 'package:piecemeal/piecemeal.dart';

import 'place.dart';
import 'room.dart';

class RoomPlace extends Place {
  final RoomType _type;

  RoomPlace(this._type, List<Vec> cells, {bool hasHero = false})
      : super(cells, 0.05, 0.05, hasHero: hasHero);

  /// Picks a theme based on the shape and size of the room.
  void applyThemes() {
    addTheme(_type.theme, 2.0, spread: _type.spread);
    // TODO: Make theme affect monster and item density.
  }
}

class PassagePlace extends Place {
  PassagePlace(List<Vec> cells) : super(cells, 0.04, 0.02);

  void applyThemes() {
    addTheme("passage", 5.0, spread: false);
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
