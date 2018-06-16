import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';

class GrottoBiome extends Biome {
  final Dungeon _dungeon;
  final int _count;

  GrottoBiome(this._dungeon, this._count);

  Iterable<String> generate() sync* {
    var added = 0;
    for (var i = 0; i < 200; i++) {
      var pos = rng.vecInRect(_dungeon.safeBounds);
      // TODO: Handle different shore types.
      if (_dungeon.getTileAt(pos) == Tiles.grass &&
          _dungeon.hasCardinalNeighbor(pos, [Tiles.wall, Tiles.rock])) {
        yield "Carving grotto";
        // TODO: Different sizes and smoothness.
        _dungeon.growSeed([pos], 30, 3, Tiles.grass);
        if (++added == _count) break;
      }
    }
  }
}
