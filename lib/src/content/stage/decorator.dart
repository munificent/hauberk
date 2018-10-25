import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../decor/decor.dart';
import 'architect.dart';
import 'painter.dart';

class Decorator {
  final Architect _architect;

  Decorator(this._architect);

  Stage get _stage => _architect.stage;

  Iterable<String> decorate() sync* {
    _paintTiles();

    // TODO: Should this happen before or after painting?
    yield* _placeDecor();
  }

  /// Turn the temporary tiles into real tiles based on each architecutre's
  /// painters.
  void _paintTiles() {
    for (var pos in _architect.stage.bounds) {
      var tile = _stage[pos];
      var owner = _architect.ownerAt(pos);
      if (owner == null) {
        tile.type = Painter.base.paint(tile.type);
      } else {
        tile.type = owner.painter.paint(tile.type);
      }
    }
  }

  Iterable<String> _placeDecor() sync* {
    var tilesByOwner = <Architecture, List<Vec>>{};
    for (var pos in _stage.bounds) {
      var owner = _architect.ownerAt(pos);
      if (owner != null) {
        tilesByOwner.putIfAbsent(owner, () => []).add(pos);
      }
    }

    for (var entry in tilesByOwner.entries) {
      var architecture = entry.key;
      var tiles = entry.value;

      var painter = DecorPainter._(_architect, architecture);

      // TODO: Let architecture/theme control density.
      var decorTiles = rng.round(tiles.length * 0.1);
      decorTiles = rng.float(decorTiles * 0.8, decorTiles * 1.2).ceil();

      var tries = 0;
      while (tries++ < decorTiles && painter._painted < decorTiles) {
        var decor = Decor.choose(architecture.decorTheme);
        if (decor == null) continue;

        var allowed = <Vec>[];

        for (var tile in tiles) {
          if (decor.canPlace(painter, tile)) {
            allowed.add(tile);
          }
        }

        if (allowed.isNotEmpty) {
          decor.place(painter, rng.item(allowed));
          yield "Placed decor";
        }
      }
    }
  }
}

// TODO: Figure out how this interacts with Painter.
class DecorPainter {
  final Architect _architect;
  final Architecture _architecture;
  int _painted = 0;

  DecorPainter._(this._architect, this._architecture);

  Rect get bounds => _architect.stage.bounds;

  bool ownsTile(Vec pos) => _architect.ownerAt(pos) == _architecture;

  TileType getTile(Vec pos) {
    assert(ownsTile(pos));
    return _architect.stage[pos].type;
  }

  void setTile(Vec pos, TileType type) {
    assert(_architect.ownerAt(pos) == _architecture);
    _architect.stage[pos].type = type;
    _painted++;
  }
}
