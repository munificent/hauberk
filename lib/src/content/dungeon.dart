library hauberk.content.dungeon;

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'stage_builder.dart';
import 'tiles.dart';

class TrainingGrounds extends Dungeon {
  void onGenerate() {
    // Layout the rooms.
    addRooms(300);
    addJunctions(30);

    _carveRooms();
    _carveCorridors();

    // We do this after carving corridors so that when corridors carve through
    // rooms, they don't mess up the decorations.
    //decorateRooms((room) {
    //  if (rng.oneIn(4) && decoratePillars(room.bounds)) return;
    //  if (rng.oneIn(4) && decorateInnerRoom(room.bounds)) return;
    //});

    // We do this last so that we only add doors where they actually make sense
    // and don't have to worry about overlapping corridors and other stuff
    // leading to nonsensical doors.
    _addDoors();
  }
}

class GoblinStronghold extends Dungeon {
  final int _numRooms;

  GoblinStronghold(this._numRooms);

  int get roomWidthMax => 8;
  int get roomHeightMax => 6;

  /// Loosely connected.
  int get extraCorridorOneIn => 200;

  /// Pretty closed off.
  int get closedDoorPercent => 70;
  int get openDoorPercent => 20;

  void onGenerate() {
    // Layout the rooms.
    addRooms(_numRooms);

    _carveRooms();
    _carveCorridors();

    _decorateRooms((room) {
      if (rng.oneIn(5)) _decorateTable(room);
    });

    _addDoors();
  }

  bool _allowRoomOverlap(Rect a, Rect b) => rng.oneIn(20);
}

abstract class Dungeon extends StageBuilder {
  final _rooms = <_Room>[];
  final _usedColors = new Set<int>();

  int get roomWidthMin => 3;
  int get roomWidthMax => 12;
  int get roomHeightMin => 3;
  int get roomHeightMax => 8;
  int get extraCorridorDistanceMax => 10;
  int get extraCorridorOneIn => 20;
  int get extraCorridorDistanceMultiplier => 4;

  /// Chance out of 100 that an opening to a room will be a closed door.
  int get closedDoorPercent => 30;

  /// Chance out of 100 that an opening to a room will be an open door.
  int get openDoorPercent => 40;

  TileType get floor => Tiles.floor;
  TileType get wall => Tiles.wall;

  Dungeon();

  void generate(Stage stage) {
    bindStage(stage);
    fill(Tiles.wall);
    onGenerate();
  }

  void onGenerate();

