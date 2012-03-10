/// An explorable level in the game.
class Level {
  int get width() => tiles.width;
  int get height() => tiles.height;
  Vec get bounds() => tiles.bounds;

  final Array2D<Tile> tiles;
  final Chain<Actor> actors;

  // Scent state is double-buffered in Tiles. This tracks which buffer is
  // current. Will be `true` if `scent1` is current.
  bool currentScent1;

  /// The number of pathfinding steps that have been calculated so far. Gets
  /// reset anytime something that affects pathfinding changes (i.e. whenever
  /// the hero moves since that paths are to him, or when an actor moves since
  /// actors can block others).
  int _knownPath = -1;

  Level(int width, int height)
  : tiles = new Array2D<Tile>(width, height, () => new Tile()),
    actors = new Chain<Actor>()
  {
    final creep = new FeatureCreep();
    creep.create(this, new FeatureCreepOptions());
  }

  Game game;

  // TODO(bob): Multi-argument subscript operators would be nice.
  Tile operator[](Vec pos) => tiles[pos];

  Tile get(int x, int y) => tiles.get(x, y);
  void set(int x, int y, Tile tile) => tiles.set(x, y, value);

  Actor actorAt(Vec pos) {
    for (final actor in actors) {
      if (actor.pos == pos) return actor;
    }

    return null;
  }

  num getScent(int x, int y) {
    return currentScent1 ? tiles.get(x, y).scent1 : tiles.get(x, y).scent2;
  }

  void dirtyPathfinding() {
    _knownPath = -1;

    // Clear the pathfinding data.
    for (final tile in tiles) tile.path = -1;
  }

  int getPath(int x, int y) {
    int path = tiles.get(x, y).path;

    // Known path.
    if (path != -1) return path;

    // If a straight line to the hero is too far, then there can be no path,
    // so don't even try.
    if ((game.hero.pos - new Vec(x, y)).kingLength > Option.MAX_PATH) {
      return path;
    }

    // We don't know a path yet, so try to find it.

    if (_knownPath == -1) {
      // No path data is known, so start with the hero.
      tiles[game.hero.pos].path = 0;
      _knownPath = 0;
    }

    // Walk outwards from the hero until we find a path to this tile, or until
    // we give up. This is basically Dijkstra's algorithm.
    // TODO(bob): This is an inefficient way to do Dijkstra's. Since we don't
    // keep track of the set of open nodes (i.e. tiles that are at the edge of
    // the known paths) we end up walking over all tiles repeatedly. Could
    // optimize.
    bool found = false;

    while (_knownPath < Option.MAX_PATH) {
      for (var scanY = 1; scanY < height - 1; scanY++) {
        for (var scanX = 1; scanX < width - 1; scanX++) {
          final tile = tiles.get(scanX, scanY);

          // Can't pathfind through walls.
          if (!tile.isPassable) continue;

          // Don't do anything if we've already solved this tile.
          if (tile.path != -1) continue;

          // Find the best path distance to one of this tile's neighbors.
          int best = Option.MAX_PATH + 1;
          int testNeighbor(int h, int v) {
            final path = tiles.get(scanX + h, scanY + v).path;
            if ((path != -1) && (path < best)) best = path;
          }

          testNeighbor(-1, -1);
          testNeighbor( 0, -1);
          testNeighbor( 1, -1);
          testNeighbor(-1,  0);
          testNeighbor( 1,  0);
          testNeighbor(-1,  1);
          testNeighbor( 0,  1);
          testNeighbor( 1,  1);

          // If we have a path to a neighbor, then a path to this tile is just
          // one more step.
          if (best <= Option.MAX_PATH) {
            tile.path = best + 1;
            if ((x == scanX) && (y == scanY)) found = true;
          }
        }
      }

      _knownPath++;

      // See if we've found a path to our goal yet.
      if (found) break;
    }

    return tiles.get(x, y).path;
  }

  void updateScent(Hero hero) {
    // The hero stinks!
    if (currentScent1) {
      tiles[hero.pos].scent1 += Option.SCENT_HERO;
    } else {
      tiles[hero.pos].scent2 += Option.SCENT_HERO;
    }

    for (var y = 1; y < tiles.height - 1; y++) {
      for (var x = 1; x < tiles.width - 1; x++) {
        // Scent doesn't flow through walls.
        if (!tiles.get(x, y).isPassable) continue;

        var scent = 0;
        var totalWeight = 0;
        num addScent(int x, int y, num weight) {
          if (!tiles.get(x, y).isPassable) return;
          scent += getScent(x, y) * weight;
          totalWeight += weight;
        }

        addScent(x - 1, y - 1, Option.SCENT_CORNER_CONVOLVE);
        addScent(x    , y - 1, Option.SCENT_SIDE_CONVOLVE);
        addScent(x + 1, y - 1, Option.SCENT_CORNER_CONVOLVE);
        addScent(x - 1, y,     Option.SCENT_SIDE_CONVOLVE);
        addScent(x    , y,     1.0);
        addScent(x + 1, y,     Option.SCENT_SIDE_CONVOLVE);
        addScent(x - 1, y + 1, Option.SCENT_CORNER_CONVOLVE);
        addScent(x    , y + 1, Option.SCENT_SIDE_CONVOLVE);
        addScent(x + 1, y + 1, Option.SCENT_CORNER_CONVOLVE);

        // Weight it with a slight negative bias so that scent fades.
        scent = (scent * Option.SCENT_DECAY) / totalWeight;

        // Clamp it within [0,1].
        scent = clamp(0, scent, 1);

        // Write it to the other buffer.
        if (currentScent1) {
          tiles.get(x, y).scent2 = scent;
        } else {
          tiles.get(x, y).scent1 = scent;
        }
      }
    }

    // Flip the buffers.
    currentScent1 = !currentScent1;
  }

}

class TileType {
  static final FLOOR = 0;
  static final WALL  = 1;
}

class Tile {
  int  type    = TileType.WALL;
  bool _visible = false;
  bool _explored = false;
  num scent1 = 0;
  num scent2 = 0;

  /// The number of steps from this tile to the hero following the best possible
  /// path. Will be `-1` if the path isn't known (or if it's too far to
  /// calculate).
  int path = -1;

  Tile();

  bool get visible() => _visible;
  void set visible(bool value) {
    if (value) _explored = true;
    _visible = value;
  }

  bool get explored() => _explored;

  bool get isPassable() => type == TileType.FLOOR;
  bool get isTransparent() => type == TileType.FLOOR;
}