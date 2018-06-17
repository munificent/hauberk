import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';
import 'room.dart';

class RoomPlace extends Place {
  final Vec _pos;
  final Room _room;

  RoomPlace(this._pos, this._room, List<Vec> cells, {bool hasHero})
      : super("room", cells, hasHero: hasHero);

  void decorate(Dungeon dungeon) {
    var exits = 0;
    for (var junction in _room.junctions) {
      var pos = junction.position + _pos;
      if (dungeon.getTileAt(pos).isTraversable) exits++;
    }

    // TODO: Assumes rectangular rooms.
    var narrow = _room.tiles.width - 2;
    var wide = _room.tiles.height - 2;
    if (narrow > wide) {
      var temp = narrow;
      narrow = wide;
      wide = temp;
    }

    // TODO: Calculate some larger properties of the dungeon first and then
    // pass those in so we can have smarter styles for things like rooms that
    // are farther from the start location, near other biomes, etc.
    var styles = RoomStyle.all.where((style) {
      if (exits < style.minExits) return false;
      if (exits > style.maxExits) return false;
      if (narrow < style.minNarrowDimension) return false;
      if (narrow > style.maxNarrowDimension) return false;
      if (wide < style.minWideDimension) return false;
      if (wide > style.maxWideDimension) return false;
      return true;
    }).toList();

    assert(styles.isNotEmpty, "Should have at least one style for any room.");

    // TODO: Weighted probabilities. Maybe use ResourceSet?
    var style = rng.item(styles);
    style.decorate(this, dungeon);

    // TODO: Change the door types too.
  }
}

class PassagePlace extends Place {
  PassagePlace(List<Vec> cells) : super("passage", cells);
}

abstract class RoomStyle {
  static final _all = <RoomStyle>[];

  static List<RoomStyle> get all {
    if (_all.isEmpty) _initialize();
    return _all;
  }

  static void _initialize() {
    // 1 exit -> dead end
    // 2 exits -> passageway
    // more exits -> central hall

    // how large it is
    // small -> closet, storage
    // large -> great hall, jail, boss, etc.

    // aspect ratio
    // squarish -> interesting themes
    // long -> hall, dining hall

    // TODO: "Zoo" monster pits with themed decorations and terrain to match
    // (grass and trees for animal pits, etc.).

    _all.add(new SmallStairRoom());
    _all.add(new PlainRoom());
  }

  int get minExits => 0;

  int get maxExits => 100;

  int get minNarrowDimension => 1;

  int get maxNarrowDimension => 100;

  int get minWideDimension => 1;

  int get maxWideDimension => 100;

  void decorate(RoomPlace place, Dungeon dungeon);
}

class PlainRoom extends RoomStyle {
  void decorate(RoomPlace place, Dungeon dungeon) {
    // Nothing.

    // TODO: Move this out of plain and have separate room styles for ones with
    // tables.
    if (rng.oneIn(3)) {
      // TODO: These are placed after the hero's location is chosen which
      // means sometimes the hero gets spawned on top of a decoration. Fix.
      _tryPlaceTable(place, dungeon);
    }

    // TODO: "Zoo" monster pits with themed decorations and terrain to match
    // (grass and trees for animal pits, etc.).

    _tryPlaceDoorTorches(place, dungeon);
  }

  void _tryPlaceTable(RoomPlace place, Dungeon dungeon) {
    var roomWidth = place._room.tiles.width - 2;
    var roomHeight = place._room.tiles.height - 2;

    if (roomWidth < 6) return;
    if (roomHeight < 6) return;

    // Try a big centered table.
    if (rng.percent(30)) {
      var x = 2;
      var y = 2;
      var width = roomWidth - 2;
      var height = roomHeight - 2;

      if (width > 4 && height > 4) {
        if (roomWidth < roomHeight || roomWidth == roomHeight && rng.oneIn(2)) {
          width = 4 - (roomWidth % 2);
          x = 1 + (roomWidth - width) ~/ 2;
        } else {
          height = 4 - (roomHeight % 2);
          y = 1 + (roomHeight - height) ~/ 2;
        }
      }

      if (_tryPlaceTableAt(place, dungeon, x, y, width, height)) return;
    }

    // Try a smaller centered table.
    if (roomWidth > 5 && roomHeight > 5 && rng.percent(30)) {
      var width = roomWidth - 4;
      var height = roomHeight - 4;
      if (_tryPlaceTableAt(place, dungeon, 3, 3, width, height)) return;
    }

    // Try a randomly placed table.
    for (var i = 0; i < 30; i++) {
      var width = rng.inclusive(2, math.min(5, roomWidth - 2));
      var height = rng.inclusive(2, math.min(5, roomHeight - 2));

      var x = rng.range(2, roomWidth - width + 1);
      var y = rng.range(2, roomHeight - height + 1);

      if (_tryPlaceTableAt(place, dungeon, x, y, width, height)) return;
    }
  }

