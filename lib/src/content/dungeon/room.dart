import 'dart:collection';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'blob.dart';
import 'dungeon.dart';
import 'junction.dart';
import 'room_place.dart';

// TODO: Define different ones of this to have different styles.
class RoomStyle {
  final int passagePercent = 80;
  final int passageTurnPercent = 30;
  final int passageBranchPercent = 40;
  final int passageStopPercent = 10;
  final int passageMinLength = 4;

  /// The shortest existing path between two points required to allow an
  /// additional shortcut passage to connect them. Making this longer requires
  /// cycles to be more of a shortcut, and makes them rarer.
  final int passageShortcutLength = 10;

  final int junctionMaxTries = 50;
}

class RoomBiome extends Biome {
  final Dungeon _dungeon;

  final RoomStyle _style = new RoomStyle();

  RoomBiome(this._dungeon);

  Iterable<String> generate() sync* {
    yield "Add starting room";
    // TODO: Sometimes start at a natural feature?
    _createStartingRoom();

    yield "Adding rooms";

    // Keep growing as long as we have attachment points.
    var roomNumber = 1;
    while (_dungeon.junctions.isNotEmpty) {
      var junction = _dungeon.junctions.takeNext();

      var success = false;
      if (rng.percent(_style.passagePercent)) {
        success = _tryPlacePassageRoom(junction);
      } else {
        // TODO: Only passages can connect to shore tiles, so dungeons with
        // just rooms don't reach them. Should consider placing a door if a
        // junction is next to shore.
        success = _tryPlaceRoom(junction, new Set());
        if (success) _placeDoor(junction.position);
      }

      if (success) {
        yield "Room $roomNumber";
        roomNumber++;
      } else if (++junction.tries < _style.junctionMaxTries) {
        // Couldn't place it, so re-add to try the junction again.
        _dungeon.junctions.add(junction);
      }
    }
  }

  /// Try to make a meandering passage starting at [junction] that ends in a
  /// new room or connects to an existing junction.
  bool _tryPlacePassageRoom(Junction junction) {
    // Make a meandering passage.
    var pos = junction.position;
    var dir = junction.direction;
    var distanceThisDir = 0;
    var passage = [pos].toSet();
    var newJunctions = <Junction>[];
    var placeRoom = true;

    maybeBranch(Direction dir) {
      if (rng.percent(_style.passageBranchPercent)) {
        newJunctions.add(new Junction(dir, pos + dir));
      }
    }

    while (passage.length < _style.passageMinLength ||
        !rng.percent(_style.passageStopPercent)) {
      // Don't allow turning twice in a row.
      if (distanceThisDir > 1 && rng.percent(_style.passageTurnPercent)) {
        if (rng.oneIn(2)) {
          dir = dir.rotateLeft90;
          maybeBranch(dir.rotateRight90);
        } else {
          dir = dir.rotateRight90;
          maybeBranch(dir.rotateLeft90);
        }

        maybeBranch(dir.rotate180);
        distanceThisDir = 0;
      }

      pos += dir;
      if (!_dungeon.safeBounds.contains(pos)) return false;

      // Don't let it loop back on itself.
      if (passage.contains(pos)) return false;

      var left = pos + dir.rotateLeft90;
      var right = pos + dir.rotateRight90;

      // If the passage connects up to an existing junction, consider adding a
      // cycle.
      // TODO: This search is slow.
      var reachedJunction = _dungeon.junctions.at(pos);
      if (reachedJunction != null &&
          reachedJunction.direction == dir.rotate180) {
        // Avoid a short passage that's just two doors next to each other.
        if (passage.length < 2) return false;

        // Don't add a cycle if there's already a path from one side to the other
        // that isn't much longer.
        if (new CyclePathfinder(_dungeon.stage, junction.position, pos + dir,
                passage.length + _style.passageShortcutLength)
            .search()) {
          return false;
        }

        // Don't add too many cycles.
        if (!rng.percent(1)) return false;

        _dungeon.junctions.removeAt(pos);
        placeRoom = false;
        passage.add(pos);
        break;
      }

      // If the passage connects to a natural area, stop there and then
      // traverse through it.
      if (_dungeon.getTileAt(pos) == Tiles.grass) {
        // Avoid a short passage that's just two doors next to each other.
        if (passage.length < 2) return false;

        // Don't add a cycle if there's already a path from one side to the other
        // that isn't very long.
        if (new CyclePathfinder(
                _dungeon.stage, junction.position, pos + dir, 20)
            .search()) {
          return false;
        }

        _reachNature([pos]);
        pos -= dir;
        placeRoom = false;
        passage.add(pos);
        break;
      }

      if (!_dungeon.safeBounds.contains(left)) return false;
      if (_dungeon.getTileAt(left).isTraversable) return false;
      if (passage.contains(left)) return false;

      if (!_dungeon.safeBounds.contains(right)) return false;
      if (_dungeon.getTileAt(right).isTraversable) return false;
      if (passage.contains(right)) return false;

      passage.add(pos);
      distanceThisDir++;
    }

    var cells = passage.toList();

    // The last passage position will always become the door.
    passage.remove(passage.last);

    // If we didn't connect to an existing junction, add a new room at the end
    // of the passage. We require this to pass so that we avoid dead end
    // passages.
    if (placeRoom) {
      var endJunction = new Junction(dir, pos);
      if (!_tryPlaceRoom(endJunction, passage)) return false;
    }

    for (var junction in newJunctions) {
      _dungeon.junctions.add(junction);
    }

    for (var pos in passage) {
      _dungeon.setTileAt(pos, Tiles.floor);

      for (var dir in Direction.all) {
        var neighbor = pos + dir;
        if (_dungeon.isRockAt(neighbor)) {
          _dungeon.setTileAt(neighbor, Tiles.wall);
        }
      }
    }

    _placeDoor(junction.position);
    _placeDoor(pos);

    _dungeon.addPlace(new PassagePlace(cells));
    return true;
  }

