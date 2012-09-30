class DungeonBuilder implements StageBuilder {
  final int numRoomTries;
  final int numJunctionTries;
  final int numRoundingTries;
  final int roomWidthMin;
  final int roomWidthMax;
  final int roomHeightMin;
  final int roomHeightMax;
  final int allowOverlapOneIn;

  final int extraCorridorDistanceMax;
  final int extraCorridorOneIn;
  final int extraCorridorDistanceMultiplier;

  DungeonBuilder([
    this.numRoomTries = 300,
    this.numJunctionTries = 30,
    this.numRoundingTries = 0,
    this.roomWidthMin = 3,
    this.roomWidthMax = 12,
    this.roomHeightMin = 3,
    this.roomHeightMax = 8,
    this.allowOverlapOneIn = 0,
    this.extraCorridorDistanceMax = 10,
    this.extraCorridorOneIn = 20,
    this.extraCorridorDistanceMultiplier = 4
  ]);

  void generate(Stage stage) {
    new Dungeon(stage, this).generate();
  }
}

class StageGenerator {
  final Stage stage;

  StageGenerator(this.stage);

  TileType getTile(Vec pos) => stage[pos].type;

  void setTile(Vec pos, TileType type) {
    stage[pos].type = type;
  }
}

class Dungeon extends StageGenerator {
  final DungeonBuilder builder;
  final List<Room> _rooms;
  final Set<int> _usedColors;

  Dungeon(Stage stage, this.builder)
  : super(stage),
    _rooms = <Room>[],
    _usedColors = new Set<int>();

  void generate() {
    // Clear the dungeon.
    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        setTile(new Vec(x, y), Tiles.wall);
      }
    }

    // Layout the rooms.
    int color = 0;
    for (var i = 0; i < builder.numRoomTries; i++) {
      final width = rng.range(builder.roomWidthMin, builder.roomWidthMax);
      final height = rng.range(builder.roomHeightMin, builder.roomHeightMax);
      final x = rng.range(1, stage.width - width);
      final y = rng.range(1, stage.height - height);

      final room = new Rect(x, y, width, height);
      if (!overlapsExistingRooms(room, true)){
        _rooms.add(new Room(room, ++color));
        _usedColors.add(color);
      }
    }

    // Add some one-tile "rooms" to work as corridor junctions.
    for (var i = 0; i < builder.numJunctionTries; i++) {
      final x = rng.range(1, stage.width - 3);
      final y = rng.range(1, stage.height - 3);

      final room = new Rect(x, y, 1, 1);
      if (!overlapsExistingRooms(room, false)){
        _rooms.add(new Room(room, ++color));
        _usedColors.add(color);
      }
    }

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
        }
      }
    }

    carveCorridors();

    // We do this after carving corridors so that when corridors carve through
    // rooms, they don't mess up the decorations.
    decorateRooms();

    // Round off sharp corners to make it look more organic.
    final bounds = stage.bounds.inflate(-1);
    for (var i = 0; i < builder.numRoundingTries; i++) {
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
        if (walls > 3) setTile(pos, Tiles.wall);
      } else {
        if (walls < 6) setTile(pos, Tiles.floor);
      }
    }

    // We do this last so that we only add doors where they actually make sense
    // and don't have to worry about overlapping corridors and other stuff
    // leading to nonsensical doors.
    addDoors();
  }

  bool overlapsExistingRooms(Rect room, bool allowOverlap) {
    for (final other in _rooms) {
      if (room.distanceTo(other.bounds) <= 0) {
        // Allow some rooms to overlap.
        if (allowOverlap && builder.allowOverlapOneIn > 0 &&
            rng.oneIn(builder.allowOverlapOneIn)) continue;
        return true;
      }
    }

    return false;
  }

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
    // TODO(bob): Inner loop shouldn't go through all rooms. Redundantly
    // considers each pair twice.
    for (final fromRoom in _rooms) {
      for (final toRoom in _rooms) {
        if (fromRoom == toRoom) continue;

        final distance = fromRoom.bounds.distanceTo(toRoom.bounds);
        if ((distance < builder.extraCorridorDistanceMax) &&
            rng.oneIn(builder.extraCorridorOneIn + distance *
                builder.extraCorridorDistanceMultiplier)) {
          carveCorridor(fromRoom, toRoom);
        }
      }
    }
  }

  void carveCorridor(Room fromRoom, Room toRoom) {
    // Draw a corridor.
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

    mergeColors(fromRoom, toRoom);
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

  bool isFloor(int x, int y) {
    return stage.get(x, y).type == Tiles.floor;
  }

  bool isWall(int x, int y) {
    return stage.get(x, y).type == Tiles.wall;
  }

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

  Room(this.bounds, this.color);
}
