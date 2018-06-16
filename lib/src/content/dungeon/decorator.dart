import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';
import 'room.dart';

class Decorator {
  final Dungeon _dungeon;
  final List<PlacedRoom> _rooms;

  Decorator(this._dungeon, this._rooms);

  Iterable<String> decorate() sync* {
    // TODO: Decorate some rooms with light.

    for (var placed in _rooms) {
      if (rng.oneIn(3)) {
        // TODO: These are placed after the hero's location is chosen which
        // means sometimes the hero gets spawned on top of a decoration. Fix.
        _tryPlaceTable(placed);
      }
    }

    // TODO: "Zoo" monster pits with themed decorations and terrain to match
    // (grass and trees for animal pits, etc.).

    // Try to place some torches around doors.
    // TODO: Make these more strategic.
    canPlaceTorchAt(int x, int y) {
      if (_dungeon.getTile(x, y) != Tiles.wall) return false;

      return true;
    }

    for (var y = 1; y < _dungeon.height - 1; y++) {
      for (var x = 1; x < _dungeon.width - 1; x++) {
        if (!rng.oneIn(5)) continue;

        if (_dungeon.getTile(x, y) != Tiles.closedDoor) continue;
        if (canPlaceTorchAt(x - 1, y) && canPlaceTorchAt(x + 1, y)) {
          _dungeon.setTile(x - 1, y, Tiles.wallTorch);
          _dungeon.setTile(x + 1, y, Tiles.wallTorch);
        } else if (canPlaceTorchAt(x, y - 1) && canPlaceTorchAt(x, y + 1)) {
          _dungeon.setTile(x, y - 1, Tiles.wallTorch);
          _dungeon.setTile(x, y + 1, Tiles.wallTorch);
        }
      }
    }
  }

  void _tryPlaceTable(PlacedRoom placed) {
    var roomWidth = placed.room.tiles.width - 2;
    var roomHeight = placed.room.tiles.height - 2;

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

      if (_tryPlaceTableAt(placed, x, y, width, height)) return;
    }

    // Try a smaller centered table.
    if (roomWidth > 5 && roomHeight > 5 && rng.percent(30)) {
      var width = roomWidth - 4;
      var height = roomHeight - 4;
      if (_tryPlaceTableAt(placed, 3, 3, width, height)) return;
    }

    // Try a randomly placed table.
    for (var i = 0; i < 30; i++) {
      var width = rng.inclusive(2, math.min(5, roomWidth - 2));
      var height = rng.inclusive(2, math.min(5, roomHeight - 2));

      var x = rng.range(2, roomWidth - width + 1);
      var y = rng.range(2, roomHeight - height + 1);

      if (_tryPlaceTableAt(placed, x, y, width, height)) return;
    }
  }

  bool _tryPlaceTableAt(
      PlacedRoom placed, int x, int y, int width, int height) {
    // Make sure the table isn't blocked.
    for (var y1 = 0; y1 < height; y1++) {
      for (var x1 = 0; x1 < width; x1++) {
        var pos = placed.pos.offset(x + x1, y + y1);
        if (_dungeon.getTileAt(pos) != Tiles.floor) return false;
      }
    }

    for (var y1 = 1; y1 < height - 1; y1++) {
      for (var x1 = 1; x1 < width - 1; x1++) {
        var pos = placed.pos.offset(x + x1, y + y1);

        if (rng.oneIn(3)) {
          _dungeon.setTileAt(pos, Tiles.candle);
        } else {
          _dungeon.setTileAt(pos, Tiles.tableCenter);
        }
      }
    }

    _dungeon.setTileAt(placed.pos.offset(x, y), Tiles.tableTopLeft);
    _dungeon.setTileAt(
        placed.pos.offset(x + width - 1, y), Tiles.tableTopRight);
    _dungeon.setTileAt(
        placed.pos.offset(x, y + height - 1), Tiles.tableBottomLeft);
    _dungeon.setTileAt(placed.pos.offset(x + width - 1, y + height - 1),
        Tiles.tableBottomRight);

    for (var x1 = 1; x1 < width - 1; x1++) {
      _dungeon.setTileAt(placed.pos.offset(x + x1, y), Tiles.tableTop);
      _dungeon.setTileAt(
          placed.pos.offset(x + x1, y + height - 1), Tiles.tableBottom);
    }

    for (var y1 = 1; y1 < height - 1; y1++) {
      _dungeon.setTileAt(placed.pos.offset(x, y + y1), Tiles.tableLeft);
      _dungeon.setTileAt(
          placed.pos.offset(x + width - 1, y + y1), Tiles.tableRight);
    }

    if (width <= 3 || rng.oneIn(2)) {
      _dungeon.setTileAt(
          placed.pos.offset(x, y + height - 1), Tiles.tableLegLeft);
      _dungeon.setTileAt(placed.pos.offset(x + width - 1, y + height - 1),
          Tiles.tableLegRight);
    } else {
      _dungeon.setTileAt(
          placed.pos.offset(x + 1, y + height - 1), Tiles.tableLeg);
      _dungeon.setTileAt(
          placed.pos.offset(x + width - 2, y + height - 1), Tiles.tableLeg);
    }

    return true;
  }
}
