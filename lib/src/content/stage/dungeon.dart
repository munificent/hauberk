import 'dart:collection';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'architect.dart';

/// Places a number of connected rooms.
class Dungeon extends Architecture {
  static JunctionSet debugJunctions;

  // TODO: Fields to tune numbers below.
  // TODO: Different room shapes.

  final JunctionSet _junctions = JunctionSet();

  Iterable<String> build(Region region) sync* {
    debugJunctions = _junctions;

    var room = _createRoom();
    for (var i = 0; i < 100; i++) {
      var pos = _startLocation(region, room);
      if (_tryPlaceRoom(room, pos.x, pos.y)) break;
    }

    while (_junctions.isNotEmpty) {
      var junction = _junctions.takeNext();

      if (!_regionContains(region, junction.position)) continue;

      // Make sure the junction is still valid. If other stuff has been placed
      // in its way since then, discard it.
      if (!canCarve(junction.position + junction.direction)) continue;

      // TODO: Passages.

      if (_tryAttachRoom(junction)) {
        yield "Room";
        continue;
      }

      // TODO: Make tunable.
      if (junction.tries < 10) _junctions.add(junction);
    }
  }

  /// Pick a random location for [room] in [region].
  Vec _startLocation(Region region, Array2D<RoomTile> room) {
    var xMin = 1;
    var xMax = width - room.width - 1;
    var yMin = 1;
    var yMax = height - room.height - 1;

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

    return Vec(rng.range(xMin, xMax), rng.range(yMin, yMax));
  }

  /// Determines whether [pos] is within [region], with some randomness.
  bool _regionContains(Region region, Vec pos) {
    const min = 0.0;
    const max = 2.0;

    var density = 0.0;
    switch (region) {
      case Region.everywhere:
        return true;
      case Region.n:
        density = lerpDouble(pos.y, 0, height, min, max);
        break;
      case Region.ne:
        var distance = math.max(width - pos.x - 1, pos.y);
        var range = math.min(width, height);
        density = lerpDouble(distance, 0, range, min, max);
        break;
      case Region.e:
        density = lerpDouble(pos.x, 0, width, min, max);
        break;
      case Region.se:
        var distance = math.max(width - pos.x - 1, height - pos.y - 1);
        var range = math.min(width, height);
        density = lerpDouble(distance, 0, range, min, max);
        break;
      case Region.s:
        density = lerpDouble(pos.y, 0, height, max, min);
        break;
      case Region.sw:
        var distance = math.max(pos.x, height - pos.y - 1);
        var range = math.min(width, height);
        density = lerpDouble(distance, 0, range, min, max);
        break;
      case Region.w:
        density = lerpDouble(pos.x, 0, width, max, min);
        break;
      case Region.nw:
        var distance = math.max(pos.x, pos.y);
        var range = math.min(width, height);
        density = lerpDouble(distance, 0, range, min, max);
        break;
    }

    return rng.float(1.0) > density;
  }

  bool _tryAttachRoom(Junction junction) {
    var room = _createRoom();

    // Try to find a junction that can mate with this one.
    var connectingTile = RoomTile.junctionFor(junction.direction.rotate180);
    var junctions =
        room.bounds.where((pos) => room[pos] == connectingTile).toList();
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
          _junctions.removeAt(here);
          break;

        case RoomTile.junctionN:
        case RoomTile.junctionS:
        case RoomTile.junctionE:
        case RoomTile.junctionW:
          // Remove any existing junctions since they now clash with the room.
          _junctions.removeAt(here);
          // TODO: Should we shuffle the room's junctions so that the clockwise
          // order doesn't bias the generator?
          _junctions.add(Junction(here, room[pos].direction));
          break;
      }
    }

    return true;
  }

  Array2D<RoomTile> _createRoom() {
    // TODO: Different room types and shapes.
    // Make a randomly-sized room but keep the aspect ratio reasonable.
    var short = rng.inclusive(3, 8);
    var long = rng.inclusive(short, math.min(12, short + 4));

    var horizontal = rng.oneIn(2);
    var width = horizontal ? long : short;
    var height = horizontal ? short : long;

    var tiles = Array2D<RoomTile>(width + 2, height + 2, RoomTile.unused);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        tiles.set(x + 1, y + 1, RoomTile.floor);
      }
    }

    _calculateEdges(tiles);
    return tiles;
  }

  /// Given a set of floor tiles, marks the boundary tiles as junctions or walls
  /// as appropriate.
  void _calculateEdges(Array2D<RoomTile> room) {
    for (var pos in room.bounds) {
      if (room[pos] != RoomTile.unused) continue;

      isFloor(Direction dir) {
        var here = pos + dir;
        if (!room.bounds.contains(here)) return false;
        return room[here] == RoomTile.floor;
      }

      var cardinalFloors = Direction.cardinal.where(isFloor).toList();
      var hasCornerFloor = Direction.intercardinal.any(isFloor);

      if (cardinalFloors.length == 1) {
        // Place junctions next to floors.
        room[pos] = RoomTile.junctionFor(cardinalFloors.single.rotate180);
      } else if (cardinalFloors.length > 1) {
        // Don't allow junctions at inside corners.
      } else if (hasCornerFloor) {
        // Don't allow junctions at outside corners.
        room[pos] = RoomTile.wall;
      }
    }
  }
}

class RoomTile {
  /// Not part of the room.
  static const unused = RoomTile("unused", Direction.none);

  /// Room floor.
  static const floor = RoomTile("floor", Direction.none);

  /// Room wall that cannot have a junction or passage through it.
  static const wall = RoomTile("wall", Direction.none);

  static const junctionN = RoomTile("junctionN", Direction.n);
  static const junctionS = RoomTile("junctionS", Direction.s);
  static const junctionE = RoomTile("junctionE", Direction.e);
  static const junctionW = RoomTile("junctionW", Direction.w);

  static RoomTile junctionFor(Direction dir) {
    switch (dir) {
      case Direction.n:
        return junctionN;
      case Direction.s:
        return junctionS;
      case Direction.e:
        return junctionE;
      case Direction.w:
        return junctionW;
      default:
        throw "Invalid direction.";
    }
  }

  final String name;
  final Direction direction;

  const RoomTile(this.name, this.direction);
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

class JunctionSet {
  final Map<Vec, Junction> _byPosition = {};
  final Queue<Junction> _queue = Queue();

  bool get isNotEmpty => _queue.isNotEmpty;

  Junction operator [](Vec pos) => _byPosition[pos];

  void add(Junction junction) {
    assert(_byPosition[junction.position] == null);

    _byPosition[junction.position] = junction;
    _queue.add(junction);
  }

  Junction takeNext() {
    // TODO: Filling them in bread-first order tends to make nicely packed
    // sets of rooms. Picking a random junction is a little more organic and
    // tends to leave more gaps.
    var junction = _queue.removeFirst();
    _byPosition.remove(junction.position);
    junction.tries++;

    return junction;
  }

  void removeAt(Vec pos) {
    var junction = _byPosition.remove(pos);
    if (junction != null) _queue.remove(junction);
  }
}