  void _createStartingRoom() {
    var startRoom = Room.create(_dungeon.depth);

    int x, y;
    do {
      x = rng.inclusive(0, _dungeon.width - startRoom.tiles.width);
      y = rng.inclusive(0, _dungeon.height - startRoom.tiles.height);

      // TODO: After a certain number of tries, should try a different room.
    } while (!_canPlaceRoom(startRoom, x, y, new Set()));

    _placeRoom(startRoom, x, y);

    // Place the hero on an open tile in the starting room.
    var openTiles = <Vec>[];
    for (var pos in startRoom.tiles.bounds) {
      if (startRoom.tiles[pos].isWalkable) openTiles.add(pos.offset(x, y));
    }
    _dungeon.placeHero(rng.item(openTiles));
  }

  bool _tryPlaceRoom(Junction junction, Set<Vec> passageTiles) {
    // TODO: Choosing random room types looks kind of blah. It's weird to
    // have blob rooms randomly scattered amongst other ones. Instead, it
    // would be better to have "regions" in the dungeon that preferentially
    // lean towards some room types.
    //
    // Alternatively (or do both), have the room type chosen based on the
    // preceding rooms that lead to this junction so that you don't have
    // weird things like a closet leading to a great hall.
    var room = Room.create(_dungeon.depth, junction);

    var roomJunctions = room.junctions
        .where((roomJunction) =>
            roomJunction.direction == junction.direction.rotate180)
        .toList();
    rng.shuffle(roomJunctions);

    for (var roomJunction in roomJunctions) {
      // Calculate the room position by lining up the junctions.
      var roomPos = junction.position - roomJunction.position;

      if (!_canPlaceRoom(room, roomPos.x, roomPos.y, passageTiles)) continue;

      _placeRoom(room, roomPos.x, roomPos.y, junction.position);
      return true;
    }

    return false;
  }

  bool _canPlaceRoom(Room room, int x, int y, Set<Vec> passageTiles) {
    if (!_dungeon.bounds.containsRect(room.tiles.bounds.offset(x, y))) {
      return false;
    }

    for (var roomPos in room.tiles.bounds) {
      var mapPos = roomPos.offset(x, y);

      // If the room doesn't care about the tile, it's fine.
      if (room.tiles[roomPos] == null) continue;

      // If there is an incoming passage, the room can't overlap it.
      if (passageTiles.contains(mapPos)) {
        return false;
      }

      // If some different tile has already been placed here, we can't place
      // the room.
      var tile = _dungeon.getTileAt(mapPos);
      if (tile != Tiles.rock && tile != room.tiles[roomPos]) {
        return false;
      }
    }

    return true;
  }

  void _placeRoom(Room room, int x, int y, [Vec junction]) {
    var cells = <Vec>[];

    if (junction != null) cells.add(junction);

    for (var pos in room.tiles.bounds) {
      var tile = room.tiles[pos];
      if (tile == null) continue;

      var absolute = pos.offset(x, y);
      _dungeon.setTileAt(absolute, tile);

      if (tile.isWalkable) cells.add(absolute);
    }

    // Add its junctions unless they are already blocked.
    var roomPos = new Vec(x, y);

    for (var junction in room.junctions) {
      _tryAddJunction(roomPos + junction.position, junction.direction);
    }

    _dungeon.addPlace(new RoomPlace(room, cells, hasHero: junction == null));
  }

