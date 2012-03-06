/// An explorable level in the game.
class Level {
  int get width() => tiles.width;
  int get height() => tiles.height;
  final Array2D<Tile> tiles;
  final Chain<Actor> actors;

  Level(int width, int height)
  : tiles = new Array2D<Tile>(width, height, () => new Tile()),
    actors = new Chain<Actor>()
  {
    final maze = new Maze(39, 19);
    maze.generate();
    maze.draw(this);
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
  int type;

  Tile() : type = TileType.WALL;
}