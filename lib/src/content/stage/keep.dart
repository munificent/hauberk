import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'architect.dart';
import 'room.dart';

// TODO: Give at an optional max number of rooms so that it
// can be used to generate small concentrated areas on the stage. Create a
// separate "Dungeon" that works like Catacomb but uses rooms instead of blobs
// so that you get passages between them.

/// Places a number of connected rooms.
class Keep extends Architecture {
  static JunctionSet debugJunctions;

  // TODO: Fields to tune numbers below.

  final JunctionSet _junctions = JunctionSet();

  String get paintStyle => "stone";

  Iterable<String> build() sync* {
    debugJunctions = _junctions;

    // If we are covering the whole area, attempt to place multiple rooms.
    // That way, if there disconnected areas (like a river cutting through the
    // stage, we can still hopefully cover it all.
    var startingRooms = region == Region.everywhere ? 20 : 1;
    for (var i = 0; i < startingRooms; i++) {
      yield* _growRooms();
    }
  }

  Iterable<String> _growRooms() sync* {
    if (!_tryPlaceStartingRoom()) return;

    // Expand outward from it.
    while (_junctions.isNotEmpty) {
      var junction = _junctions.takeNext();

      // Make sure the junction is still valid. If other stuff has been placed
      // in its way since then, discard it.
      if (!canCarve(junction.position + junction.direction)) continue;

      if (_tryAttachRoom(junction)) {
        yield "Room";
        continue;
      }

      // TODO: Make tunable.
      if (junction.tries < 5) _junctions.add(junction);
    }
  }

  bool _tryPlaceStartingRoom() {
    var room = Room.create();
    for (var i = 0; i < 100; i++) {
      var pos = _startLocation(room);
      if (_tryPlaceRoom(room, pos.x, pos.y)) return true;
    }

    return false;
  }

  /// Pick a random location for [room] in [region].
  Vec _startLocation(Array2D<RoomTile> room) {
    var xMin = 1;
    var xMax = width - room.width - 1;
    var yMin = 1;
    var yMax = height - room.height - 1;

    switch (region) {
      case Region.nw:
      case Region.n:
      case Region.ne:
        yMax = math.max(1, (height * 0.25).toInt() - room.height);
        break;
      case Region.sw:
      case Region.s:
      case Region.se:
        yMin = (height * 0.75).toInt();
        break;
    }

    switch (region) {
      case Region.nw:
      case Region.w:
      case Region.sw:
        xMax = math.max(1, (width * 0.25).toInt() - room.width);
        break;
      case Region.ne:
      case Region.e:
      case Region.se:
        xMin = (width * 0.75).toInt();
        break;
    }

    return Vec(rng.range(xMin, xMax), rng.range(yMin, yMax));
  }

  /// Determines whether [pos] is within [region], with some randomness.
  bool _regionContains(Vec pos) {
    const min = -3.0;
    const max = 2.0;

    diagonal(int xDistance, yDistance) =>
        lerpDouble(xDistance + yDistance, 0, width + height, 2.0, -3.0);

    var density = 0.0;
    switch (region) {
      case Region.everywhere:
        return true;
      case Region.n:
        density = lerpDouble(pos.y, 0, height, max, min);
        break;
      case Region.ne:
        density = diagonal(width - pos.x - 1, pos.y);
        break;
      case Region.e:
        density = lerpDouble(pos.x, 0, width, min, max);
        break;
      case Region.se:
        density = diagonal(width - pos.x - 1, height - pos.y - 1);
        break;
      case Region.s:
        density = lerpDouble(pos.y, 0, height, min, max);
        break;
      case Region.sw:
        density = diagonal(pos.x, height - pos.y - 1);
        break;
      case Region.w:
        density = lerpDouble(pos.x, 0, width, max, min);
        break;
      case Region.nw:
        density = diagonal(pos.x, pos.y);
        break;
    }

    return rng.float(1.0) < density;
  }

  bool _tryAttachRoom(Junction junction) {
    var room = Room.create();

    // Try to find a junction that can mate with this one.
    var direction = junction.direction.rotate180;
    var junctions =
        room.bounds.where((pos) => room[pos].direction == direction).toList();
    rng.shuffle(junctions);

    for (var pos in junctions) {
      // Calculate the room position by lining up the junctions.
      var roomPos = junction.position - pos;
      if (_tryPlaceRoom(room, roomPos.x, roomPos.y)) return true;
    }

    return false;
  }

  bool _tryPlaceRoom(Array2D<RoomTile> room, int x, int y) {
    for (var pos in room.bounds) {
      var here = pos.offset(x, y);
      var tile = room[pos];

      if (!tile.isUnused && !bounds.contains(here)) return false;
      if (tile.isTile && !canCarve(pos.offset(x, y))) return false;
    }

    var junctions = <Junction>[];

    for (var pos in room.bounds) {
      var here = pos.offset(x, y);
      var tile = room[pos];

      if (tile.isJunction) {
        // Don't grow outside of the chosen region.
        if (_regionContains(here)) {
          junctions.add(Junction(here, tile.direction));
        }
      } else if (tile.isTile) {
        carve(here.x, here.y, tile.tile);
      } else if (tile.isWall) {
        preventPassage(here);
        _junctions.removeAt(here);
      }
    }

    // Shuffle the junctions so that the order we traverse the room tiles
    // doesn't bias the room growth.
    rng.shuffle(junctions);
    for (var junction in junctions) {
      // Remove any existing junctions since they now clash with the room.
      _junctions.removeAt(junction.position);
      _junctions.add(junction);
    }

    return true;
  }
}

class Junction {
  /// The location of the junction.
  final Vec position;

  /// Points from the first room towards where the new room should be attached.
  ///
  /// A room must have an opposing junction in order to match.
  final Direction direction;

  /// How many times we've tried to place something at this junction.
  int tries = 0;

  Junction(this.position, this.direction);
}

enum TakeFrom { newest, oldest, random }

class JunctionSet {
  // TODO: Let the architectural style control this.
  final TakeFrom _takeFrom = rng.item(TakeFrom.values);
  final Map<Vec, Junction> _byPosition = {};
  final List<Junction> _junctions = [];

  bool get isNotEmpty => _junctions.isNotEmpty;

  Junction operator [](Vec pos) => _byPosition[pos];

  void add(Junction junction) {
    assert(_byPosition[junction.position] == null);

    _byPosition[junction.position] = junction;
    _junctions.add(junction);
  }

  Junction takeNext() {
    Junction junction;
    switch (_takeFrom) {
      case TakeFrom.newest:
        junction = _junctions.removeLast();
        break;

      case TakeFrom.oldest:
        junction = _junctions.removeAt(0);
        break;

      case TakeFrom.random:
        junction = rng.take(_junctions);
        break;
    }

    _byPosition.remove(junction.position);
    junction.tries++;

    return junction;
  }

  void removeAt(Vec pos) {
    var junction = _byPosition.remove(pos);
    if (junction != null) _junctions.remove(junction);
  }
}
