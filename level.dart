/// An explorable level in the game.
class Level {
  int get width() => tiles.width;
  int get height() => tiles.height;
  final Array2D<Tile> tiles;

  Level(int width, int height)
  : tiles = new Array2D<Tile>(width, height, () => new Tile());

  // TODO(bob): Multi-argument subscript operators would be nice.
  Tile get(int x, int y) => tiles.get(x, y);
  void set(int x, int y, Tile tile) => tiles.set(x, y, value);
}

class TileType {
  static final FLOOR = 0;
  static final WALL  = 1;
}

class Tile {
  int type;

  Tile() : type = TileType.FLOOR;
}