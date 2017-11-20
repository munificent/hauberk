import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';

class LakeBiome extends Biome {
  final Array2D<bool> _blob;

  LakeBiome(this._blob);

  Iterable<String> generate(Dungeon dungeon) sync* {
    // TODO: Lakes sometimes have unreachable islands in the middle. Should
    // either fill those in, add bridges, give players a way to traverse water,
    // or at least ensure nothing is spawned on them.

    // Try to find a place to drop the lake.
    for (var i = 0; i < 100; i++) {
      var x = rng.range(0, dungeon.width - _blob.width);
      var y = rng.range(0, dungeon.height - _blob.height);

      // See if the lake overlaps anything.
      var canPlace = true;
      for (var pos in _blob.bounds) {
        if (_blob[pos]) {
          if (!dungeon.isRockAt(pos.offset(x, y))) {
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
          dungeon.setTileAt(pos.offset(x, y), Tiles.water);
          cells.add(pos);
        }
      }

      // Grow a shoreline.
      var edges = <Vec>[];
      var shoreBounds =
      Rect.intersect(_blob.bounds.offset(x, y), dungeon.safeBounds);
      for (var pos in shoreBounds) {
        if (dungeon.isRockAt(pos) && dungeon.hasNeighbor(pos, Tiles.water)) {
          dungeon.setTileAt(pos, Tiles.grass);
          edges.add(pos);

          cells.add(pos);
        }
      }

      dungeon.growSeed(edges, edges.length, 4, Tiles.grass, cells);
      dungeon.addPlace(new Place("aquatic", cells));
      return;
    }
  }
}
