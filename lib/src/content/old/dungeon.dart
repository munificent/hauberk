import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../item/affixes.dart';
import '../item/items.dart';
import '../monster/monsters.dart';
import '../tiles.dart';
import 'rooms.dart';

/// The random dungeon generator.
///
/// Starting with a stage of solid walls, it works like so:
///
/// 1. Place a number of randomly sized and positioned rooms. If a room
///    overlaps an existing room, it is discarded. Any remaining rooms are
///    carved out.
/// 2. Any remaining solid areas are filled in with mazes. The maze generator
///    will grow and fill in even odd-shaped areas, but will not touch any
///    rooms.
/// 3. The result of the previous two steps is a series of unconnected rooms
///    and mazes. We walk the stage and find every tile that can be a
///    "connector". This is a solid tile that is adjacent to two unconnected
///    regions.
/// 4. We randomly choose connectors and open them or place a door there until
///    all of the unconnected regions have been joined. There is also a slight
///    chance to carve a connector between two already-joined regions, so that
///    the dungeon isn't single connected.
/// 5. The mazes will have a lot of dead ends. Finally, we remove those by
///    repeatedly filling in any open tile that's closed on three sides. When
///    this is done, every corridor in a maze actually leads somewhere.
///
/// The end result of this is a multiply-connected dungeon with rooms and lots
/// of winding corridors.
class OldDungeon {
  static const numRoomTries = 60;
  static const numRoomPositionTries = 20;

  /// The number of extra junctions to add to make the dungeon more than simply
  /// connected.
  static const maxCycles = 20;

  /// How long the path around two sides of a junction must be to be worth
  /// adding a cycle there.
  static const minCyclePath = 20;

  final Stage stage;
  final int depth;

  Rect get bounds => stage.bounds;

  /// Increasing this allows rooms to be larger.
  int get roomExtraSize => 2;

  static const windingPercent = 80;

  final _rooms = <Rect, RoomType>{};
  final _connectors = <Vec>[];
  final _maze = <Vec>[];

  /// For each open position in the dungeon, the index of the connected region
  /// that that position is a part of.
  Array2D<int> _regions;

  /// The index of the current region being carved.
  int _currentRegion = -1;

  OldDungeon(this.stage, this.depth);

  Iterable<String> generate() sync* {
    // TODO: This occasionally generates dungeons with unreachable areas. I
    // think it's because of the limited connectors exposed by some room types.
    // Need to decide how to handle that.
    //
    // The simplest solution is to add a "give up" command and permit it to
    // happen. Characters with stone to mud or teleportation may be able to
    // escape.

    if (stage.width % 2 == 0 || stage.height % 2 == 0) {
      throw new ArgumentError("The stage must be odd-sized.");
    }

    _regions = new Array2D(stage.width, stage.height);
    fill(Tiles.wall);

    yield "Placing rooms";
    _addRooms();

    yield "Carving passageways";
    // Fill in all of the empty space with mazes.
    for (var y = 1; y < bounds.height; y += 2) {
      for (var x = 1; x < bounds.width; x += 2) {
        var pos = new Vec(x, y);
        if (getTile(pos) != Tiles.wall) continue;
        _growMaze(pos);
      }
    }

    yield "Decorating rooms";
    _rooms.forEach((room, type) {
      type.place(this, room);
    });

    yield "Connecting regions";
    _connectRegions();

    yield "Adding extra connections";
    _addCycles();

    yield "Removing dead ends";
    _removeDeadEnds();

    // TODO: Temp hack. Place stairs in a more logical way.
    var numStairs = rng.inclusive(2, 10);
    for (var i = 0; i < numStairs; i++) {
      var pos = stage.findOpenTile();
      stage.tiles[pos].type = Tiles.stairs;
    }

    yield "Dropping loot";
    // TODO: Place into rooms. Give them themes, etc.
    var numItems = rng.taper(50 + depth * 2, 2);
    for (int i = 0; i < numItems; i++) {
      var pos = stage.findOpenTile();
      tryPlaceItem(pos, depth);
    }

    yield "Spawning monsters";
    // TODO: Tune this. Make it based on depth. Take density of open areas into
    // account?
    // TODO: Place monsters into rooms. Give them themes.
    var numMonsters = rng.taper(30 + depth, 2);
    for (int i = 0; i < numMonsters; i++) {
      var pos = stage.findOpenTile();
      trySpawn(pos, depth);
    }
  }

