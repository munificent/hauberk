import 'dart:collection';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'blob.dart';
import 'dungeon2.dart';
import 'tiles.dart';

class Junction {
  /// Points from the first room towards where the new room should be attached.
  ///
  /// A room must have an opposing junction in order to match.
  final Direction direction;

  /// The location of the junction.
  ///
  /// For a placed room, this is in absolute coordinates. For a room yet to be
  /// placed, it's relative to the room's tile array.
  final Vec position;

  Junction(this.direction, this.position);
}

/// Mixin for [Dungeon2] that adds support for rooms.
abstract class Rooms implements DungeonBase {
  final List<Junction> _junctions = [];

  Iterable<String> addRooms() sync* {
    // TODO: Hack temp.
    Dungeon2.currentJunctions = _junctions;

    yield "Add starting room";
    // TODO: Sometimes start at a natural feature.

    var startRoom = Room.create(depth);
    while (true) {
      var x = rng.inclusive(0, width - startRoom.tiles.width);
      var y = rng.inclusive(0, height - startRoom.tiles.height);

      if (!_canPlace(startRoom, x, y)) continue;
      // TODO: After a certain number of tries, should try a different room.

      yield "Placing starting room";
      _placeRoom(startRoom, x, y);
      break;
    }

    yield "Adding rooms";

    // Keep growing as long as we have attachment points.
    var roomNumber = 1;
    while (_junctions.isNotEmpty) {
      var junction = rng.take(_junctions);
      var roomJunctionDir = junction.direction.rotate180;
      // TODO: Add junctions to natural features so we can grow through them.

      var placed = false;
      // TODO: Tune this.
      for (var i = 0; i < 20; i++) {
        // TODO: Choosing random room types looks kind of blah. It's weird to
        // have blob rooms randomly scattered amongst other ones. Instead, it
        // would be better to have "regions" in the dungeon that preferentially
        // lean towards some room types.
        //
        // Alternatively (or do both), have the room type chosen based on the
        // preceding rooms that lead to this junction so that you don't have
        // weird things like a closet leading to a great hall.
        var room = Room.create(depth);

        for (var roomJunction in room.junctions) {
          if (roomJunction.direction != roomJunctionDir) continue;

          // Calculate the room position by lining up the junctions.
          var roomPos = junction.position - roomJunction.position;

          if (!_canPlace(room, roomPos.x, roomPos.y)) continue;

          yield "Placing room ${roomNumber++}";
          _placeRoom(room, roomPos.x, roomPos.y);
          // TODO: Different doors.
          setTile(junction.position.x, junction.position.y, Tiles.closedDoor,
              TileState.reached);

          placed = true;
          break;
        }

        if (placed) break;
      }
    }
  }

  bool _canPlace(Room room, int x, int y) {
    if (!bounds.containsRect(room.tiles.bounds.offset(x, y))) return false;

    var allowed = 0;
    var feature = 0;

    for (var pos in room.tiles.bounds) {
      // If the room doesn't care about the tile, it's fine.
      if (room.tiles[pos] == null) continue;

      // Otherwise, it must still be solid on the stage.
      var state = getState(pos.x + x, pos.y + y);
      var tile = getTile(pos.x + x, pos.y + y);

      if (state == TileState.unused) {
        allowed++;
      } else if (state == TileState.natural) {
        feature++;
      } else if (tile == room.tiles[pos]) {
        // Allow it if it wouldn't change the type. This lets room walls
        // overlap.
      } else {
        return false;
      }
    }

    // Allow overlapping natural features somewhat, but not too much.
    // TODO: Do we want to only allow certain room types to open into natural
    // areas?
    return allowed > feature * 2;
  }

  void _placeRoom(Room room, int x, int y) {
    List<Vec> nature = [];

    for (var pos in room.tiles.bounds) {
      var tile = room.tiles[pos];
      if (tile == null) continue;

      // Don't erase existing natural features.
      var state = getState(pos.x + x, pos.y + y);
      if (state == TileState.natural) {
        if (tile.isTraversable) nature.add(pos.offset(x, y));
        continue;
      }

      setTile(pos.x + x, pos.y + y, tile, TileState.reached);
    }

    // Add its junctions unless they are already blocked.
    var roomPos = new Vec(x, y);

    for (var junction in room.junctions) {
      _tryAddJunction(roomPos + junction.position, junction.direction);
    }

    // If the room opens up into a natural feature, that feature is reachable
    // now.
    if (nature != null) _reachNature(nature);
  }

  void _tryAddJunction(Vec junctionPos, Direction junctionDir) {
    isBlocked(Direction direction) {
      var pos = junctionPos + direction;
      if (!safeBounds.contains(pos)) return true;

      var tile = getTileAt(pos);
      // TODO: Is there a more generic way we can handle this?
      return tile != Tiles.wall && tile != Tiles.rock;
    }

    if (isBlocked(Direction.none)) return;
    if (isBlocked(junctionDir)) return;
    if (isBlocked(junctionDir.rotateLeft45)) return;
    if (isBlocked(junctionDir.rotateRight45)) return;
    if (isBlocked(junctionDir.rotateLeft90)) return;
    if (isBlocked(junctionDir.rotateRight90)) return;

    _junctions.add(new Junction(junctionDir, junctionPos));
  }

