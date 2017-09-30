import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'dungeon.dart';
import 'template_rooms.dart';

abstract class RoomType {
  int get width;
  int get height;

  static ResourceSet<RoomType> _allTypes = new ResourceSet();

  // TODO: Hacky. ResourceSet assumes resources are named and have unique names.
  // Relax that constraint?
  static int _nextNameId = 0;

  static RoomType choose(int depth) {
    if (_allTypes.isEmpty) _initializeRoomTypes();

    // TODO: Take depth into account somehow.
    return _allTypes.tryChoose(1, "room");
  }

  static void add(RoomType type, int rarity) {
    _allTypes.add("room_${_nextNameId++}", type, 1, rarity, "room");
  }

  static void _initializeRoomTypes() {
    _allTypes.defineTags("room");

    rectangle(int w, int h, {int rarity: 1}) {
      add(new RectangleRoom(w, h), rarity);
      if (w != h) add(new RectangleRoom(h, w), rarity);
    }

    rectangle(3, 3, rarity: 2);
    rectangle(3, 5, rarity: 2);
    rectangle(5, 5);
    rectangle(5, 7);
    rectangle(7, 7);
    rectangle(5, 9);
    rectangle(7, 9);
    rectangle(9, 9);
    rectangle(7, 11);
    rectangle(9, 11);
    rectangle(11, 11, rarity: 2);
    rectangle(7, 13);
    rectangle(9, 13, rarity: 2);

    octagon(int w, int h, int slope, {int rarity: 1}) {
      // 4 * to make all octagonal rooms less common.
      add(new OctagonRoom(w, h, slope), 4 * rarity);
      if (w != h) add(new OctagonRoom(h, w, slope), 4 * rarity);
    }

    octagon(5, 5, 1);
    octagon(5, 7, 1, rarity: 2);
    octagon(7, 7, 2);
    octagon(7, 9, 2, rarity: 2);
    octagon(9, 9, 2);
    octagon(9, 9, 3);
    octagon(9, 11, 2, rarity: 2);
    octagon(9, 11, 3, rarity: 2);
    octagon(11, 11, 3, rarity: 2);

    TemplateRoom.initialize();
  }

  /// Fill in the bounds of [room] with this room's individual style.
  ///
  /// Also, add any connectors as are possible from the room.
  ///
  /// When this is called, [room] will already be cleared to all floor.
  void place(OldDungeon dungeon, Rect room);

  void decorate(OldDungeon dungeon, Rect room) {
    if (rng.oneIn(2)) {
      var tables = rng.inclusive(1, 3);
      for (var i = 0; i < tables; i++) {
        decorateTable(dungeon, room);
      }
    }
  }

  /// Tries to place a table in the room.
  bool decorateTable(OldDungeon dungeon, Rect room) {
    var pos = rng.vecInRect(room);

    if (dungeon.getTile(pos) != Tiles.floor) return false;

    // Don't block an exit.
    if (pos.x == room.left && dungeon.getTile(pos.offsetX(-1)) != Tiles.wall) {
      return false;
    }

    if (pos.y == room.top && dungeon.getTile(pos.offsetY(-1)) != Tiles.wall) {
      return false;
    }

    if (pos.x == room.right && dungeon.getTile(pos.offsetX(1)) != Tiles.wall) {
      return false;
    }

    if (pos.y == room.bottom && dungeon.getTile(pos.offsetY(1)) != Tiles.wall) {
      return false;
    }

    dungeon.setTile(pos, Tiles.table);
    return true;
  }
}

class RectangleRoom extends RoomType {
  final int width;
  final int height;

  RectangleRoom(this.width, this.height);

  void place(OldDungeon dungeon, Rect room) {
    for (var x = room.left; x < room.right; x++) {
      dungeon.addConnector(x, room.top - 1);
      dungeon.addConnector(x, room.bottom);
    }

    for (var y = room.top; y < room.bottom; y++) {
      dungeon.addConnector(room.left - 1, y);
      dungeon.addConnector(room.right, y);
    }

    decorate(dungeon, room);
  }
}

class OctagonRoom extends RoomType {
  final int width;
  final int height;
  final int slope;

  OctagonRoom(this.width, this.height, this.slope);

  void place(OldDungeon dungeon, Rect room) {
    for (var pos in room) {
      // Fill in the corners.
      if ((room.topLeft - pos).rookLength < slope ||
          (room.topRight - pos).rookLength < slope + 1 ||
          (room.bottomLeft - pos).rookLength < slope + 1 ||
          (room.bottomRight - pos).rookLength < slope + 2) {
        dungeon.setTile(pos, Tiles.wall);
      }
    }

    // TODO: Decorate inside?

    dungeon.addConnector(room.center.x, room.top - 1);
    dungeon.addConnector(room.center.x, room.bottom);
    dungeon.addConnector(room.left - 1, room.center.y);
    dungeon.addConnector(room.right, room.center.y);

    decorate(dungeon, room);
  }
}