  bool _tryPlaceTableAt(
      RoomPlace place, Dungeon dungeon, int x, int y, int width, int height) {
    // Make sure the table isn't blocked.
    for (var y1 = 0; y1 < height; y1++) {
      for (var x1 = 0; x1 < width; x1++) {
        var pos = place._pos.offset(x + x1, y + y1);
        if (dungeon.getTileAt(pos) != Tiles.floor) return false;
      }
    }

    for (var y1 = 1; y1 < height - 1; y1++) {
      for (var x1 = 1; x1 < width - 1; x1++) {
        var pos = place._pos.offset(x + x1, y + y1);

        if (rng.oneIn(3)) {
          dungeon.setTileAt(pos, Tiles.candle);
        } else {
          dungeon.setTileAt(pos, Tiles.tableCenter);
        }
      }
    }

    dungeon.setTileAt(place._pos.offset(x, y), Tiles.tableTopLeft);
    dungeon.setTileAt(place._pos.offset(x + width - 1, y), Tiles.tableTopRight);
    dungeon.setTileAt(
        place._pos.offset(x, y + height - 1), Tiles.tableBottomLeft);
    dungeon.setTileAt(place._pos.offset(x + width - 1, y + height - 1),
        Tiles.tableBottomRight);

    for (var x1 = 1; x1 < width - 1; x1++) {
      dungeon.setTileAt(place._pos.offset(x + x1, y), Tiles.tableTop);
      dungeon.setTileAt(
          place._pos.offset(x + x1, y + height - 1), Tiles.tableBottom);
    }

    for (var y1 = 1; y1 < height - 1; y1++) {
      dungeon.setTileAt(place._pos.offset(x, y + y1), Tiles.tableLeft);
      dungeon.setTileAt(
          place._pos.offset(x + width - 1, y + y1), Tiles.tableRight);
    }

    if (width <= 3 || rng.oneIn(2)) {
      dungeon.setTileAt(
          place._pos.offset(x, y + height - 1), Tiles.tableLegLeft);
      dungeon.setTileAt(place._pos.offset(x + width - 1, y + height - 1),
          Tiles.tableLegRight);
    } else {
      dungeon.setTileAt(
          place._pos.offset(x + 1, y + height - 1), Tiles.tableLeg);
      dungeon.setTileAt(
          place._pos.offset(x + width - 2, y + height - 1), Tiles.tableLeg);
    }

    return true;
  }

  /// Try to place some torches around doors.
  void _tryPlaceDoorTorches(RoomPlace place, Dungeon dungeon) {
    // TODO: Make these more strategic.
    canPlaceTorchAt(int x, int y) {
      if (dungeon.getTile(x, y) != Tiles.wall) return false;

      return true;
    }

    for (var junction in place._room.junctions) {
      var pos = junction.position + place._pos;

      if (dungeon.getTileAt(pos) != Tiles.closedDoor) continue;
      if (!rng.oneIn(5)) continue;

      if (canPlaceTorchAt(pos.x - 1, pos.y) &&
          canPlaceTorchAt(pos.x + 1, pos.y)) {
        dungeon.setTile(pos.x - 1, pos.y, Tiles.wallTorch);
        dungeon.setTile(pos.x + 1, pos.y, Tiles.wallTorch);
      } else if (canPlaceTorchAt(pos.x, pos.y - 1) &&
          canPlaceTorchAt(pos.x, pos.y + 1)) {
        dungeon.setTile(pos.x, pos.y - 1, Tiles.wallTorch);
        dungeon.setTile(pos.x, pos.y + 1, Tiles.wallTorch);
      }
    }
  }
}

class SmallStairRoom extends RoomStyle {
  int get minExits => 1;

  int get maxExits => 1;

  int get minNarrowDimension => 3;

  int get maxNarrowDimension => 3;

  int get minWideDimension => 3;

  int get maxWideDimension => 7;

  void decorate(RoomPlace place, Dungeon dungeon) {
    var bounds =
        place._room.tiles.bounds.inflate(-1).offset(place._pos.x, place._pos.y);

    // Place the stairs in the middle.
    var stairs = rng.vecInRect(bounds.inflate(-1));
    dungeon.setTileAt(stairs, Tiles.stairs);

    if (rng.oneIn(3)) _addTorches(bounds, place, dungeon);
  }

  void _addTorches(Rect bounds, RoomPlace place, Dungeon dungeon) {
    // Find out which corners permit torches.
    var left = bounds.left;
    var right = bounds.right - 1;
    var top = bounds.top;
    var bottom = bounds.bottom - 1;

    var canTopLeft = dungeon.getTile(left - 1, top) == Tiles.wall &&
        dungeon.getTile(left, top - 1) == Tiles.wall;

    var canTopRight = dungeon.getTile(right + 1, top) == Tiles.wall &&
        dungeon.getTile(right, top - 1) == Tiles.wall;

    var canBottomLeft = dungeon.getTile(left - 1, bottom) == Tiles.wall &&
        dungeon.getTile(left, bottom + 1) == Tiles.wall;

    var canBottomRight = dungeon.getTile(right + 1, bottom) == Tiles.wall &&
        dungeon.getTile(right, bottom + 1) == Tiles.wall;

    // Place torches in the corners when we can do adjacent pairs.
    if (canTopLeft && canTopRight) {
      dungeon.setTile(left, top, Tiles.wallTorch);
      dungeon.setTile(right, top, Tiles.wallTorch);
    }

    if (canBottomLeft && canBottomRight) {
      dungeon.setTile(left, bottom, Tiles.wallTorch);
      dungeon.setTile(right, bottom, Tiles.wallTorch);
    }

    if (canTopLeft && canBottomLeft) {
      dungeon.setTile(left, top, Tiles.wallTorch);
      dungeon.setTile(left, bottom, Tiles.wallTorch);
    }

    if (canTopRight && canBottomRight) {
      dungeon.setTile(right, top, Tiles.wallTorch);
      dungeon.setTile(right, bottom, Tiles.wallTorch);
    }
  }
}
