import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../themes.dart';
import '../tiles.dart';
import 'dungeon.dart';
import 'junction.dart';
import 'place.dart';

class RoomPlace extends Place {
  final RoomType _type;

  RoomPlace(this._type, List<Vec> cells,
      {bool hasHero = false, bool emanates = false})
      : super(cells, 0.05, 0.05, hasHero: hasHero, emanates: emanates);

  /// Picks a theme based on the shape and size of the room.
  void applyThemes() {
    addTheme(_type.theme, 2.0, spread: _type.spread);
    // TODO: Make theme affect monster and item density.
  }
}

class PassagePlace extends Place {
  PassagePlace(List<Vec> cells) : super(cells, 0.04, 0.02);

  void applyThemes() {
    addTheme("passage", 5.0, spread: false);
  }
}

// TODO: Delete. Figure out what to do with stair room and wall torch code.
//class PlainRoom extends RoomStyle {
//  void decorate(RoomPlace place, Dungeon dungeon) {
//    _tryPlaceDoorTorches(place, dungeon);
//  }
//
//  /// Try to place some torches around doors.
//  void _tryPlaceDoorTorches(RoomPlace place, Dungeon dungeon) {
//    // TODO: Make these more strategic.
//    canPlaceTorchAt(int x, int y) {
//      if (dungeon.getTile(x, y) != Tiles.wall) return false;
//
//      return true;
//    }
//
//    for (var junction in place._room.junctions) {
//      var pos = junction.position + place._pos;
//
//      if (dungeon.getTileAt(pos) != Tiles.closedDoor) continue;
//      if (!rng.oneIn(5)) continue;
//
//      if (canPlaceTorchAt(pos.x - 1, pos.y) &&
//          canPlaceTorchAt(pos.x + 1, pos.y)) {
//        dungeon.setTile(pos.x - 1, pos.y, Tiles.wallTorch);
//        dungeon.setTile(pos.x + 1, pos.y, Tiles.wallTorch);
//      } else if (canPlaceTorchAt(pos.x, pos.y - 1) &&
//          canPlaceTorchAt(pos.x, pos.y + 1)) {
//        dungeon.setTile(pos.x, pos.y - 1, Tiles.wallTorch);
//        dungeon.setTile(pos.x, pos.y + 1, Tiles.wallTorch);
//      }
//    }
//  }
//}
//
//class SmallStairRoom extends RoomStyle {
//  void decorate(RoomPlace place, Dungeon dungeon) {
//    var bounds =
//        place._room.tiles.bounds.inflate(-1).offset(place._pos.x, place._pos.y);
//
//    // Place the stairs in the middle.
//    var stairs = rng.vecInRect(bounds.inflate(-1));
//    dungeon.setTileAt(stairs, Tiles.stairs);
//
//    if (rng.oneIn(3)) _addTorches(bounds, place, dungeon);
//  }
//
//  void _addTorches(Rect bounds, RoomPlace place, Dungeon dungeon) {
//    // Find out which corners permit torches.
//    var left = bounds.left;
//    var right = bounds.right - 1;
//    var top = bounds.top;
//    var bottom = bounds.bottom - 1;
//
//    var canTopLeft = dungeon.getTile(left - 1, top) == Tiles.wall &&
//        dungeon.getTile(left, top - 1) == Tiles.wall;
//
//    var canTopRight = dungeon.getTile(right + 1, top) == Tiles.wall &&
//        dungeon.getTile(right, top - 1) == Tiles.wall;
//
//    var canBottomLeft = dungeon.getTile(left - 1, bottom) == Tiles.wall &&
//        dungeon.getTile(left, bottom + 1) == Tiles.wall;
//
//    var canBottomRight = dungeon.getTile(right + 1, bottom) == Tiles.wall &&
//        dungeon.getTile(right, bottom + 1) == Tiles.wall;
//
//    // Place torches in the corners when we can do adjacent pairs.
//    if (canTopLeft && canTopRight) {
//      dungeon.setTile(left, top, Tiles.wallTorch);
//      dungeon.setTile(right, top, Tiles.wallTorch);
//    }
//
//    if (canBottomLeft && canBottomRight) {
//      dungeon.setTile(left, bottom, Tiles.wallTorch);
//      dungeon.setTile(right, bottom, Tiles.wallTorch);
//    }
//
//    if (canTopLeft && canBottomLeft) {
//      dungeon.setTile(left, top, Tiles.wallTorch);
//      dungeon.setTile(left, bottom, Tiles.wallTorch);
//    }
//
//    if (canTopRight && canBottomRight) {
//      dungeon.setTile(right, top, Tiles.wallTorch);
//      dungeon.setTile(right, bottom, Tiles.wallTorch);
//    }
//  }
//}

// TODO: Define different ones of this to have different styles.
class RoomStyle {
  final int passageTurnPercent = 30;
  final int passageBranchPercent = 40;
  final int passageStopPercent = 10;
  final int passageMinLength = 4;
  final int passageTries = 20;

