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