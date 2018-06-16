import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';

class LakeBiome extends Biome {
  final Dungeon _dungeon;
  final Array2D<bool> _blob;

  LakeBiome(this._dungeon, this._blob);

  Iterable<String> generate() sync* {
    // TODO: Lakes sometimes have unreachable islands in the middle. Should
    // either fill those in, add bridges, give players a way to traverse water,
    // or at least ensure nothing is spawned on them.

    // Try to find a place to drop the lake.
    for (var i = 0; i < 100; i++) {
      var x = rng.range(0, _dungeon.width - _blob.width);
      var y = rng.range(0, _dungeon.height - _blob.height);

      // See if the lake overlaps anything.
      var canPlace = true;
      for (var pos in _blob.bounds) {
        if (_blob[pos]) {
          if (!_dungeon.isRockAt(pos.offset(x, y))) {
            canPlace = false;
            break;
          }
        }
      }

      if (!canPlace) continue;

      // We found a spot, carve the water.
      var cells = <Vec>[];
      for (var pos in _blob.bounds) {
        if (_blob[pos]) {
          var absolute = pos.offset(x, y);
          _dungeon.setTileAt(absolute, Tiles.water);
          cells.add(absolute);
        }
      }

      // Grow a shoreline.
      var edges = <Vec>[];
      var shoreBounds =
          Rect.intersect(_blob.bounds.offset(x, y), _dungeon.safeBounds);
      for (var pos in shoreBounds) {
        if (_dungeon.isRockAt(pos) && _dungeon.hasNeighbor(pos, Tiles.water)) {
          _dungeon.setTileAt(pos, Tiles.grass);
          edges.add(pos);

          cells.add(pos);
        }
      }

      _dungeon.growSeed(edges, edges.length, 4, Tiles.grass, cells);
      _dungeon.addPlace(new Place("aquatic", cells));
      return;
    }
  }
}
