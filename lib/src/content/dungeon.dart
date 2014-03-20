library content.dungeon;

import 'dart:math' as math;

import '../engine.dart';
import '../util.dart';
import 'tiles.dart';

class StageGenerator {
  Stage stage;

  TileType getTile(Vec pos) => stage[pos].type;

  void setTile(Vec pos, TileType type) {
    stage[pos].type = type;
  }

  void bindStage(Stage stage) {
    this.stage = stage;
  }
}

class TrainingGrounds extends Dungeon {
  void onGenerate() {
    fill(Tiles.wall);

    // Layout the rooms.
    addRooms(300);
    addJunctions(30);

    carveRooms();
    carveCorridors();

    // We do this after carving corridors so that when corridors carve through
    // rooms, they don't mess up the decorations.
    //decorateRooms();

    // We do this last so that we only add doors where they actually make sense
    // and don't have to worry about overlapping corridors and other stuff
    // leading to nonsensical doors.
    addDoors();
  }
}

class GoblinStronghold extends Dungeon {
  final int depth;

  GoblinStronghold(this.depth);

  int get roomWidthMax => 8;
  int get roomHeightMax => 6;

  void onGenerate() {
    fill(Tiles.wall);

    // Layout the rooms.
    addRooms(300 - depth * 20);

    carveRooms();
    carveCorridors();

    erode(500 + depth * 250);
  }

  bool allowRoomOverlap(Rect a, Rect b) => rng.oneIn(20);
}

abstract class Dungeon extends StageGenerator {
  final List<Room> _rooms;
  final Set<int> _usedColors;

  int get roomWidthMin => 3;
  int get roomWidthMax => 12;
  int get roomHeightMin => 3;
  int get roomHeightMax => 8;
  int get extraCorridorDistanceMax => 10;
  int get extraCorridorOneIn => 20;
  int get extraCorridorDistanceMultiplier => 4;

  TileType get floor => Tiles.floor;
  TileType get wall => Tiles.wall;

  Dungeon()
    : _rooms = <Room>[],
      _usedColors = new Set<int>();

  void generate(Stage stage) {
    bindStage(stage);
    onGenerate();
  }

  void onGenerate();