  void addRooms(int tries) {
    for (var i = 0; i < tries; i++) {
      var room = randomRoom();
      if (!_overlapsExistingRooms(room, false)) {
        var color = _usedColors.length;
        _rooms.add(new _Room(room, color));
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
      var x = rng.range(1, stage.width - 3);
      var y = rng.range(1, stage.height - 3);

      var room = new Rect(x, y, 1, 1);
      if (!_overlapsExistingRooms(room, true)) {
        var color = _usedColors.length;
        _rooms.add(new _Room(room, ++color));
        _usedColors.add(color);
      }
    }
  }

  bool _overlapsExistingRooms(Rect room, bool isJunction) {
    for (var other in _rooms) {
      if (room.distanceTo(other.bounds) <= 0) {
        // Possibly allow some rooms to overlap.
        if (!isJunction && _allowRoomOverlap(room, other.bounds)) continue;
        return true;
      }
    }

    return false;
  }

  bool _allowRoomOverlap(Rect a, Rect b) => false;

  void _mergeColors(_Room a, _Room b) {
    if (a.color == b.color) return;

    var color = math.min(a.color, b.color);
    _usedColors.remove(math.max(a.color, b.color));

    for (var room in _rooms) {
      if (room.color == a.color || room.color == b.color) {
        room.color = color;
      }
    }
  }

  void _carveRooms() {
    // Fill them in.
    for (var room in _rooms) {
      for (var pos in room.bounds) {
        setTile(pos, Tiles.floor);
      }
    }

    // Unify colors for rooms that are already overlapping.
    _forEachRoomPair((room, other) {
      if (room.bounds.distanceTo(other.bounds) > 0) return;
      _mergeColors(room, other);

      // Keep track of which rooms overlap.
      room.isOverlapping = true;
      other.isOverlapping = true;
    });
  }

  void _carveCorridors() {
    // Keep adding corridors until all rooms are connected.
    while (_usedColors.length > 1) {
      // Pick a random color.
      var fromColor = rng.item(_rooms).color;

      // Find the room that is nearest to any room of this color and has a
      // different color. (In other words, find the nearest unconnected room to
      // this set of rooms.)
      var nearestFrom = null;
      var nearestTo = null;
      var nearestDistance = 9999;

      for (var fromRoom in _rooms) {
        if (fromRoom.color != fromColor) continue;

        for (var toRoom in _rooms) {
          if (toRoom.color == fromColor) continue;

          var distance = fromRoom.bounds.distanceTo(toRoom.bounds);
          if (distance >= nearestDistance) continue;
          nearestFrom = fromRoom;
          nearestTo = toRoom;
          nearestDistance = distance;
        }
      }

      _carveCorridor(nearestFrom, nearestTo);
    }

    // Add some extra corridors so the dungeon isn't a minimum spanning tree.
    _forEachRoomPair((fromRoom, toRoom) {
      var distance = fromRoom.bounds.distanceTo(toRoom.bounds);
      if (distance >= extraCorridorDistanceMax) return;
      if (!rng.oneIn(extraCorridorOneIn + distance *
              extraCorridorDistanceMultiplier)) return;
      _carveCorridor(fromRoom, toRoom);
    });
  }

  void _carveCorridor(_Room fromRoom, _Room toRoom) {
    _mergeColors(fromRoom, toRoom);

    // If the rooms overlap horizontally, carve a vertical path.
    var left = math.max(fromRoom.bounds.left, toRoom.bounds.left);
    var right = math.min(fromRoom.bounds.right, toRoom.bounds.right);
    if (left < right) {
      var top = math.min(fromRoom.bounds.top, toRoom.bounds.top);
      var bottom = math.max(fromRoom.bounds.bottom, toRoom.bounds.bottom);

      var x = rng.range(left, right);
      for (var y = top; y < bottom; y++) {
        setTile(new Vec(x, y), Tiles.floor);
      }

      return;
    }

    // If the rooms overlap horizontally, carve a horizontal path.
    var top = math.max(fromRoom.bounds.top, toRoom.bounds.top);
    var bottom = math.min(fromRoom.bounds.bottom, toRoom.bounds.bottom);
    if (top < bottom) {
      var left = math.min(fromRoom.bounds.left, toRoom.bounds.left);
      var right = math.max(fromRoom.bounds.right, toRoom.bounds.right);

      var y = rng.range(top, bottom);
      for (var x = left; x < right; x++) {
        setTile(new Vec(x, y), Tiles.floor);
      }

      return;
    }

    // We can't draw a straight corridor, so make an angled one.
    var from = rng.vecInRect(fromRoom.bounds);
    var to = rng.vecInRect(toRoom.bounds);

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

  void _decorateRooms(void decorateRoom(Rect room)) {
    for (var i = 0; i < _rooms.length; i++) {
      var room = _rooms[i];

      // Don't decorate overlapping rooms.
      var overlap = false;
      for (var j = i + 1; j < _rooms.length; j++) {
        if (room.bounds.distanceTo(_rooms[j].bounds) <= 0) {
          overlap = true;
          break;
        }
      }
      if (overlap) continue;

      decorateRoom(room.bounds);
    }
  }

  /// Add rows of pillars to the edge(s) of the room.
  bool _decoratePillars(Rect room) {
    if (room.width < 5) return false;
    if (room.height < 5) return false;

    // Only odd-sized sides get them, so make sure at least one side is.
    if ((room.width % 2 == 0) && (room.height % 2 == 0)) return false;

    var type = rng.oneIn(2) ? Tiles.wall : Tiles.lowWall;

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
  bool _decorateInnerRoom(Rect room) {
    if (room.width < 5) return false;
    if (room.height < 5) return false;

    var width = rng.range(3, room.width  - 2);
    var height = rng.range(3, room.height - 2);
    var x = rng.range(room.x + 1, room.right - width);
    var y = rng.range(room.y + 1, room.bottom - height);

    // Trace the room.
    var type = rng.oneIn(2) ? Tiles.wall : Tiles.lowWall;
    for (var pos in new Rect(x, y, width, height).trace()) {
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

  /// Places a table in the room.
  bool _decorateTable(Rect room) {
    var pos = rng.vecInRect(room);

    // Don't block an exit.
    if (pos.x == room.left && getTile(pos.offsetX(-1)) != Tiles.wall) {
      return false;
    }

    if (pos.y == room.top && getTile(pos.offsetY(-1)) != Tiles.wall) {
      return false;
    }

    if (pos.x == room.right && getTile(pos.offsetX(1)) != Tiles.wall) {
      return false;
    }

    if (pos.y == room.bottom && getTile(pos.offsetY(1)) != Tiles.wall) {
      return false;
    }

    setTile(pos, Tiles.table);
    return true;
  }

  bool _isFloor(int x, int y) => stage.get(x, y).type == Tiles.floor;
  bool _isWall(int x, int y) => stage.get(x, y).type == Tiles.wall;

  void _addDoors() {
    // For each room, attempt to place doors along its edges.
    for (var room in _rooms) {
      // Top and bottom.
      for (var x = room.bounds.left; x < room.bounds.right; x++) {
        _tryHorizontalDoor(x, room.bounds.top - 1);
        _tryHorizontalDoor(x, room.bounds.bottom);
      }

      // Left and right.
      for (var y = room.bounds.top; y < room.bounds.bottom; y++) {
        _tryVerticalDoor(room.bounds.left - 1, y);
        _tryVerticalDoor(room.bounds.right, y);
      }
    }
  }

  void _tryHorizontalDoor(int x, int y) {
    // Must be an opening where the door will be.
    if (!_isFloor(x, y)) return;

    // Must be wall on either end of the door.
    if (!_isWall(x - 1, y)) return;
    if (!_isWall(x + 1, y)) return;

    // And open in front and behind it.
    if (!_isFloor(x, y - 1)) return;
    if (!_isFloor(x, y + 1)) return;

    _addDoor(x, y);
  }

  void _tryVerticalDoor(int x, int y) {
    // Must be an opening where the door will be.
    if (!_isFloor(x, y)) return;

    // Must be wall on either end of the door.
    if (!_isWall(x, y - 1)) return;
    if (!_isWall(x, y + 1)) return;

    // And open in front and behind it.
    if (!_isFloor(x - 1, y)) return;
    if (!_isFloor(x + 1, y)) return;

    _addDoor(x, y);
  }

  void _addDoor(int x, int y) {
    var type = Tiles.floor;

    var roll = rng.range(100);
    if (roll < closedDoorPercent) {
      type = Tiles.closedDoor;
    } else if (roll < closedDoorPercent + openDoorPercent) {
      type = Tiles.openDoor;
    }

    setTile(new Vec(x, y), type);
  }

  /// Invokes [callback] on each unique pair of [Room]s.
  void _forEachRoomPair(callback(_Room a, _Room b)) {
    for (var i = 0; i < _rooms.length - 1; i++) {
      for (var j = i + 1; j < _rooms.length; j++) {
        callback(_rooms[i], _rooms[j]);
      }
    }
  }
}

class _Room {
  final Rect bounds;
  int color;
  bool isOverlapping = false;

  _Room(this.bounds, this.color);
}
