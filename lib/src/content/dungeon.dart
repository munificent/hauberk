import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'affixes.dart';
import 'items.dart';
import 'monsters.dart';
import 'tiles.dart';
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
class Dungeon {
  static const numRoomTries = 60;
  static const numRoomPositionTries = 20;

  /// The inverse chance of adding a connector between two regions that have
  /// already been joined. Increasing this leads to more redundantly connected
  /// dungeons.
  static const extraConnectorChance = 40;

  final Stage stage;
  final int depth;

  Rect get bounds => stage.bounds;

  /// Increasing this allows rooms to be larger.
  int get roomExtraSize => 2;

  static const windingPercent = 30;

  final _rooms = <Rect, RoomType>{};
  final _connectors = <Vec>[];
  final _maze = <Vec>[];

  /// For each open position in the dungeon, the index of the connected region
  /// that that position is a part of.
  Array2D<int> _regions;

  /// The index of the current region being carved.
  int _currentRegion = -1;

  Dungeon(this.stage, this.depth);

  void generate() {
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

    fill(Tiles.wall);
    _regions = new Array2D(stage.width, stage.height);

    _addRooms();

    // Fill in all of the empty space with mazes.
    for (var y = 1; y < bounds.height; y += 2) {
      for (var x = 1; x < bounds.width; x += 2) {
        var pos = new Vec(x, y);
        if (getTile(pos) != Tiles.wall) continue;
        _growMaze(pos);
      }
    }

    _rooms.forEach((room, type) {
      type.place(this, room);
    });

    _connectRegions();
    _removeDeadEnds();

    // TODO: Temp hack. Place strairs in a more logical way.
    var numStairs = rng.inclusive(2, 10);
    for (var i = 0; i < numStairs; i++) {
      var pos = stage.findOpenTile();
      stage.tiles[pos].type = Tiles.stairs;
    }

    // Place the items.
    // TODO: Place into rooms. Give them themes, etc.
    var numItems = rng.taper(80 + depth * 2, 2);
    for (int i = 0; i < numItems; i++) {
      var pos = stage.findOpenTile();
      tryPlaceItem(pos, depth);
    }

    // Place the monsters.
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
  }

  void fill(TileType tile) {
    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        setTile(new Vec(x, y), tile);
      }
    }
  }

  void tryPlaceItem(Vec pos, int depth, [String tag]) {
    Tag itemTag;
    if (tag == null) {
      itemTag = Items.rootTag;
    } else {
      itemTag = Items.tags[tag];
    }

    var itemType = itemTag.choose(depth, Items.all.values);
    if (itemType == null) return;

    // TODO: Pass in levelOffset.
    var item = Affixes.createItem(itemType);
    item.pos = pos;
    stage.items.add(item);
  }

  void trySpawn(Vec pos, int depth) {
    var breed = Monsters.rootTag.choose(depth, Monsters.all);
    if (breed == null) return;

    stage.spawnMonster(breed, pos);
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

  void _connectRegions() {
    // Find all of the tiles that can connect two (or more) regions.
    var connectorRegions = <Vec, Set<int>>{};
    var allowed = bounds.inflate(-1);
    for (var pos in _connectors) {
      if (!allowed.contains(pos)) continue;

      var regions = new Set<int>();
      for (var dir in Direction.cardinal) {
        var region = _regions[pos + dir];
        if (region != null) regions.add(region);
      }

      if (regions.length < 2) continue;

      connectorRegions[pos] = regions;
    }

    var connectors = connectorRegions.keys.toList();

    // Keep track of which regions have been merged. This maps an original
    // region index to the one it has been merged to.
    var merged = {};
    var openRegions = new Set<int>();
    for (var i = 0; i <= _currentRegion; i++) {
      merged[i] = i;
      openRegions.add(i);
    }

    // Keep connecting regions until we're down to one.
    while (openRegions.length > 1) {
      var connector = rng.item(connectors);

      // Carve the connection.
      _addJunction(connector);

      // Merge the connected regions. We'll pick one region (arbitrarily) and
      // map all of the other regions to its index.
      var regions = connectorRegions[connector]
          .map((region) => merged[region]);
      var dest = regions.first;
      var sources = regions.skip(1).toList();

      // Merge all of the affected regions. We have to look at *all* of the
      // regions because other regions may have previously been merged with
      // some of the ones we're merging now.
      for (var i = 0; i <= _currentRegion; i++) {
        if (sources.contains(merged[i])) {
          merged[i] = dest;
        }
      }

      // The sources are no longer in use.
      openRegions.removeAll(sources);

      // Remove any connectors that aren't needed anymore.
      connectors.removeWhere((pos) {
        // Don't allow connectors right next to each other.
        if (connector - pos < 2) return true;

        // If the connector no long spans different regions, we don't need it.
        var regions = connectorRegions[pos].map((region) => merged[region])
            .toSet();

        if (regions.length > 1) return false;

        // This connecter isn't needed, but connect it occasionally so that the
        // dungeon isn't singly-connected.
        if (rng.oneIn(extraConnectorChance)) _addJunction(pos);

        return true;
      });
    }
  }

  void _addJunction(Vec pos) {
    if (rng.oneIn(4)) {
      setTile(pos, rng.oneIn(3) ? Tiles.openDoor : Tiles.floor);
    } else {
      setTile(pos, Tiles.closedDoor);
    }
  }

  void _removeDeadEnds() {
    var done = false;

    while (!done) {
      done = true;

      for (var pos in _maze) {
        if (getTile(pos) == Tiles.wall) continue;

        // If it only has one exit, it's a dead end.
        var exits = 0;
        for (var dir in Direction.cardinal) {
          if (getTile(pos + dir) != Tiles.wall) exits++;
        }

        if (exits != 1) continue;

        done = false;
        setTile(pos, Tiles.wall);
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