  void fill(TileType tile) {
    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        setTile(new Vec(x, y), tile);
      }
    }
  }

  void addRooms(int tries) {
    for (var i = 0; i < tries; i++) {
      var room = randomRoom();
      if (!overlapsExistingRooms(room, false)) {
        var color = _usedColors.length;
        _rooms.add(new Room(room, color));
        _usedColors.add(color);
      }
    }
  }

  Rect randomRoom() {
    var width = rng.range(roomWidthMin, roomWidthMax);
    var height = rng.range(roomHeightMin, roomHeightMax);
    var x = rng.range(1, stage.width - width);
    var y = rng.range(1, stage.height - height);

    return new Rect(x, y, width, height);
  }

  void addJunctions(int tries) {
    for (var i = 0; i < tries; i++) {
      final x = rng.range(1, stage.width - 3);
      final y = rng.range(1, stage.height - 3);

      final room = new Rect(x, y, 1, 1);
      if (!overlapsExistingRooms(room, true)) {
        var color = _usedColors.length;
        _rooms.add(new Room(room, ++color));
        _usedColors.add(color);
      }
    }
  }

  bool overlapsExistingRooms(Rect room, bool isJunction) {
    for (final other in _rooms) {
      if (room.distanceTo(other.bounds) <= 0) {
        // Possibly allow some rooms to overlap.
        if (!isJunction && allowRoomOverlap(room, other.bounds)) continue;
        return true;
      }
    }

    return false;
  }

  bool allowRoomOverlap(Rect a, Rect b) => false;

  void mergeColors(Room a, Room b) {
    if (a.color == b.color) return;

    final color = math.min(a.color, b.color);
    _usedColors.remove(math.max(a.color, b.color));

    for (final room in _rooms) {
      if (room.color == a.color || room.color == b.color) {
        room.color = color;
      }
    }
  }

  void carveRooms() {
    // Fill them in.
    for (final room in _rooms) {
      for (final pos in room.bounds) {
        setTile(pos, Tiles.floor);
      }
    }

    // Unify colors for rooms that are already overlapping.
    // TODO(bob): Inner loop shouldn't go through all rooms. Redundantly
    // considers each pair twice.
    for (final room in _rooms) {
      for (final other in _rooms) {
        if (room == other) continue;
        if (room.bounds.distanceTo(other.bounds) <= 0) {
          mergeColors(room, other);

          // Keep track of which rooms overlap.
          room.isOverlapping = true;
          other.isOverlapping = true;
        }
      }
    }
  }

  void carveCorridors() {
    // Keep adding corridors until all rooms are connected.
    while (_usedColors.length > 1) {
      // Pick a random color.
      final fromColor = rng.item(_rooms).color;

      // Find the room that is nearest to any room of this color and has a
      // different color. (In other words, find the nearest unconnected room to
      // this set of rooms.)
      var nearestFrom = null;
      var nearestTo = null;
      var nearestDistance = 9999;

      // TODO(bob): Inner loop shouldn't go through all rooms. Redundantly
      // considers each pair twice.
      for (final fromRoom in _rooms) {
        if (fromRoom.color != fromColor) continue;

        for (final toRoom in _rooms) {
          if (toRoom.color == fromColor) continue;

          final distance = fromRoom.bounds.distanceTo(toRoom.bounds);
          if (distance < nearestDistance) {
            nearestFrom = fromRoom;
            nearestTo = toRoom;
            nearestDistance = distance;
          }
        }
      }

      carveCorridor(nearestFrom, nearestTo);
    }

    // Add some extra corridors so the dungeon isn't a minimum spanning tree.
    for (final fromRoom in _rooms) {
      for (final toRoom in _rooms) {
        if (fromRoom == toRoom) continue;

        final distance = fromRoom.bounds.distanceTo(toRoom.bounds);
        if ((distance < extraCorridorDistanceMax) &&
            rng.oneIn(extraCorridorOneIn + distance *
                extraCorridorDistanceMultiplier)) {
          carveCorridor(fromRoom, toRoom);
        }
      }
    }
  }

  void carveCorridor(Room fromRoom, Room toRoom) {
    mergeColors(fromRoom, toRoom);

    // If the rooms overlap horizontally, carve a vertical path.
    final left = math.max(fromRoom.bounds.left, toRoom.bounds.left);
    final right = math.min(fromRoom.bounds.right, toRoom.bounds.right);
    if (left < right) {
      final top = math.min(fromRoom.bounds.top, toRoom.bounds.top);
      final bottom = math.max(fromRoom.bounds.bottom, toRoom.bounds.bottom);

      final x = rng.range(left, right);
      for (var y = top; y < bottom; y++) {
        setTile(new Vec(x, y), Tiles.floor);
      }

      return;
    }

    // If the rooms overlap horizontally, carve a horizontal path.
    final top = math.max(fromRoom.bounds.top, toRoom.bounds.top);
    final bottom = math.min(fromRoom.bounds.bottom, toRoom.bounds.bottom);
    if (top < bottom) {
      final left = math.min(fromRoom.bounds.left, toRoom.bounds.left);
      final right = math.max(fromRoom.bounds.right, toRoom.bounds.right);

      final y = rng.range(top, bottom);
      for (var x = left; x < right; x++) {
        setTile(new Vec(x, y), Tiles.floor);
      }

      return;
    }

    // We can't draw a straight corridor, so make an angled one.
    final from = rng.vecInRect(fromRoom.bounds);
    final to = rng.vecInRect(toRoom.bounds);

    // TODO(bob): Make corridor meander more.
    var pos = from;
    while (pos != to) {
      if (pos.y < to.y) {
        pos = pos.offsetY(1);
      } else if (pos.y > to.y) {
        pos = pos.offsetY(-1);
      } else if (pos.x < to.x) {
        pos = pos.offsetX(1);
      } else if (pos.x > to.x) {
        pos = pos.offsetX(-1);
      }

      setTile(pos, Tiles.floor);
    }
  }

  void decorateRooms() {
    for (var i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];

      // Don't decorate overlapping rooms.
      var overlap = false;
      for (var j = i + 1; j < _rooms.length; j++) {
        if (room.bounds.distanceTo(_rooms[j].bounds) <= 0) {
          overlap = true;
          break;
        }
      }
      if (overlap) continue;

      // Try the different kinds of decorations until one succeeds.
      if (rng.oneIn(4) && decoratePillars(room.bounds)) continue;
      if (rng.oneIn(4) && decorateInnerRoom(room.bounds)) continue;
      // TODO(bob): Add more decorations.
    }
  }

  /// Add rows of pillars to the edge(s) of the room.
  bool decoratePillars(Rect room) {
    if (room.width < 5) return false;
    if (room.height < 5) return false;

    // Only odd-sized sides get them, so make sure at least one side is.
    if ((room.width % 2 == 0) && (room.height % 2 == 0)) return false;

    final type = rng.oneIn(2) ? Tiles.wall : Tiles.lowWall;

    if (room.width % 2 == 1) {
      for (var x = room.left + 1; x < room.right - 1; x += 2) {
        setTile(new Vec(x, room.top + 1), type);
        setTile(new Vec(x, room.bottom - 2), type);
      }
    }

    if (room.height % 2 == 1) {
      for (var y = room.top + 1; y < room.bottom - 1; y += 2) {
        setTile(new Vec(room.left + 1, y), type);
        setTile(new Vec(room.right - 2, y), type);
      }
    }

    return true;
  }

  /// If [room] is big enough, adds a floating room inside of it with a single
  /// entrance.
  bool decorateInnerRoom(Rect room) {
    if (room.width < 5) return false;
    if (room.height < 5) return false;

    final width = rng.range(3, room.width  - 2);
    final height = rng.range(3, room.height - 2);
    final x = rng.range(room.x + 1, room.right - width);
    final y = rng.range(room.y + 1, room.bottom - height);

    // Trace the room.
    final type = rng.oneIn(2) ? Tiles.wall : Tiles.lowWall;
    for (final pos in new Rect(x, y, width, height).trace()) {
      setTile(pos, type);
    }

    // Make an entrance. If it's a narrow room, always place the door on the
    // wider side.
    var directions;
    if ((width == 3) && (height > 3)) {
      directions = [Direction.E, Direction.W];
    } else if ((height == 3) && (width > 3)) {
      directions = [Direction.N, Direction.S];
    } else {
      directions = [Direction.N, Direction.S, Direction.E, Direction.W];
    }

    var door;
    switch (rng.item(directions)) {
      case Direction.N:
        door = new Vec(rng.range(x + 1, x + width - 1), y);
        break;
      case Direction.S:
        door = new Vec(rng.range(x + 1, x + width - 1), y + height - 1);
        break;
      case Direction.W:
        door = new Vec(x, rng.range(y + 1, y + height - 1));
        break;
      case Direction.E:
        door = new Vec(x + width - 1, rng.range(y + 1, y + height - 1));
        break;
    }
    setTile(door, Tiles.floor);

    return true;
  }

  /// Randomly turns some floor tiles into walls and vice versa. Does so while
  /// maintaining the reachability invariant of the dungeon.
  void erode(int iterations) {
    final bounds = stage.bounds.inflate(-1);
    for (var i = 0; i < iterations; i++) {
      final pos = rng.vecInRect(bounds);

      final here = getTile(pos);
      if (here != Tiles.floor && here != Tiles.wall) continue;

      bool canChange = true;

      // Keep track of how many walls we're adjacent too. We will only fill in
      // if we are directly next to a wall.
      var walls = 0;

      // As we go around the tile's neighbors, keep track of how many times we
      // switch from wall to floor. We can fill in a tile only if it is next to
      // a single unbroken expanse of walls. If it is next to two
      // non-contiguous wall sections, then filling it in may break the
      // reachability of the dungeon.
      var inWall;
      var transitions = 0;

      for (var dir in Direction.ALL) {
        var tile = getTile(pos + dir);
        if (tile == Tiles.floor) {
          if (inWall == true) transitions++;
          inWall = false;
        } else if (tile == Tiles.wall) {
          walls++;
          if (inWall == false) transitions++;
          inWall = true;
        } else {
          // Don't modify next to "special" features.
          canChange = false;
          break;
        }

        if (transitions > 2) {
          canChange = false;
          break;
        }
      }

      if (!canChange) continue;

      if (here == Tiles.floor) {
        if (walls > 3 ||
            (walls == 3 && rng.oneIn(4)) ||
            (walls == 2 && rng.oneIn(8))) setTile(pos, Tiles.wall);
      } else {
        if (walls < 5 ||
            (walls == 5 && rng.oneIn(4)) ||
            (walls == 6 && rng.oneIn(8))) setTile(pos, Tiles.floor);
      }
    }
  }

  bool isFloor(int x, int y) => stage.get(x, y).type == Tiles.floor;
  bool isWall(int x, int y) => stage.get(x, y).type == Tiles.wall;

  void addDoors() {
    // For each room, attempt to place doors along its edges.
    for (final room in _rooms) {
      // Top and bottom.
      for (var x = room.bounds.left; x < room.bounds.right; x++) {
        tryHorizontalDoor(x, room.bounds.top - 1);
        tryHorizontalDoor(x, room.bounds.bottom);
      }

      // Left and right.
      for (var y = room.bounds.top; y < room.bounds.bottom; y++) {
        tryVerticalDoor(room.bounds.left - 1, y);
        tryVerticalDoor(room.bounds.right, y);
      }
    }
  }

  void tryHorizontalDoor(int x, int y) {
    // Must be an opening where the door will be.
    if (!isFloor(x, y)) return;

    // Must be wall on either end of the door.
    if (!isWall(x - 1, y)) return;
    if (!isWall(x + 1, y)) return;

    // And open in front and behind it.
    if (!isFloor(x, y - 1)) return;
    if (!isFloor(x, y + 1)) return;

    addDoor(x, y);
  }

  void tryVerticalDoor(int x, int y) {
    // Must be an opening where the door will be.
    if (!isFloor(x, y)) return;

    // Must be wall on either end of the door.
    if (!isWall(x, y - 1)) return;
    if (!isWall(x, y + 1)) return;

    // And open in front and behind it.
    if (!isFloor(x - 1, y)) return;
    if (!isFloor(x + 1, y)) return;

    addDoor(x, y);
  }

  void addDoor(int x, int y) {
    var type;
    switch (rng.range(3)) {
    case 0: type = Tiles.floor; break; // No door.
    case 1: type = Tiles.closedDoor; break;
    case 2: type = Tiles.openDoor; break;
    }

    setTile(new Vec(x, y), type);
  }
}

class Room {
  final Rect bounds;
  int color;
  bool isOverlapping = false;

  Room(this.bounds, this.color);
}
