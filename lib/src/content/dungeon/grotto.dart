import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';

class GrottoBiome extends Biome {
  final int _count;

  GrottoBiome(this._count);

  Iterable<String> generate(Dungeon dungeon) sync* {
    var added = 0;
    for (var i = 0; i < 200; i++) {
      var pos = rng.vecInRect(dungeon.safeBounds);
      // TODO: Handle different shore types.
      if (dungeon.getTileAt(pos) == Tiles.grass &&
          dungeon.hasCardinalNeighbor(pos, [Tiles.wall, Tiles.rock])) {
        yield "Carving grotto";
        // TODO: Different sizes and smoothness.
        dungeon.growSeed([pos], 30, 3, Tiles.grass);
        if (++added == _count) break;
      }
    }
  }
}
