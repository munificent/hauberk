import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';
import 'room.dart';

// TODO: There's a lot of copy/paste between this and Catacomb. Decide if it's
// worth trying to refactor and share some code.

/// Places a number of random rooms.
class Dungeon extends Architecture {
  /// How many rooms it tries to place.
  final int _rooms;

  String get paintStyle => "stone";

  Dungeon({int rooms})
      : _rooms = rooms ?? 50;

  Iterable<String> build() sync* {
    // Randomize the number of rooms a bit.
    var tries = rng.triangleInt(_rooms, _rooms ~/ 2);

    // TODO: Number of rooms should take dungeon size and region into account.
    // What we're really going for is a certain density of open tiles to create.

    for (var i = 0; i < tries; i++) {
      var room = Room.create();

      for (var j = 0; j < 400; j++) {
        // TODO: This puts pretty hard boundaries around the region. Is there
        // a way to more softly distribute the rooms?
        var xMin = 1;
        var xMax = width - room.width;
        var yMin = 1;
        var yMax = height - room.height;

        switch (region) {
          case Region.everywhere:
            // Do nothing.
            break;
          case Region.n:
            yMax = height ~/ 2 - room.height;
            break;
          case Region.ne:
            xMin = width ~/ 2;
            yMax = height ~/ 2 - room.height;
            break;
          case Region.e:
            xMin = width ~/ 2;
            break;
          case Region.se:
            xMin = width ~/ 2;
            yMin = height ~/ 2;
            break;
          case Region.s:
            yMin = height ~/ 2;
            break;
          case Region.sw:
            xMax = width ~/ 2 - room.width;
            yMin = height ~/ 2;
            break;
          case Region.w:
            xMax = width ~/ 2 - room.width;
            break;
          case Region.nw:
            xMax = width ~/ 2 - room.width;
            yMax = height ~/ 2 - room.height;
            break;
        }

        var x = rng.range(xMin, xMax);
        var y = rng.range(yMin, yMax);

        if (_tryPlaceRoom(room, x, y)) {
          yield "room";
          break;
        }
      }
    }
  }

  bool _tryPlaceRoom(Array2D<RoomTile> room, int x, int y) {
    // TODO: keep.dart has the same code.
    for (var pos in room.bounds) {
      var here = pos.offset(x, y);
      var tile = room[pos];

      if (tile != RoomTile.unused && !bounds.contains(here)) return false;
      if (tile == RoomTile.floor && !canCarve(pos.offset(x, y))) return false;
    }

    for (var pos in room.bounds) {
      var here = pos.offset(x, y);

      switch (room[pos]) {
        case RoomTile.floor:
          carve(here.x, here.y);
          break;

        case RoomTile.wall:
          preventPassage(here);
          break;

      }
    }

    return true;
  }
}