  void _reachNature(List<Vec> tiles) {
    var queue =
    new Queue.from(tiles.where((pos) => getTileAt(pos).isTraversable));
    for (var pos in queue) {
      setStateAt(pos, TileState.reached);
    }

    while (queue.isNotEmpty) {
      var pos = queue.removeFirst();

      for (var dir in Direction.all) {
        var neighbor = pos + dir;
        if (!bounds.contains(neighbor)) continue;

        // If we hit the edge of the walkable natural area and we're facing a
        // straight direction, try to place a junction there to allow building
        // out from the area.
        if (getStateAt(neighbor) != TileState.natural) {
          if (Direction.cardinal.contains(dir) && rng.range(100) < 30) {
            _tryAddJunction(neighbor, dir);
          }
          continue;
        }

        // Don't go into impassable natural areas like water.
        if (!getTileAt(neighbor).isTraversable) continue;

        setStateAt(neighbor, TileState.reached);
        queue.add(neighbor);
      }
    }
  }
}

class Room {
  static ResourceSet<RoomType> _allTypes = new ResourceSet();

  // TODO: Hacky. ResourceSet assumes resources are named and have unique names.
  // Relax that constraint?
  static int _nextNameId = 0;

  static Room create(int depth) {
    if (_allTypes.isEmpty) _initializeRoomTypes();

    // TODO: Take depth into account somehow.
    var type = _allTypes.tryChoose(1, "room");
    return type.create();
  }

  static void _add(RoomType type, int rarity) {
    _allTypes.add("room_${_nextNameId++}", type, 1, rarity, "room");
  }

  static void _initializeRoomTypes() {
    _allTypes.defineTags("room");

    // Rectangular rooms of various sizes.
    for (var width = 3; width <= 11; width++) {
      for (var height = 3; height <= 11; height++) {
        // Don't make them too big.
        if (width * height > 80) continue;

        // Don't make them too oblong.
        if ((width - height).abs() > math.min(width, height)) continue;

        // Middle-sized rooms are most common.
        var rarity = 1;
        if (math.max(width, height) <= 4) {
          rarity = 3;
        } else if (math.max(width, height) <= 5) {
          rarity = 2;
        } else if (math.min(width, height) >= 9) {
          rarity = 3;
        } else if (math.min(width, height) >= 7) {
          rarity = 2;
        }

        _add(new RectangleRoom(width, height), rarity * 10);
      }
    }

    // Blob-shaped rooms.
    // TODO: Get blobs working with junctions.
//    _add(new BlobRoom(), 1);

    // TODO: Other room shapes: L, T, cross, etc.
    // TODO: Passageways.
  }

  final Array2D<TileType> tiles;
  final List<Junction> junctions;

  Room(this.tiles, this.junctions);
}

abstract class RoomType {
  Room create();
}

class RectangleRoom extends RoomType {
  final int width;
  final int height;

  RectangleRoom(this.width, this.height);

  Room create() {
    // TODO: Cache this with the type?
    var tiles = new Array2D<TileType>(width + 2, height + 2, Tiles.floor);

    for (var y = 0; y < tiles.height; y++) {
      tiles.set(0, y, Tiles.wall);
      tiles.set(tiles.width - 1, y, Tiles.wall);
    }

    for (var x = 0; x < tiles.width; x++) {
      tiles.set(x, 0, Tiles.wall);
      tiles.set(x, tiles.height - 1, Tiles.wall);
    }

    var junctions = <Junction>[];
    _placeJunctions(width, (i) {
      junctions.add(new Junction(Direction.n, new Vec(i + 1, 0)));
    });

    _placeJunctions(width, (i) {
      junctions.add(new Junction(Direction.s, new Vec(i + 1, height + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(new Junction(Direction.w, new Vec(0, i + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(new Junction(Direction.e, new Vec(width + 1, i + 1)));
    });

    return new Room(tiles, junctions);
  }

  /// Walks along [length], invoking [callback] at values where a junction
  /// should be placed.
  ///
  /// Ensures two junctions are not placed next to each other.
  void _placeJunctions(int length, void Function(int) callback) {
    var start = rng.oneIn(2) ? 0 : 1;
    for (var i = start; i < length; i++) {
      // TODO: Make chances tunable.
      if (rng.range(100) < 40) {
        callback(i);

        // Don't allow two junctions right next to each other.
        i++;
      }
    }
  }
}

class BlobRoom extends RoomType {
  Room create() {
    // TODO: Other size blobs.
    var blob = Blob.make16();
    // Note: Assumes the blob never has open cells at the very edge.
    var tiles = new Array2D<TileType>(blob.width, blob.height);
    for (var pos in tiles.bounds.inflate(-1)) {
      if (blob[pos]) {
        tiles[pos] = Tiles.floor;

        // If this cell is at the edge of the blob, ensure there is a ring of
        // wall around it.
        for (var dir in Direction.all) {
          var neighbor = pos + dir;
          if (tiles[neighbor] != Tiles.floor) {
            tiles[neighbor] = Tiles.wall;
          }
        }
      }
    }

    // TODO: Place junctions.
    return new Room(tiles, []);
  }
}