  /// A passage that connects to an existing place, by definition, adds a cycle
  /// to the dungeon. We don't want to do that if there is always a similar
  /// path between those two points. A cycle should only be added if it connects
  /// two very disparate regions (in terms of reachability).
  ///
  /// To get that, we only place a cyclic passage if the shortest existing
  /// route between the two points is longer than the new passage's length times
  /// this scale. Making this smaller adds more cycles.
  final int passageShortcutScale = 10;

  final int junctionMaxTries = 10;
}

/// A biome that generates a graph of connected rooms and passages.
///
/// This is the main biome that generates the majority of dungeon content.
class RoomsBiome extends Biome {
  final Dungeon _dungeon;
  final RoomStyle _style = RoomStyle();
  final JunctionSet _junctions = JunctionSet();

  /// The tiles in other biomes that the rooms have connected to already.
  final Set<Vec> _reached = Set();

  RoomsBiome(this._dungeon);

  Iterable<String> generate() sync* {
    RoomTypes.initialize();

    yield "Add starting room";
    _createStartingRoom();

    yield "Adding rooms";

    // Keep growing as long as we have attachment points.
    var roomNumber = 1;
    while (_junctions.isNotEmpty) {
      var junction = _junctions.takeNext();
      if (_tryJunction(junction)) {
        yield "Room $roomNumber";
        roomNumber++;
      }
    }
  }

  /// Attempts to place something at [junction]. Returns `true` if successful.
  bool _tryJunction(Junction junction) {
    // Try a passage.
    for (var i = 0; i < _style.passageTries; i++) {
      if (_tryPlacePassageRoom(junction)) {
        return true;
      }
    }

    // See if there is another biome on the other side.
    var from = junction.position - junction.direction;
    var to = junction.position + junction.direction;
    if (_isOtherBiome(to) && _isShortcut(from, to, 1)) {
      _placeDoor(junction.position);
      _reachOtherBiome(to);
      return true;
    }

    if (_dungeon.getTileAt(to) != Tiles.rock) return false;

    // Try a room.
    if (_tryPlaceRoom(junction, Set())) {
      _placeDoor(junction.position);
      return true;
    }

    if (++junction.tries < _style.junctionMaxTries) {
      // Couldn't place it, so re-add to try the junction again.
      _junctions.add(junction);
    }

    return false;
  }

  /// Try to make a meandering passage starting at [junction] that ends in a
  /// new room or connects to an existing junction.
  ///
  /// Propagates the theme of the room this passage is attached to.
  bool _tryPlacePassageRoom(Junction junction) {
    // Make a meandering passage.
    var pos = junction.position;
    var dir = junction.direction;
    var distanceThisDir = 0;
    var passage = [pos].toSet();
    var newJunctions = <Junction>[];

    maybeBranch(Direction dir) {
      if (rng.percent(_style.passageBranchPercent)) {
        newJunctions.add(Junction(junction.theme, dir, pos + dir));
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
      passage.add(pos);

      // TODO: Only allow a shortcut to a valid child room?
      // If the passage connects up to an existing junction, consider adding a
      // cycle.
      var reachedJunction = _junctions.at(pos);
      if (reachedJunction != null &&
          reachedJunction.direction == dir.rotate180) {
        // TODO: Could allow shorter passages if we don't place a door. The
        // length check is mainly to avoid doors next to each other.
        if (passage.length <= 2 ||
            !_isShortcut(junction.position, pos + dir, passage.length)) {
          return false;
        }

        _junctions.removeAt(pos);
        _placePassage(pos, junction, passage, newJunctions);
        return true;
      }

      // If the passage connects to another biome, stop there and then traverse
      // through it.
      if (_isOtherBiome(pos)) {
        if (passage.length <= 3 ||
            !_isShortcut(junction.position, pos + dir, passage.length)) {
          return false;
        }

        _reachOtherBiome(pos);

        // Don't include the step into the other biome itself.
        passage.remove(pos);
        pos -= dir;

        _placePassage(pos, junction, passage, newJunctions);
        return true;
      }

      // Don't allow it to brush against the edge of anything else. We check
      // this after handling shortcuts and nature because in those cases, we
      // do allow open diagonal tiles.
      var left = pos + dir.rotateLeft90;
      var right = pos + dir.rotateRight90;

      if (!_dungeon.safeBounds.contains(left)) return false;
      if (_dungeon.getTileAt(left).isTraversable) return false;
      if (passage.contains(left)) return false;
      if (!_dungeon.safeBounds.contains(right)) return false;
      if (_dungeon.getTileAt(right).isTraversable) return false;
      if (passage.contains(right)) return false;

      distanceThisDir++;
    }

    // The last passage position will always become the door.
    passage.remove(passage.last);

    // If we didn't connect to an existing junction, add a new room at the end
    // of the passage. We require this to pass so that we avoid dead end
    // passages.
    var endJunction = Junction(junction.theme, dir, pos);
    if (!_tryPlaceRoom(endJunction, passage)) return false;

    _placePassage(pos, junction, passage, newJunctions);
    return true;
  }

  void _placePassage(Vec pos, Junction junction, Set<Vec> passage,
      List<Junction> newJunctions) {
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

    _dungeon.addPlace(PassagePlace(passage.toList()));
  }

  /// Returns `true` if a passage with [length] from [from] to [to] is
  /// significantly shorter than the current shortest path between those points.
  ///
  /// Used to avoid placing pointless redundant paths in the dungeon.
  bool _isShortcut(Vec from, Vec to, int length) {
    var pathfinder = CyclePathfinder(
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
    } while (!startRoom.canPlaceAt(_dungeon, x, y, Set()));

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
      return tile != Tiles.wall && tile != Tiles.rock && tile != Tiles.grass;
    }

    if (isBlocked(Direction.none)) return;
    if (isBlocked(junctionDir)) return;
    if (isBlocked(junctionDir.rotateLeft45)) return;
    if (isBlocked(junctionDir.rotateRight45)) return;
    if (isBlocked(junctionDir.rotateLeft90)) return;
    if (isBlocked(junctionDir.rotateRight90)) return;

    _junctions.add(Junction(theme, junctionDir, junctionPos));
  }

