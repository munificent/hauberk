import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'dungeon.dart';
import 'junction.dart';
import 'place.dart';
import 'room_types.dart';

class RoomPlace extends Place {
  final RoomType _type;

  RoomPlace(this._type, List<Vec> cells,
      {bool hasHero = false, bool emanates = false})
      : super(cells, 0.05, 0.05, hasHero: hasHero, emanates: emanates);

  /// Picks a theme based on the shape and size of the room.
  void applyThemes() {
    addTheme(_type.theme, 2.0, spread: _type.spread);

    monsterDensity *= _type.monsterDensity;
    monsterDepthOffset += _type.monsterDepthOffset;
    itemDensity *= _type.itemDensity;
    itemDepthOffset += _type.itemDepthOffset;
  }
}

class PassagePlace extends Place {
  PassagePlace(List<Vec> cells) : super(cells, 0.04, 0.02);

  void applyThemes() {
    addTheme("passage", 5.0, spread: false);
  }
}

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

  /// The pairs of points that we've run a pathfind between to look for a
  /// shortcut and where the path was too short to be a shortcut.
  ///
  /// We cache these because we often end up trying the same pairs of nodes
  /// over and over. If there is already a short path between them on the
  /// first try, it's not going to get any longer as the dungeon grows, so
  /// there is no need to recalculate it.
  final _failedShortcuts = Map<Vec, Set<Vec>>();

  RoomsBiome(this._dungeon);

  Iterable<String> generate() sync* {
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
    // If we've already checked and the path between these nodes isn't a
    // shortcut, don't try again.
    var cache = _failedShortcuts[from];
    if (cache != null && cache.contains(to)) return false;

    var pathfinder = CyclePathfinder(
        _dungeon.stage, from, to, length * _style.passageShortcutScale);

    var result = !pathfinder.search();
    if (!result) _failedShortcuts.putIfAbsent(from, () => Set()).add(to);
    return result;
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

    var type = RoomTypes.tryChoose(depth, from);
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
