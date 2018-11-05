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

  void spawnMonster(Vec pos, Breed breed) {
    _decorator.spawnMonster(pos, breed);
  }
}

/// Each style is a custom "look" that translates the semantic temporary
/// tiles into specific concrete tile types.
class PaintStyle {
  static final Map<String, PaintStyle> _all = {
    "rock": PaintStyle({}),
    "stone": _DoorPaintStyle(),
    "stone-jail": PaintStyle({
      Tiles.doorway: Tiles.closedBarredDoor
    }),
  };

  static Map<TileType, TileType> _defaultTypes = {
    Tiles.open: Tiles.floor,
    Tiles.solid: Tiles.rock,
    Tiles.passage: Tiles.floor,
    Tiles.doorway: Tiles.floor,
    Tiles.solidWet: Tiles.water,
    Tiles.passageWet: Tiles.bridge
  };

  static PaintStyle find(String name) => _all[name];

  final Map<TileType, TileType> _types;

  PaintStyle(this._types);

  TileType paintTile(Painter painter, Vec pos) {
    var tile = painter.getTile(pos);
    if (_types.containsKey(tile)) return _types[tile];

    if (_defaultTypes.containsKey(tile)) return _defaultTypes[tile];

    return tile;
  }
}

/// A paint style that turns doorways into doors.
class _DoorPaintStyle extends PaintStyle {
  _DoorPaintStyle() : super({Tiles.solid: Tiles.wall});

  TileType paintTile(Painter painter, Vec pos) {
    // TODO: Take depth into account. Locked doors, trapped, etc.
    if (painter.getTile(pos) == Tiles.doorway) {
      switch (rng.range(3)) {
        case 0:
          return Tiles.openDoor;
        case 1:
          return Tiles.closedDoor;
        case 2:
          return Tiles.floor;
      }
    }

    return super.paintTile(painter, pos);
  }
}
