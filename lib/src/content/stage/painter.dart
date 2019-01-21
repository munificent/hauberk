import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'architect.dart';
import 'decorator.dart';

/// The procedural interface exposed by [Decorator] to let a [PaintStyle]
/// modify the stage.
class Painter {
  final Decorator _decorator;
  final Architect _architect;
  final Architecture _architecture;
  int _painted = 0;

  Painter(this._decorator, this._architect, this._architecture);

  Rect get bounds => _architect.stage.bounds;

  List<Vec> get ownedTiles => _decorator.tilesFor(_architecture);

  int get paintedCount => _painted;

  int get depth => _architect.depth;

  bool ownsTile(Vec pos) => _architect.ownerAt(pos) == _architecture;

  TileType getTile(Vec pos) {
    return _architect.stage[pos].type;
  }

  void setTile(Vec pos, TileType type) {
    assert(_architect.ownerAt(pos) == _architecture);
    _architect.stage[pos].type = type;
    _painted++;
  }

  bool hasActor(Vec pos) => _architect.stage.actorAt(pos) != null;

  Breed chooseBreed(int depth, {String tag, bool includeParentTags}) {
    return _decorator.chooseBreed(depth,
        tag: tag, includeParentTags: includeParentTags);
  }

  void spawnMonster(Vec pos, Breed breed) {
    _decorator.spawnMonster(pos, breed);
  }
}

/// Each style is a custom "look" that translates the semantic temporary
/// tiles into specific concrete tile types.
class PaintStyle {
  static final rock = PaintStyle();
  static final flagstone = PaintStyle(
      floor: [Tiles.flagstoneFloor],
      wall: [Tiles.flagstoneWall],
      closedDoor: Tiles.closedDoor,
      openDoor: Tiles.openDoor);
  static final granite = PaintStyle(
      floor: [Tiles.graniteFloor],
      wall: [Tiles.graniteWall],
      closedDoor: Tiles.closedSquareDoor);
  static final stoneJail = PaintStyle(closedDoor: Tiles.closedBarredDoor);

  static Map<TileType, List<TileType>> _defaultTypes = {
    Tiles.solidWet: [Tiles.water],
    Tiles.passageWet: [Tiles.bridge]
  };

  static List<TileType> _defaultWalls = [
    Tiles.granite1,
    Tiles.granite2,
    Tiles.granite3
  ];

  final List<TileType> _floor;
  final List<TileType> _wall;
  final TileType _closedDoor;
  final TileType _openDoor;

  PaintStyle(
      {List<TileType> floor,
      List<TileType> wall,
      TileType closedDoor,
      TileType openDoor})
      : _floor = floor,
        _wall = wall,
        _closedDoor = closedDoor,
        _openDoor = openDoor;

  TileType paintTile(Painter painter, Vec pos) {
    var tile = painter.getTile(pos);

    if (tile == Tiles.open || tile == Tiles.passage) return _floorTile();

    if (tile == Tiles.solid) {
      if (_wall != null) return rng.item(_wall);
      return rng.item(_defaultWalls);
    }

    if (tile == Tiles.doorway) {
      if (_closedDoor != null && _openDoor != null) {
        switch (rng.range(6)) {
          case 0:
            return _openDoor;
          case 1:
            return _floorTile();
          default:
            return _closedDoor;
        }
      } else if (_closedDoor != null) {
        return _closedDoor;
      } else if (_openDoor != null) {
        return _openDoor;
      } else {
        return _floorTile();
      }
    }

    if (_defaultTypes.containsKey(tile)) return rng.item(_defaultTypes[tile]);

    return tile;
  }

  TileType _floorTile() {
    if (_floor != null) return rng.item(_floor);

    return Tiles.flagstoneFloor;
  }
}