  TileType getTile(Vec pos) => stage[pos].type;

  void setTile(Vec pos, TileType type) {
    stage[pos].type = type;

    // If we're filling in a part of a room, don't try to connect a junction
    // to it.
    if (!type.isTraversable) _regions[pos] = null;
  }

  void fill(TileType tile) {
    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        setTile(new Vec(x, y), tile);
      }
    }
  }

  void tryPlaceItem(Vec pos, int depth) {
    var itemType = Items.types.tryChoose(depth, "item");
    if (itemType == null) return;

    var item = Affixes.createItem(itemType, depth);
    stage.addItem(item, pos);
  }

  void trySpawn(Vec pos, int depth) {
    var breed = Monsters.breeds.tryChoose(depth, "monster");
    if (breed == null) return;

    // TODO: Gone.
//    stage.spawnMonster(breed, pos: pos);
  }

  /// Implementation of the "growing tree" algorithm from here:
  /// http://www.astrolog.org/labyrnth/algrithm.htm.
  void _growMaze(Vec start) {
    var cells = <Vec>[];
    var lastDir;

    _startRegion();
    _carve(start);
    _maze.add(start);

    cells.add(start);
    while (cells.isNotEmpty) {
      var cell = cells.last;

      // See which adjacent cells are open.
      var unmadeCells = <Direction>[];

      for (var dir in Direction.cardinal) {
        if (_canCarve(cell, dir)) unmadeCells.add(dir);
      }

      if (unmadeCells.isNotEmpty) {
        // Based on how "windy" passages are, try to prefer carving in the
        // same direction.
        var dir;
        if (unmadeCells.contains(lastDir) && rng.range(100) > windingPercent) {
          dir = lastDir;
        } else {
          dir = rng.item(unmadeCells);
        }

        _carve(cell + dir);
        _carve(cell + dir * 2);
        _maze.add(cell + dir);
        _maze.add(cell + dir * 2);

        cells.add(cell + dir * 2);
        lastDir = dir;
      } else {
        // No adjacent uncarved cells.
        cells.removeLast();

        // This path has ended.
        lastDir = null;
      }
    }
  }

  void _addRooms() {
    for (var i = 0; i < numRoomTries; i++) {
      var roomType = RoomType.choose(depth);

      var room = _tryFindOpenSpace(roomType.width, roomType.height);
      if (room == null) continue;

      _rooms[room] = roomType;
      _startRegion();

      for (var pos in room) {
        _carve(pos);
      }
    }
  }

  /// Tries to find an open area large enough for a room with size [width],
  /// [height].
  ///
  /// Returns `null` if not found.
  Rect _tryFindOpenSpace(int width, int height) {
    for (var j = 0; j < numRoomPositionTries; j++) {
      var x = rng.range((bounds.width - width) ~/ 2) * 2 + 1;
      var y = rng.range((bounds.height - height) ~/ 2) * 2 + 1;

      var room = new Rect(x, y, width, height);

      var overlaps = false;
      for (var other in _rooms.keys) {
        if (room.distanceTo(other) <= 0) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) return room;
    }

    return null;
  }

  void addConnector(int x, int y) {
    var pos = new Vec(x, y);
    if (!bounds.inflate(-1).contains(pos)) return;

    _connectors.add(pos);
  }

  /// Add junctions to the dungeon until each unconnected region is no longer
  /// unconnected.
  ///
  /// This effectively computes a random spanning tree, with a few extra
  /// random junctions so that the dungeon isn't tree-like.
  void _connectRegions() {
    // Keep track of which regions can been merged together. This maps a
    // region's original id to its merged one. When a set of regions are
    // connected to each other, we give them all the lowest id as their new
    // region id.
    var mergedRegions = <int, int>{};
    for (var i = 0; i <= _currentRegion; i++) {
      mergedRegions[i] = i;
    }

    var allowedBounds = bounds.inflate(-1);

    // Try each connector in random order.
    rng.shuffle(_connectors);
    for (var pos in _connectors) {
      if (!allowedBounds.contains(pos)) continue;

      // Find the regions this connector touches.
      var touchingJunction = false;
      var regions = new Set<int>();
      for (var dir in Direction.cardinal) {
        var region = _regions[pos + dir];
        if (region == null) continue;

        if (region == -1) {
          // A tile directly adjacent to this one was already turned into a
          // junction. Skip this one. We don't want to end up with doors right
          // next to each other.
          touchingJunction = true;
          break;
        }

        region = mergedRegions[region];
        regions.add(region);
      }

      // Don't place two connectors right next to each other.
      if (touchingJunction) continue;

      if (regions.length >= 2) {
        // This junction connects two unmerged regions, so merge them.
        _addJunction(pos);

        // This becomes the new id.
        var mergedTo = regions.first;

        // And the remaining regions will be mapped to that.
        var mergedFrom = regions.skip(1).toSet();

        for (var i = 0; i <= _currentRegion; i++) {
          if (mergedFrom.contains(mergedRegions[i])) {
            mergedRegions[i] = mergedTo;
          }
        }
      }
    }
  }

  void _addJunction(Vec pos) {
    if (rng.oneIn(4)) {
      setTile(pos, rng.oneIn(3) ? Tiles.openDoor : Tiles.floor);
    } else {
      setTile(pos, Tiles.closedDoor);
    }

    // Mark this tile as containing a junction.
    _regions[pos] = -1;
  }

  /// Open additional junctions that aren't necessary to make the dungeon
  /// connected.
  void _addCycles() {
    var cycles = 0;

    for (var pos in _connectors) {
      // If it's already connected, ignore it.
      if (getTile(pos) != Tiles.wall) continue;

      var exits = Direction.cardinal
          .map((dir) => pos + dir)
          .where((neighbor) => getTile(neighbor) != Tiles.wall)
          .toList();

      // Only consider extra junctions that directly connect two open areas.
      if (exits.length != 2) continue;

      // Only add cycles if they add significant shortcuts.
      // TODO: Instead of a hard cut-off, maybe shorter paths should just make
      // cycles less common?
//      var path = AStar.findPath(
//          stage, exits[0], exits[1], MotilitySet.walkAndDoor,
//          maxLength: minCyclePath);
//      if (path.length != 0 && path.length < minCyclePath) continue;

      _addJunction(pos);

      cycles++;
      if (cycles > maxCycles) break;
    }
  }

  void _removeDeadEnds() {
    var toCheck = new Queue<Vec>.from(_maze);
    while (toCheck.isNotEmpty) {
      var pos = toCheck.removeFirst();

      if (getTile(pos) == Tiles.wall) continue;

      // If it only has one exit, it's a dead end.
      var exits = 0;
      for (var dir in Direction.cardinal) {
        if (getTile(pos + dir).isTraversable) exits++;
      }

      if (exits != 1) continue;

      // It's a dead end.
      setTile(pos, Tiles.wall);

      // Its neighbors may be dead ends now.
      for (var dir in Direction.cardinal) {
        toCheck.add(pos + dir);
      }
    }
  }

  /// Gets whether or not an opening can be carved from the given starting
  /// [Cell] at [pos] to the adjacent Cell facing [direction]. Returns `true`
  /// if the starting Cell is in bounds and the destination Cell is filled
  /// (or out of bounds).</returns>
  bool _canCarve(Vec pos, Direction direction) {
    // Must end in bounds.
    if (!bounds.contains(pos + direction * 3)) return false;

    // Destination must not be open.
    return getTile(pos + direction * 2) == Tiles.wall;
  }

  void _startRegion() {
    _currentRegion++;
  }

  void _carve(Vec pos, [TileType type]) {
    if (type == null) type = Tiles.floor;
    setTile(pos, type);
    _regions[pos] = _currentRegion;
  }
}