  void _placeDoor(Vec pos) {
    // Always place a closed door. Later phases look for that to recognize
    // junctions.
    // TODO: Replace some closed doors with open doors, floor, hidden doors,
    // etc. in a later phase.
    _dungeon.setTile(pos.x, pos.y, Tiles.closedDoor);

    // Since passages are placed after the room they connect to, they may
    // overlap a room junction. Remove that since it's pointless.
    _dungeon.junctions.removeAt(pos);
  }

  void _tryAddJunction(Vec junctionPos, Direction junctionDir) {
    isBlocked(Direction direction) {
      var pos = junctionPos + direction;
      if (!_dungeon.safeBounds.contains(pos)) return true;

      var tile = _dungeon.getTileAt(pos);
      // TODO: Is there a more generic way we can handle this?
      return tile != Tiles.wall && tile != Tiles.rock;
    }

    if (isBlocked(Direction.none)) return;
    if (isBlocked(junctionDir)) return;
    if (isBlocked(junctionDir.rotateLeft45)) return;
    if (isBlocked(junctionDir.rotateRight45)) return;
    if (isBlocked(junctionDir.rotateLeft90)) return;
    if (isBlocked(junctionDir.rotateRight90)) return;

    _dungeon.junctions.add(new Junction(junctionDir, junctionPos));
  }

  void _reachNature(List<Vec> tiles) {
    var queue = new Queue.from(
        tiles.where((pos) => _dungeon.getTileAt(pos).isTraversable));
    var visited = new Set<Vec>();

    // TODO: Simplify.
    for (var pos in queue) {
      visited.add(pos);
    }

    while (queue.isNotEmpty) {
      var pos = queue.removeFirst();

      for (var dir in Direction.all) {
        var neighbor = pos + dir;
        if (!_dungeon.bounds.contains(neighbor)) continue;

        if (visited.contains(neighbor)) continue;

        var tile = _dungeon.getTileAt(neighbor);

        // Don't expand outside of the natural area.
        if (tile != Tiles.grass && tile != Tiles.bridge) {
          // If we're facing a straight direction, try to place a junction
          // there to allow building out from the area.
          if (Direction.cardinal.contains(dir) && rng.percent(30)) {
            _tryAddJunction(neighbor, dir);
          }
          continue;
        }

        // Don't go into impassable natural areas like water.
        if (!_dungeon.getTileAt(neighbor).isTraversable) continue;

        queue.add(neighbor);
        visited.add(neighbor);
      }
    }
  }
}

class Room {
  static ResourceSet<RoomType> _allTypes = new ResourceSet();

  // TODO: Hacky. ResourceSet assumes resources are named and have unique names.
  // Relax that constraint?
  static int _nextNameId = 0;

  static Room create(int depth, [Junction junction]) {
    if (_allTypes.isEmpty) _initializeRoomTypes();

    // TODO: Take depth into account somehow.
    var type = _allTypes.tryChoose(1, "room");
    return type.create();
  }

  static void _add(RoomType type, double frequency) {
    _allTypes.add("room_${_nextNameId++}", type, 1, frequency, "room");
  }

  static void _initializeRoomTypes() {
    _allTypes.defineTags("room");

    // Rectangular rooms of various sizes.
    // TODO: Make tunable.
    for (var width = 3; width <= 13; width++) {
      for (var height = 3; height <= 13; height++) {
        // Don't make them too big.
        if (width * height > 120) continue;

        // Don't make them too oblong.
        if ((width - height).abs() > math.min(width, height)) continue;

        // Prefer larger rooms. They tend to fail to get placed more often,
        // so making them more common counter-acts that.
        var frequency = math.sqrt(width * height);
        _add(new RectangleRoom(width, height), frequency);
      }
    }

    // Blob-shaped rooms.
    // TODO: Get blobs working with junctions.
//    _add(new BlobRoom(), 1);

    // TODO: Other room shapes: L, T, cross, etc.
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

    // TODO: Consider placing the junctions symmetrically sometimes.
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

// TODO: Maybe use blob rooms for things like worm pits?

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

/// Used to see if there is already a path between two points in the dungeon
/// before adding an extra door between two areas.
class CyclePathfinder extends Pathfinder<bool> {
  final int _maxLength;

  CyclePathfinder(Stage stage, Vec start, Vec end, this._maxLength)
      : super(stage, start, end);

  bool processStep(Path path) {
    if (path.length >= _maxLength) return false;

    return null;
  }

  bool reachedGoal(Path path) => true;

  int stepCost(Vec pos, Tile tile) {
    if (tile.canEnterAny(MotilitySet.doorAndWalk)) return 1;

    return null;
  }

  bool unreachableGoal() => false;
}
