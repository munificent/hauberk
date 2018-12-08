import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';
import 'room.dart';

// TODO: There's a lot of copy/paste between this and Catacomb. Decide if it's
// worth trying to refactor and share some code.

/// Places a number of random rooms.
class Dungeon extends Architecture {
  /// How much open space it tries to carve.
  final double _density;

  String get paintStyle => "stone";

  Dungeon({double density}) : _density = density ?? 0.3;

  Iterable<String> build() sync* {
    var failed = 0;
    while (carvedDensity < _density && failed < 100) {
      var room = Room.create(depth);

      var placed = false;
      for (var i = 0; i < 400; i++) {
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

        // TODO: Instead of purely random, it would be good if it tried to
        // place rooms as far from other rooms as possible to maximize passage
        // length and more evenly distribute them.
        var x = rng.range(xMin, xMax);
        var y = rng.range(yMin, yMax);

        if (_tryPlaceRoom(room, x, y)) {
          yield "room";
          placed = true;
          break;
        }
      }

      if (!placed) failed++;
    }
  }

  bool _tryPlaceRoom(Array2D<RoomTile> room, int x, int y) {
    // TODO: keep.dart has the same code.
    for (var pos in room.bounds) {
      var here = pos.offset(x, y);
      var tile = room[pos];

      if (!tile.isUnused && !bounds.contains(here)) return false;
      if (tile.isTile && !canCarve(pos.offset(x, y))) return false;
    }

    for (var pos in room.bounds) {
      var here = pos.offset(x, y);
      var tile = room[pos];

      if (tile.isTile) {
        carve(here.x, here.y, tile.tile);
      } else if (tile.isWall) {
        preventPassage(here);
      }
    }

    return true;
  }
}
