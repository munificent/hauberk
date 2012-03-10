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

  Level(int width, int height)
  : tiles = new Array2D<Tile>(width, height, () => new Tile()),
    actors = new Chain<Actor>()
  {
    final creep = new FeatureCreep();
    creep.create(this, new FeatureCreepOptions());
  }

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
        scent = Math.min(Math.max(0, scent), 1.0);

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