class Dungeon {
  static int NUM_ROOM_TRIES = 1000;
  static int NUM_JUNCTION_TRIES = 30;

  final Level level;
  final List<Room> _rooms;
  final Set<int> _usedColors;

  Dungeon(this.level)
  : _rooms = <Room>[],
    _usedColors = new Set<int>();

  TileType getTile(Vec pos) => level[pos].type;

  void setTile(Vec pos, TileType type) {
    level[pos].type = type;
  }

  void generate() {
    // Layout the rooms.
    int color = 0;
    for (var i = 0; i < NUM_ROOM_TRIES; i++) {
      final width = rng.range(3, 12);
      final height = rng.range(3, 8);
      final x = rng.range(1, level.width - width);
      final y = rng.range(1, level.height - height);

      final room = new Rect(x, y, width, height);
      if (!overlapsExistingRooms(room)){
        _rooms.add(new Room(room, ++color));
        _usedColors.add(color);
      }
    }

    // Add some one-tile "rooms" to work as corridor junctions.
    for (var i = 0; i < NUM_JUNCTION_TRIES; i++) {
      final x = rng.range(1, level.width - 3);
      final y = rng.range(1, level.height - 3);

      final room = new Rect(x, y, 1, 1);
      if (!overlapsExistingRooms(room)){
        _rooms.add(new Room(room, ++color));
        _usedColors.add(color);
      }
    }

    // Fill them in.
    for (final room in _rooms) {
      for (final pos in room.bounds) {
        setTile(pos, TileType.FLOOR);
      }
    }

    // Unify colors for rooms that are already overlapping.
    for (final room in _rooms) {
      for (final other in _rooms) {
        if (room == other) continue;
        if (room.bounds.distanceTo(other.bounds) <= 0) {
          mergeColors(room, other);
        }
      }
    }

    // Draw corridors to connect the rooms.
    while (_usedColors.length > 1) {
      // Pick a random color.
      final fromColor = rng.item(_rooms).color;

      // Find the room that is nearest to any room of this color and has a
      // different color. (In other words, find the nearest unconnected room to
      // this set of rooms.)
      var nearestFrom = null;
      var nearestTo = null;
      var nearestDistance = 9999;

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

    // Add some extra corridors so the dungeon isn't a tree.
    for (final fromRoom in _rooms) {
      for (final toRoom in _rooms) {
        if (fromRoom == toRoom) continue;

        final distance = fromRoom.bounds.distanceTo(toRoom.bounds);
        if ((distance < 10) && rng.oneIn(10 + distance * 4)) {
          carveCorridor(fromRoom, toRoom);
        }
      }
    }

    /*
    final unconnected = new List<Rect>.from(_rooms);
    final connected = <Rect>[];

    while (unconnected.length > 0) {
      final room = rng.take(unconnected);

      // Find the nearest connected room.
      var nearest = null;
      var nearestDistance = 9999;
      for (final other in connected) {
        final distance = room.distanceTo(other);
        if (distance < nearestDistance) {
          nearest = other;
          nearestDistance = distance;
        }
      }

      final from = rng.vecInRect(room);
      final to = rng.vecInRect(nearest);

      connected.add(room);
    }
    */
  }

  bool overlapsExistingRooms(Rect room) {
    for (final other in _rooms) {
      if (room.distanceTo(other.bounds) <= 0) {
        // Allow some rooms to overlap.
        if (rng.oneIn(50)) continue;
        return true;
      }
    }

    return false;
  }

  void mergeColors(Room a, Room b) {
    if (a.color == b.color) return;

    final color = Math.min(a.color, b.color);
    _usedColors.remove(Math.max(a.color, b.color));

    for (final room in _rooms) {
      if (room.color == a.color || room.color == b.color) {
        room.color = color;
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

      setTile(pos, TileType.FLOOR);
    }

    mergeColors(fromRoom, toRoom);
  }
}

class Room {
  final Rect bounds;
  int color;

  Room(this.bounds, this.color);
}

/*
/// Going down a passageway should feel like it's leading towards a goal.
///
/// The dungeon should be connected. Moreso, it should be multiply connected
/// with at least a few cycles.
///
/// Given the relatively small dungeon size, we should use space efficiently.
///
/// As much as possible, it should feel like the dungeon is a place that was
/// built by an intelligent hand with a sense of purpose.
///
/// Small-scale features should support tactical combat and make the micro-level
/// gameplay more interesting.
///
/// Different dungeons should have a different feel. There should be a sense of
/// consistency across the entire dungeon.
///
/// There should be foreshadowing: the player encounters something that hints
/// at what they will find as they keep exploring. Treasure hides behind secret
/// passageways. After defeating a particularly strong monster, there will be
/// more loot past it.

class Dungeon {
  final Level level;

  Dungeon(this.level);

  TileType getTile(Vec pos) => level[pos].type;

  void setTile(Vec pos, TileType type) {
    level[pos].type = type;
  }

  void generate() {
    placeGreatHall();
  }

  void placeGreatHall() {
    final width = rng.range(10, 50);
    final height = rng.range(1, 3);
    final x = rng.range(1, level.width - width - 1);
    final y = 20;

    for (final pos in new Rect(x, y, width, height)) {
      setTile(pos, TileType.FLOOR);
    }

    final doorSpacing = 4 + rng.range(6);
    final topWingHeight = rng.range(3, Math.min(y - 1, 20));
    final bottomWingHeight = rng.range(3, Math.min(level.height - y - height - 1, 20));

    placeRoomRow(x, y - topWingHeight - 1, width, topWingHeight, doorSpacing, false);
    placeRoomRow(x, y + height + 1, width, bottomWingHeight, doorSpacing, true);
  }

  void placeRoomRow(int x, int y, int width, int height, int doorSpacing,
      bool doorsOnTop) {
    var left = x;
    var door = left + doorSpacing ~/ 2;
    do {
      var right;
      if (door + doorSpacing >= x + width) {
        // Last room.
        right = x + width;
      } else {
        right = rng.range(door + 1, door + doorSpacing);
      }

      placeRooms(new Rect(left, y, right - left, height),
          door - left, doorsOnTop ? Direction.N : Direction.S);
      left = right + 1;
      door += doorSpacing;
    } while (left < x + width);
  }

  void placeRooms(Rect bounds, int doorPos, Direction doorSide) {
    for (final pos in bounds) {
      setTile(pos, TileType.FLOOR);
    }

    var door;
    switch (doorSide) {
      case Direction.N: door = new Vec(bounds.left + doorPos, bounds.top - 1); break;
      case Direction.E: door = new Vec(bounds.left - 1, bounds.top + doorPos); break;
      case Direction.S: door = new Vec(bounds.left + doorPos, bounds.bottom); break;
      case Direction.W: door = new Vec(bounds.right, bounds.top + doorPos); break;
    }

    setTile(door, TileType.FLOOR);
  }
}
*/