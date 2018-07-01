import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../themes.dart';
import '../tiles.dart';
import 'dungeon.dart';
import 'junction.dart';
import 'room_place.dart';

// TODO: Define different ones of this to have different styles.
class RoomStyle {
  final int passagePercent = 60;
  final int passageTurnPercent = 30;
  final int passageBranchPercent = 40;
  final int passageStopPercent = 10;
  final int passageMinLength = 4;

  /// A passage that connects to an existing place, by definition, adds a cycle
  /// to the dungeon. We don't want to do that if there is always a similar
  /// path between those two points. A cycle should only be added if it connects
  /// two very disparate regions (in terms of reachability).
  ///
  /// To get that, we only place a cyclic passage if the shortest existing
  /// route between the two points is longer than the new passage's length times
  /// this scale. Making this smaller adds more cycles.
  final int passageShortcutScale = 10;

  final int junctionMaxTries = 50;
}

class RoomBiome extends Biome {
  final Dungeon _dungeon;
  final RoomStyle _style = new RoomStyle();
  final JunctionSet _junctions = new JunctionSet();

  RoomBiome(this._dungeon);

  Iterable<String> generate() sync* {
    RoomTypes.initialize();

    yield "Add starting room";
    // TODO: Sometimes start at a natural feature?
    _createStartingRoom();

    yield "Adding rooms";

    // Keep growing as long as we have attachment points.
    var roomNumber = 1;
    while (_junctions.isNotEmpty) {
      var junction = _junctions.takeNext();

      var success = false;
      if (RoomTypes.allowsPassage(junction.theme) &&
          rng.percent(_style.passagePercent)) {
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
        _junctions.add(junction);
      }
    }
  }

