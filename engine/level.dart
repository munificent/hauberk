/// An explorable level in the game.
class Level {
  int get width() => tiles.width;
  int get height() => tiles.height;
  Vec get bounds() => tiles.bounds;

  final Array2D<Tile> tiles;
  final Chain<Actor> actors;

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
}

class TileType {
  static final FLOOR = 0;
  static final WALL  = 1;
}

class Tile {
  int  type    = TileType.WALL;
  bool _visible = false;
  bool _explored = false;

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