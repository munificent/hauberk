import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'affixes.dart';
import 'items.dart';
import 'monsters.dart';
import 'stage_builder.dart';
import 'tiles.dart';

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
class Dungeon extends StageBuilder {
  static const numRoomTries = 20;
  static const numRoomPositionTries = 20;

  /// The inverse chance of adding a connector between two regions that have
  /// already been joined. Increasing this leads to more redundantly connected
  /// dungeons.
  static const extraConnectorChance = 40;

  /// Increasing this allows rooms to be larger.
  int get roomExtraSize => 2;

  static const windingPercent = 30;

  final _rooms = <Rect, RoomType>{};
  final _connectors = <Vec>[];

  /// For each open position in the dungeon, the index of the connected region
  /// that that position is a part of.
  Array2D<int> _regions;

  /// The index of the current region being carved.
  int _currentRegion = -1;

  void generate(Stage stage, int depth) {
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

    bindStage(stage);

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
      var itemType = Items.rootTag.choose(depth, Items.all.values);
      if (itemType == null) continue;

      var pos = stage.findOpenTile();
      // TODO: Pass in levelOffset.
      var item = Affixes.createItem(itemType);
      item.pos = pos;
      stage.items.add(item);
    }

    // Place the monsters.
    // TODO: Tune this. Make it based on depth. Take density of open areas into
    // account?
    // TODO: Place monsters into rooms. Give them themes.
    var numMonsters = rng.taper(30 + depth, 2);
    for (int i = 0; i < numMonsters; i++) {
      var breed = Monsters.rootTag.choose(depth, Monsters.all);
      if (breed == null) continue;

      // TODO: Place strong monsters farther from the hero?
      var pos = stage.findOpenTile();
      stage.spawnMonster(breed, pos);
    }
  }

  void onDecorateRoom(Rect room) {}

  /// Implementation of the "growing tree" algorithm from here:
  /// http://www.astrolog.org/labyrnth/algrithm.htm.
  void _growMaze(Vec start) {
    var cells = <Vec>[];
    var lastDir;

    _startRegion();
    _carve(start);

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
    // TODO: Make some room types rarer than others. Tune by depth.
    var roomTypes = [
      new RectangleRoom(3, 3),
      new RectangleRoom(5, 3), new RectangleRoom(3, 5),
      new RectangleRoom(5, 5),
      new RectangleRoom(7, 5), new RectangleRoom(5, 7),
      new RectangleRoom(9, 5), new RectangleRoom(5, 9),
      new RectangleRoom(9, 7), new RectangleRoom(7, 9),
      new RectangleRoom(11, 7), new RectangleRoom(7, 11),
      new RectangleRoom(11, 9), new RectangleRoom(9, 11),
      new RectangleRoom(11, 11),
      new RectangleRoom(13, 7), new RectangleRoom(7, 13),
      new RectangleRoom(13, 9), new RectangleRoom(9, 13),
      new OctagonRoom(5, 5, 1),
      new OctagonRoom(7, 7, 2),
      new OctagonRoom(9, 9, 2),
      new OctagonRoom(9, 9, 3),
      new OctagonRoom(11, 11, 2),
      new OctagonRoom(11, 11, 3),
    ];

    for (var i = 0; i < numRoomTries; i++) {
      var roomType = rng.item(roomTypes);
      for (var j = 0; j < numRoomPositionTries; j++) {
        var x = rng.range((bounds.width - roomType.width) ~/ 2) * 2 + 1;
        var y = rng.range((bounds.height - roomType.height) ~/ 2) * 2 + 1;

        var room = new Rect(x, y, roomType.width, roomType.height);

        var overlaps = false;
        for (var other in _rooms.keys) {
          if (room.distanceTo(other) <= 0) {
            overlaps = true;
            break;
          }
        }

        if (overlaps) continue;

        _rooms[room] = roomType;

        _startRegion();

        for (var pos in room) {
          _carve(pos);
        }
      }
    }
  }

  void _addConnector(int x, int y) {
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

      for (var pos in bounds.inflate(-1)) {
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

abstract class RoomType {
  int get width;
  int get height;

  /// Fill in the bounds of [room] with this room's individual style.
  ///
  /// Also, add any connectors as are possible from the room.
  ///
  /// When this is called, [room] will already be cleared to all floor.
  void place(Dungeon dungeon, Rect room);

  void decorate(Dungeon dungeon, Rect room) {
    if (rng.oneIn(2)) {
      var tables = rng.inclusive(1, 3);
      for (var i = 0; i < tables; i++) {
        decorateTable(dungeon, room);
      }
    }
  }

  /// Tries to place a table in the room.
  bool decorateTable(Dungeon dungeon, Rect room) {
    var pos = rng.vecInRect(room);

    if (dungeon.getTile(pos) != Tiles.floor) return false;

    // Don't block an exit.
    if (pos.x == room.left && dungeon.getTile(pos.offsetX(-1)) != Tiles.wall) {
      return false;
    }

    if (pos.y == room.top && dungeon.getTile(pos.offsetY(-1)) != Tiles.wall) {
      return false;
    }

    if (pos.x == room.right && dungeon.getTile(pos.offsetX(1)) != Tiles.wall) {
      return false;
    }

    if (pos.y == room.bottom && dungeon.getTile(pos.offsetY(1)) != Tiles.wall) {
      return false;
    }

    dungeon.setTile(pos, Tiles.table);
    return true;
  }
}

class RectangleRoom extends RoomType {
  final int width;
  final int height;

  RectangleRoom(this.width, this.height);

  void place(Dungeon dungeon, Rect room) {
    for (var x = room.left; x < room.right; x++) {
      dungeon._addConnector(x, room.top - 1);
      dungeon._addConnector(x, room.bottom);
    }

    for (var y = room.top; y < room.bottom; y++) {
      dungeon._addConnector(room.left - 1, y);
      dungeon._addConnector(room.right, y);
    }

    decorate(dungeon, room);
  }
}

class OctagonRoom extends RoomType {
  final int width;
  final int height;
  final int slope;

  OctagonRoom(this.width, this.height, this.slope);

  void place(Dungeon dungeon, Rect room) {
    for (var pos in room) {
      // Fill in the corners.
      if ((room.topLeft - pos).rookLength < slope ||
          (room.topRight - pos).rookLength < slope + 1 ||
          (room.bottomLeft - pos).rookLength < slope + 1 ||
          (room.bottomRight - pos).rookLength < slope + 2) {
        dungeon.setTile(pos, Tiles.wall);
      }
    }

    // TODO: Decorate inside?

    dungeon._addConnector(room.center.x, room.top - 1);
    dungeon._addConnector(room.center.x, room.bottom);
    dungeon._addConnector(room.left - 1, room.center.y);
    dungeon._addConnector(room.right, room.center.y);

    decorate(dungeon, room);
  }
}
