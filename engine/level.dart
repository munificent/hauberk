/// An explorable level in the game.
class Level {
  int get width() => tiles.width;
  int get height() => tiles.height;
  Rect get bounds() => tiles.bounds;

  final Array2D<Tile> tiles;
  final Chain<Actor> actors;
  final List<Item> items;

  // Scent state is double-buffered in Tiles. This tracks which buffer is
  // current. Will be `true` if `scent1` is current.
  bool currentScent1;

  bool _visibilityDirty = true;

  Level(int width, int height)
  : tiles = new Array2D<Tile>(width, height, () => new Tile()),
    actors = new Chain<Actor>(),
    items = <Item>[];

  Game game;

  // TODO(bob): Multi-argument subscript operators would be nice.
  Tile operator[](Vec pos) => tiles[pos];

  Tile get(int x, int y) => tiles.get(x, y);
  void set(int x, int y, Tile tile) => tiles.set(x, y, tile);

  // TODO(bob): Move into Actor collection?
  Actor actorAt(Vec pos) {
    for (final actor in actors) {
      if (actor.pos == pos) return actor;
    }

    return null;
  }

  // TODO(bob): Move into Item collection?
  Item itemAt(Vec pos) {
    for (final item in items) {
      if (item.pos == pos) return item;
    }

    return null;
  }

  num getScent(int x, int y) {
    return currentScent1 ? tiles.get(x, y).scent1 : tiles.get(x, y).scent2;
  }

  void dirtyVisibility() {
    _visibilityDirty = true;
  }

  void refreshVisibility(Hero hero) {
    if (_visibilityDirty) {
      Fov.refresh(this, hero.pos);
      _visibilityDirty = false;
    }
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
        scent = scent / totalWeight * Option.SCENT_DECAY - Option.SCENT_SUBTRACT;

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

  // TODO(bob): This is hackish and may fail to terminate.
  Vec findOpenTile() {
    while (true) {
      final pos = rng.vecInRect(bounds);

      if (!this[pos].isPassable) continue;
      if (actorAt(pos) != null) continue;

      return pos;
    }
  }

  void spawnMonster(Breed breed, Vec pos) {
    final monsters = [];
    final count = rng.triangleInt(breed.numberInGroup, breed.numberInGroup ~/ 3);

    addMonster(Vec pos) {
      final monster = breed.spawn(game, pos);
      actors.add(monster);
      monsters.add(monster);
    }

    // Place the first monster.
    addMonster(pos);

    // If the monster appears in groups, place the rest of the groups.
    for (var i = 1; i < count; i++) {
      // Find every open tile that's neighboring a monster in the group.
      final open = [];
      for (final monster in monsters) {
        for (final dir in Direction.ALL) {
          final neighbor = monster.pos + dir;
          if (this[neighbor].isPassable && (actorAt(neighbor) == null)) {
            open.add(neighbor);
          }
        }
      }

      if (open.length == 0) {
        // We filled the entire reachable area with monsters, so give up.
        break;
      }

      addMonster(rng.item(open));
    }
  }

  void spawnItem(ItemType type, Vec pos) {
    // TODO(bob): Handle powers.
    final item = new Item(type, pos, null, null);
    items.add(item);
  }
}

class TileType {
  static final FLOOR       = const TileType(0);
  static final WALL        = const TileType(1);
  static final LOW_WALL    = const TileType(2);
  static final OPEN_DOOR   = const TileType(3);
  static final CLOSED_DOOR = const TileType(4);

  final int _value;
  const TileType(this._value);
}

class Tile {
  TileType type      = TileType.WALL;
  bool     _visible  = false;
  bool     _explored = false;
  num      scent1    = 0;
  num      scent2    = 0;

  Tile();

  bool get visible() => _visible;
  void set visible(bool value) {
    if (value) _explored = true;
    _visible = value;
  }

  bool get isExplored() => _explored;

  bool get isPassable() {
    return (type == TileType.FLOOR) ||
           (type == TileType.OPEN_DOOR);
  }

  bool get isTransparent() {
    return (type == TileType.FLOOR) ||
           (type == TileType.LOW_WALL) ||
           (type == TileType.OPEN_DOOR);
  }
}