  /// Try to make a meandering passage starting at [junction] that ends in a
  /// new room or connects to an existing junction.
  bool _tryPlacePassageRoom(Junction junction) {
    // TODO: Instead of always using "passage" as the room type, could either
    // propagate the parent type, or define different flavors of passage to
    // control which kinds of rooms allow corridors between them.

    // Make a meandering passage.
    var pos = junction.position;
    var dir = junction.direction;
    var distanceThisDir = 0;
    var passage = [pos].toSet();
    var newJunctions = <Junction>[];
    var placeRoom = true;

    maybeBranch(Direction dir) {
      if (rng.percent(_style.passageBranchPercent)) {
        newJunctions.add(new Junction("passage", dir, pos + dir));
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

      // TODO: Only allow a shortcut to a valid child room?
      // If the passage connects up to an existing junction, consider adding a
      // cycle.
      var reachedJunction = _junctions.at(pos);
      if (reachedJunction != null &&
          reachedJunction.direction == dir.rotate180) {
        if (!_isValidShortcut(junction.position, pos + dir, passage.length)) {
          return false;
        }

        _junctions.removeAt(pos);
        placeRoom = false;
        passage.add(pos);
        break;
      }

      // If the passage connects to a natural area, stop there and then
      // traverse through it.
      if (_dungeon.getTileAt(pos) == Tiles.grass) {
        if (!_isValidShortcut(junction.position, pos + dir, passage.length)) {
          return false;
        }

        _reachNature([pos]);
        pos -= dir;
        placeRoom = false;
        passage.add(pos);
        break;
      }

      // Don't allow it to brush against the edge of anything else.
      var left = pos + dir.rotateLeft90;
      var right = pos + dir.rotateRight90;

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
      var endJunction = new Junction("passage", dir, pos);
      if (!_tryPlaceRoom(endJunction, passage)) return false;
    }

    for (var junction in newJunctions) {
      _junctions.add(junction);
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

  /// Returns `true` if a passage with [length] from [from] to [to] is
  /// significantly shorter than the current shortest path between those points.
  ///
  /// Used to avoid placing pointless redundant paths in the dungeon.
  bool _isValidShortcut(Vec from, Vec to, int length) {
    // Avoid a short passage that's just two doors next to each other.
    if (length < 2) return false;

    var pathfinder = new CyclePathfinder(
        _dungeon.stage, from, to, length * _style.passageShortcutScale);

    // TODO: This search is very slow.
    return !pathfinder.search();
  }

  void _createStartingRoom() {
    var startRoom = _tryCreateRoom(_dungeon.depth);

    int x, y;
    do {
      x = rng.inclusive(0, _dungeon.width - startRoom.tiles.width);
      y = rng.inclusive(0, _dungeon.height - startRoom.tiles.height);

      // TODO: After a certain number of tries, should try a different room.
    } while (!startRoom.canPlaceAt(_dungeon, x, y, new Set()));

    startRoom.place(this, x, y);
  }

  bool _tryPlaceRoom(Junction junction, Set<Vec> passageTiles) {
    var room = _tryCreateRoom(_dungeon.depth, junction.theme);
    if (room == null) return false;

    var roomJunctions = room.junctions
        .where((roomJunction) =>
            roomJunction.direction == junction.direction.rotate180)
        .toList();
    rng.shuffle(roomJunctions);

    for (var roomJunction in roomJunctions) {
      // Calculate the room position by lining up the junctions.
      var roomPos = junction.position - roomJunction.position;

      if (!room.canPlaceAt(_dungeon, roomPos.x, roomPos.y, passageTiles)) {
        continue;
      }

      room.place(this, roomPos.x, roomPos.y, junction.position);
      return true;
    }

    return false;
  }

  Room _tryCreateRoom(int depth, [String from]) {
    from ??= "starting";

    var type = RoomTypes._resources.tryChoose(depth, from);
    if (type == null) return null;

    return type.create();
  }

  void _placeDoor(Vec pos) {
    // TODO: Take room theme into account when choosing what kind of door, if
    // any, to place.
    _dungeon.setTile(pos.x, pos.y, Tiles.closedDoor);

    // Since passages are placed after the room they connect to, they may
    // overlap a room junction. Remove that since it's pointless.
    _junctions.removeAt(pos);
  }

  void _tryAddJunction(String theme, Vec junctionPos, Direction junctionDir) {
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

    _junctions.add(new Junction(theme, junctionDir, junctionPos));
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
            _tryAddJunction("nature", neighbor, dir);
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

/// A single placeable instance of a room of some type.
class Room {
  final RoomType type;

  /// The tiles that should be placed for the room.
  final Array2D<TileType> tiles;
  final List<Junction> junctions;

  Room(this.type, this.tiles, this.junctions);

  bool canPlaceAt(Dungeon dungeon, int x, int y, Set<Vec> passageTiles) {
    if (!dungeon.bounds.containsRect(tiles.bounds.offset(x, y))) {
      return false;
    }

    for (var roomPos in tiles.bounds) {
      var mapPos = roomPos.offset(x, y);

      // If the room doesn't care about the tile, it's fine.
      if (tiles[roomPos] == null) continue;

      // If there is an incoming passage, the room can't overlap it.
      if (passageTiles.contains(mapPos)) {
        return false;
      }

      // If some different tile has already been placed here, we can't place
      // the room.
      var tile = dungeon.getTileAt(mapPos);
      if (tile != Tiles.rock && tile != tiles[roomPos]) {
        return false;
      }
    }

    return true;
  }

  void place(RoomBiome biome, int x, int y, [Vec junction]) {
    var cells = <Vec>[];

    if (junction != null) cells.add(junction);

    for (var pos in tiles.bounds) {
      var tile = tiles[pos];
      if (tile == null) continue;

      var absolute = pos.offset(x, y);
      biome._dungeon.setTileAt(absolute, tile);

      if (tile.isWalkable) cells.add(absolute);
    }

    // Add its junctions unless they are already blocked.
    var roomPos = new Vec(x, y);

    for (var junction in junctions) {
      biome._tryAddJunction(
          type.theme, roomPos + junction.position, junction.direction);
    }

    biome._dungeon
        .addPlace(new RoomPlace(type, cells, hasHero: junction == null));
  }
}

class RoomTypes {
  static final ResourceSet<RoomType> _resources = new ResourceSet();

  static bool allowsPassage(String type) =>
      type == "nature" ||
      type == "passage" ||
      _resources.hasTag(type, "passage");

  static void initialize() {
    if (_resources.isNotEmpty) return;

    Themes.defineTags(_resources);

    // Special tag to mark rooms that can be starting rooms.
    _resources.defineTags("starting");

    // TODO: Tune frequencies.
    add(
        new RectangleRoom("great-hall",
            spread: true, minWide: 8, maxWide: 16, minNarrow: 6, maxNarrow: 10),
        from: "chamber hall nature passage starting");
    add(
        new RectangleRoom("kitchen",
            minWide: 4, maxWide: 7, minNarrow: 6, maxNarrow: 12),
        from: "great-hall");
    add(new RectangleRoom("larder", maxWide: 6, maxNarrow: 5), from: "kitchen");
    add(new RectangleRoom("pantry", maxWide: 5, maxNarrow: 4),
        from: "kitchen larder storeroom");

    add(new RectangleRoom("chamber", minWide: 4, maxWide: 8, maxNarrow: 7),
        from: "chamber great-hall hall nature passage");

    add(new RectangleRoom("closet", maxWide: 5, maxNarrow: 4),
        from: "chamber laboratory storeroom");

    add(
        new RectangleRoom("laboratory",
            spread: true, minWide: 4, maxWide: 10, maxNarrow: 8),
        from: "hall laboratory passage");

    add(
        new RectangleRoom("storeroom",
            spread: true, minWide: 4, maxWide: 10, minNarrow: 4, maxNarrow: 10),
        from: "hall");

    add(
        new RectangleRoom("hall",
            minWide: 6, maxWide: 16, minNarrow: 2, maxNarrow: 4),
        from: "nature passage starting storeroom");
    // TODO: Custom classes for certain rooms:
    // - Great halls should usually have a big centered table, symmetric doors.
    // - Halls should have evenly placed doors.
    // - Etc.
    // TODO: Secret passages from closets.
  }

  /// Adds [type] to the set of room types. A room of this type can be created
  /// and attached to any existing room whose type is one of the
  /// space-separated names in [from].
  static void add(RoomType type, {double frequency, String from}) {
    // TODO: Different room types at different depths.
    _resources.add(type.theme, type, 1, frequency ?? 1.0, from);
  }
}

abstract class RoomType {
  // TODO: Use "theme" and "type" consistently.
  final String theme;
  final bool spread;

  RoomType(this.theme, {bool spread}) : spread = spread ?? false;

  Room create();
}

/// A simple rectangular room type with junctions randomly spaced around it.
class RectangleRoom extends RoomType {
  final int minWide;
  final int maxWide;
  final int minNarrow;
  final int maxNarrow;

  RectangleRoom(String theme,
      {bool spread, int minWide, int maxWide, int minNarrow, int maxNarrow})
      : minWide = minWide ?? 3,
        maxWide = maxWide ?? 8,
        minNarrow = minNarrow ?? 3,
        maxNarrow = maxNarrow ?? 8,
        super(theme, spread: spread);

  Room create() {
    var width = rng.inclusive(minWide, maxWide);
    var height = rng.inclusive(minNarrow, maxNarrow);
    if (rng.oneIn(2)) {
      var temp = width;
      width = height;
      height = temp;
    }

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
      junctions.add(new Junction(theme, Direction.n, new Vec(i + 1, 0)));
    });

    _placeJunctions(width, (i) {
      junctions
          .add(new Junction(theme, Direction.s, new Vec(i + 1, height + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(new Junction(theme, Direction.w, new Vec(0, i + 1)));
    });

    _placeJunctions(height, (i) {
      junctions
          .add(new Junction(theme, Direction.e, new Vec(width + 1, i + 1)));
    });

    return new Room(this, tiles, junctions);
  }

  /// Walks along [length], invoking [callback] at values where a junction
  /// should be placed.
  ///
  /// Ensures two junctions are not placed next to each other.
  void _placeJunctions(int length, void Function(int) callback) {
    var start = rng.oneIn(2) ? 0 : 1;
    for (var i = start; i < length; i++) {
      // TODO: Make chances tunable.
      if (rng.percent(40)) {
        callback(i);

        // Don't allow two junctions right next to each other.
        i++;
      }
    }
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

// TODO: Maybe use blob rooms for things like worm pits?
//class BlobRoom extends RoomType {
//  Room create(RoomTheme theme) {
//    // TODO: Other size blobs.
//    var blob = Blob.make16();
//    // Note: Assumes the blob never has open cells at the very edge.
//    var tiles = new Array2D<TileType>(blob.width, blob.height);
//    for (var pos in tiles.bounds.inflate(-1)) {
//      if (blob[pos]) {
//        tiles[pos] = Tiles.floor;
//
//        // If this cell is at the edge of the blob, ensure there is a ring of
//        // wall around it.
//        for (var dir in Direction.all) {
//          var neighbor = pos + dir;
//          if (tiles[neighbor] != Tiles.floor) {
//            tiles[neighbor] = Tiles.wall;
//          }
//        }
//      }
//    }
//
//    // TODO: Place junctions.
//    return new Room(theme, tiles, []);
//  }
//}