  bool _isOtherBiome(Vec pos) {
    var place = _dungeon.placeAt(pos);
    return place != null && place is! RoomPlace && place is! PassagePlace;
  }

  void _reachOtherBiome(Vec start) {
    if (_reached.contains(start)) return;

    var queue = Queue<Vec>.from([start]);
    _reached.add(start);

    // Breadth-first search over the reachable nature tiles.
    // TODO: Can we use Place for this? See if the start tile is in a different
    // place and, if so, iterate its cells?
    while (queue.isNotEmpty) {
      var pos = queue.removeFirst();

      for (var dir in Direction.all) {
        var neighbor = pos + dir;
        if (!_dungeon.bounds.contains(neighbor)) continue;

        if (_reached.contains(neighbor)) continue;

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

        queue.add(neighbor);
        _reached.add(neighbor);
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

  void place(RoomsBiome biome, int x, int y, [Vec junction]) {
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
    var roomPos = Vec(x, y);

    for (var junction in junctions) {
      biome._tryAddJunction(
          type.theme, roomPos + junction.position, junction.direction);
    }

    // Rooms are likely to be lit near the surface, but by depth 30, lit rooms
    // become rare.
    // TODO: Take theme into account. Great halls should be more likely to be
    // lit than closets.
    var emanates = rng.percent(lerpInt(biome._dungeon.depth, 1, 30, 80, 10));
    biome._dungeon.addPlace(
        RoomPlace(type, cells, hasHero: junction == null, emanates: emanates));
  }
}

class RoomTypes {
  static final ResourceSet<RoomType> _resources = ResourceSet();

  static void initialize() {
    if (_resources.isNotEmpty) return;

    Themes.defineTags(_resources);

    // Special tag to mark rooms that can be starting rooms.
    _resources.defineTags("starting");

    // TODO: Tune frequencies.
    add(
        RectangleRoom("great-hall",
            spread: true, minWide: 8, maxWide: 16, minNarrow: 6, maxNarrow: 10),
        from: "chamber hall nature starting");
    add(
        RectangleRoom("kitchen",
            minWide: 4, maxWide: 7, minNarrow: 6, maxNarrow: 12),
        from: "great-hall");
    add(RectangleRoom("larder", maxWide: 6, maxNarrow: 5),
        frequency: 0.2, from: "kitchen");
    add(RectangleRoom("pantry", maxWide: 5, maxNarrow: 4),
        frequency: 0.1, from: "kitchen larder storeroom");

    add(RectangleRoom("chamber", minWide: 4, maxWide: 8, maxNarrow: 7),
        from: "chamber great-hall hall nature");

    add(RectangleRoom("closet", maxWide: 5, maxNarrow: 4),
        frequency: 0.2, from: "chamber laboratory storeroom");

    add(
        RectangleRoom("laboratory",
            spread: true, minWide: 4, maxWide: 10, maxNarrow: 8),
        from: "hall laboratory");

    add(
        RectangleRoom("storeroom",
            spread: true, minWide: 4, maxWide: 10, minNarrow: 4, maxNarrow: 10),
        from: "hall");

    add(
        RectangleRoom("hall",
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

    var tiles = Array2D<TileType>(width + 2, height + 2, Tiles.floor);

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
      junctions.add(Junction(theme, Direction.n, Vec(i + 1, 0)));
    });

    _placeJunctions(width, (i) {
      junctions.add(Junction(theme, Direction.s, Vec(i + 1, height + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(theme, Direction.w, Vec(0, i + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(theme, Direction.e, Vec(width + 1, i + 1)));
    });

    return Room(this, tiles, junctions);
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
    if (tile.canEnter(Motility.doorAndWalk)) return 1;

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
