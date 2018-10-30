// Rooms and passages generator.
//
// Unlike the keep and dungeon style, this explicitly builds branching passages.

/*
import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'architecture.dart';
import 'dungeon.dart';
import 'junction.dart';
import 'place.dart';
import 'room_type.dart';

class RoomPlace extends Place {
  final RoomType _type;

  RoomPlace(this._type, List<Vec> cells,
      {bool hasHero = false, bool emanates = false})
      : super(cells, 0.05, 0.05, hasHero: hasHero, emanates: emanates);

  double get decorDensity => 0.1;

  /// Picks a theme based on the shape and size of the room.
  void applyThemes() {
    addTheme(_type.theme, 2.0);
  }
}

class PassagePlace extends Place {
  PassagePlace(List<Vec> cells) : super(cells, 0.04, 0.02);

  // TODO: Change this if we add any passage decor.
  double get decorDensity => 0.0;

  void applyThemes() {
    addTheme("passage", 5.0, spread: false);
  }
}

/// A biome that generates a graph of connected rooms and passages.
///
/// This is the main biome that generates the majority of dungeon content.
class RoomsBiome extends Biome {
  final Dungeon _dungeon;
  final Architecture _architecture;
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

  RoomsBiome(this._dungeon)
      : _architecture = Architecture.choose(_dungeon.depth);

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
    for (var i = 0; i < junction.architecture.passageTries; i++) {
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

    if (++junction.tries < junction.architecture.junctionMaxTries) {
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
      if (rng.percent(junction.architecture.passageBranchPercent)) {
        newJunctions.add(Junction(junction.architecture, dir, pos + dir));
      }
    }

    var length = rng.inclusive(junction.architecture.passageMinLength,
        junction.architecture.passageMaxLength);
    while (passage.length < length) {
      // Don't allow turning twice in a row.
      if (distanceThisDir > 1 &&
          rng.percent(junction.architecture.passageTurnPercent)) {
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
      // TODO: This still seems to allow turns to brush against corners, like:
      //
      //      #.#
      //     ##.#
      //     ...###
      //     ###...
      //       #.##
      //       #.#

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
    var endJunction = Junction(junction.architecture, dir, pos);
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

      for (var neighbor in pos.neighbors) {
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
        _dungeon.stage, from, to, length * _architecture.passageShortcutScale);

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
    var room = _tryCreateRoom(_dungeon.depth, junction.architecture);
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

  Room _tryCreateRoom(int depth, [Architecture architecture]) {
    architecture = pickArchitecture(architecture);

    // TODO: Use tags.
    var type = architecture.roomTypes.tryChoose(depth, "room");
    if (type == null) return null;

    return type.create(architecture);
  }

  void _placeDoor(Vec pos) {
    // TODO: Take room theme into account when choosing what kind of door, if
    // any, to place.
    _dungeon.setTile(pos.x, pos.y, Tiles.closedDoor);

    // Since passages are placed after the room they connect to, they may
    // overlap a room junction. Remove that since it's pointless.
    _junctions.removeAt(pos);
  }

  void _tryAddJunction(
      Architecture architecture, Vec junctionPos, Direction junctionDir) {
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

    _junctions.add(Junction(architecture, junctionDir, junctionPos));
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
            _tryAddJunction(pickArchitecture(), neighbor, dir);
          }
          continue;
        }

        queue.add(neighbor);
        _reached.add(neighbor);
      }
    }
  }

  Architecture pickArchitecture([Architecture from]) {
    var architecture = from ?? _architecture;

    // Sometimes switch to a different architecture.
    if (rng.oneIn(10)) architecture = Architecture.choose(_dungeon.depth);

    return architecture;
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
      biome._tryAddJunction(junction.architecture, roomPos + junction.position,
          junction.direction);
    }

    // Rooms are more likely to be lit near the surface.
    // TODO: Take theme into account. Great halls should be more likely to be
    // lit than closets.
    var emanates = rng.percent(lerpInt(biome._dungeon.depth, 1, 50, 100, 00));
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

abstract class RoomType {
  final String theme;

  RoomType(this.theme);

  // TODO: Should arch be passed in or part of the room type itself?
  Room create(Architecture architecture);
}

/// A simple rectangular room type with junctions randomly spaced around it.
class RectangleRoom extends RoomType {
  final int _maxDimension;

  RectangleRoom(String theme, this._maxDimension) : super(theme);

  Room create(Architecture architecture) {
    // TODO: Constrain aspect ratio?
    var width = rng.inclusive(3, _maxDimension);
    var height = rng.inclusive(3, _maxDimension);
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
      junctions.add(Junction(architecture, Direction.n, Vec(i + 1, 0)));
    });

    _placeJunctions(width, (i) {
      junctions
          .add(Junction(architecture, Direction.s, Vec(i + 1, height + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(architecture, Direction.w, Vec(0, i + 1)));
    });

    _placeJunctions(height, (i) {
      junctions.add(Junction(architecture, Direction.e, Vec(width + 1, i + 1)));
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

class Junction {
  final Architecture architecture;

  /// Points from the first room towards where the new room should be attached.
  ///
  /// A room must have an opposing junction in order to match.
  final Direction direction;

  /// The location of the junction.
  ///
  /// For a placed room, this is in absolute coordinates. For a room yet to be
  /// placed, it's relative to the room's tile array.
  final Vec position;

  /// How many times we've tried to place something at this junction.
  int tries = 0;

  Junction(this.architecture, this.direction, this.position);
}

class JunctionSet {
  final Map<Vec, Junction> _byPosition = {};
  final Queue<Junction> _queue = Queue();

  bool get isNotEmpty => _queue.isNotEmpty;

  Junction at(Vec pos) => _byPosition[pos];

  void add(Junction junction) {
    if (_byPosition.containsKey(junction.position)) return;

    _byPosition[junction.position] = junction;
    _queue.add(junction);
  }

  Junction takeNext() {
    var junction = _queue.removeFirst();
    _byPosition.remove(junction.position);
    return junction;
  }

  void removeAt(Vec pos) {
    if (!_byPosition.containsKey(pos)) return;

    var junction = _byPosition[pos];
    _byPosition.remove(pos);
    _queue.remove(junction);
  }
}

*/
