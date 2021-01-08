import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';
import 'blob.dart';
import 'painter.dart';

/// Places a single blob filled with monsters.
class Pit extends Architecture {
  final String _monsterGroup;

  /// The minimum chamber size.
  final int _minSize;

  /// The maximum chamber size.
  final int _maxSize;

  final List<Vec> _monsterTiles = [];

  PaintStyle get paintStyle => PaintStyle.stoneJail;

  Pit(this._monsterGroup, {int minSize, int maxSize})
      : _minSize = minSize ?? 12,
        _maxSize = maxSize ?? 24;

  Iterable<String> build() sync* {
    for (var i = 0; i < 20; i++) {
      var size = rng.range(_minSize, _maxSize);
      var cave = Blob.make(size);

      var bounds = _tryPlaceCave(cave, this.bounds);
      if (bounds != null) {
        yield "pit";

        for (var pos in cave.bounds) {
          if (cave[pos]) {
            _monsterTiles.add(pos + bounds.topLeft);
          }
        }

        yield* _placeAntechambers(bounds);
        return;
      }
    }
  }

  bool spawnMonsters(Painter painter) {
    // Boost the depth some.
    var depth = (painter.depth * rng.float(1.0, 1.4)).ceil();

    for (var pos in _monsterTiles) {
      if (!painter.getTile(pos).isWalkable) continue;

      // Leave a ring of open tiles around the edge of the pit.
      var openNeighbors = true;
      for (var neighbor in pos.neighbors) {
        if (!painter.getTile(neighbor).isWalkable) {
          openNeighbors = false;
          break;
        }
      }
      if (!openNeighbors) continue;

      if (painter.hasActor(pos)) continue;

      var breed = painter.chooseBreed(depth,
          tag: _monsterGroup, includeParentTags: false);
      painter.spawnMonster(pos, breed);
    }

    return true;
  }

  Rect _tryPlaceCave(Array2D<bool> cave, Rect bounds) {
    if (bounds.width < cave.width) return null;
    if (bounds.height < cave.height) return null;

    for (var j = 0; j < 200; j++) {
      var x = rng.range(bounds.left, bounds.right - cave.width);
      var y = rng.range(bounds.top, bounds.bottom - cave.height);

      if (_tryPlaceCaveAt(cave, x, y)) {
        return Rect(x, y, cave.width, cave.height);
      }
    }

    return null;
  }

  // TODO: Copied from Cavern.
  bool _tryPlaceCaveAt(Array2D<bool> cave, int x, int y) {
    for (var pos in cave.bounds) {
      if (cave[pos]) {
        if (!canCarve(pos.offset(x, y))) return false;
      }
    }

    for (var pos in cave.bounds) {
      if (cave[pos]) carve(pos.x + x, pos.y + y);
    }

    return true;
  }

  /// Try to place a few small caves around the main pit. This gives some
  /// foreshadowing that the hero is about to enter a pit.
  Iterable<String> _placeAntechambers(Rect pitBounds) sync* {
    for (var i = 0; i < 8; i++) {
      var size = rng.range(6, 10);
      var cave = Blob.make(size);

      var allowed = Rect.leftTopRightBottom(
          pitBounds.left - cave.width,
          pitBounds.top - cave.height,
          pitBounds.right + cave.width,
          pitBounds.bottom + cave.height);
      allowed = Rect.intersect(allowed, bounds.inflate(-1));

      if (_tryPlaceCave(cave, allowed) != null) yield "antechamber";
    }
  }
}
