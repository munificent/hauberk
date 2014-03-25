library dngn.engine.stage;

import 'dart:collection';

import '../util.dart';
import 'actor.dart';
import 'breed.dart';
import 'fov.dart';
import 'game.dart';
import 'hero.dart';
import 'item.dart';

/// The game's live play area.
class Stage {
  int get width => tiles.width;
  int get height => tiles.height;
  Rect get bounds => tiles.bounds;

  final Array2D<Tile> tiles;
  final Chain<Actor> actors;
  final List<Item> items;

  bool _visibilityDirty = true;

  /// For each tile, contains the number of steps between this tile and the
  /// hero.
  Array2D<int> _distances;

  /// The position where the [Hero] was the last time [_distances] was
  /// calculated.
  Vec _distancesHeroPos;

  Stage(int width, int height)
  : tiles = new Array2D<Tile>(width, height, () => new Tile()),
    actors = new Chain<Actor>(),
    items = <Item>[];

  Game game;

  Tile operator[](Vec pos) => tiles[pos];

  Tile get(int x, int y) => tiles.get(x, y);
  void set(int x, int y, Tile tile) => tiles.set(x, y, tile);

  // TODO: Move into Actor collection?
  Actor actorAt(Vec pos) {
    for (final actor in actors) {
      if (actor.pos == pos) return actor;
    }

    return null;
  }

  // TODO: Move into Item collection?
  // TODO: What if there are multiple items at pos?
  Item itemAt(Vec pos) {
    for (final item in items) {
      if (item.pos == pos) return item;
    }

    return null;
  }

  /// Gets the [Item]s at [pos].
  List<Item> itemsAt(Vec pos) =>
      items.where((item) => item.pos == pos).toList();

  /// Removes [item] from the stage. Does nothing if the item is not on the
  /// ground.
  void removeItem(Item item) {
    for (var i = 0; i < items.length; i++) {
      if (items[i] == item) {
        items.removeAt(i);
        return;
      }
    }

    assert(false); // Unreachable.
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

  // TODO: This is hackish and may fail to terminate.
  /// Selects a random passable tile that does not have an [Actor] on it.
  Vec findOpenTile() {
    while (true) {
      var pos = rng.vecInRect(bounds);

      if (!this[pos].isPassable) continue;
      if (actorAt(pos) != null) continue;

      return pos;
    }
  }

  /// Gets the number of tiles to walk from [pos] to the [Hero]'s current
  /// position taking into account which tiles are traversable.
  int getHeroDistanceTo(Vec pos) {
    _refreshDistances();
    return _distances[pos];
  }

  /// Randomly selects an open tile in the stage. Makes [tries] attempts and
  /// chooses the one most distance from some point. Assumes that [scent2] has
  /// been filled with the distance information for the target point.
  ///
  /// This is used during level creation to place stronger [Monster]s and
  /// better treasure farther from the [Hero]'s starting location.
  Vec findDistantOpenTile(int tries) {
    _refreshDistances();

    var bestDistance = -1;
    var best;

    for (var i = 0; i < tries; i++) {
      var pos = findOpenTile();
      if (this[pos].scent2 > bestDistance) {
        best = pos;
        bestDistance = this[pos].scent2;
      }
    }

    return best;
  }

  void spawnMonster(Breed breed, Vec pos) {
    final monsters = [];
    final count = rng.triangleInt(breed.numberInGroup, breed.numberInGroup ~/ 2);

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

  /// Run Dijkstra's algorithm to calculate the distance from every reachable
  /// tile to[start]. We will use this to place better and stronger things
  /// farther from the Hero. Re-uses the scent data as a convenient buffer for
  /// this.
  void _refreshDistances() {
    // Don't recalculate if still valid.
    if (game.hero.pos == _distancesHeroPos) return;

    // Clear it out.
    _distances = new Array2D<int>(width, height, () => 9999);
    _distancesHeroPos = game.hero.pos;
    _distances[_distancesHeroPos] = 0;

    var open = new Queue<Vec>();
    open.add(_distancesHeroPos);

    while (open.length > 0) {
      var start = open.removeFirst();
      var distance = _distances[start];

      // Update the neighbor's distances.
      for (var dir in Direction.ALL) {
        var here = start + dir;

        // Can't reach impassable tiles.
        if (!this[here].isTraversable) continue;

        // If we got a new best path to this tile, update its distance and
        // consider its neighbors later.
        if (_distances[here] > distance + 1) {
          _distances[here] = distance + 1;
          open.add(here);
        }
      }
    }
  }
}

class TileType {
  final String name;
  final bool isPassable;
  final bool isTransparent;
  final appearance;
  TileType opensTo;
  TileType closesTo;

  TileType(this.name, this.isPassable, this.isTransparent, this.appearance);
}

class Tile {
  TileType type;
  bool     _visible  = false;
  bool     _explored = false;
  num      scent1    = 0;
  num      scent2    = 0;

  Tile();

  bool get visible => _visible;
  void set visible(bool value) {
    if (value) _explored = true;
    _visible = value;
  }

  bool get isExplored => _explored;
  bool get isPassable => type.isPassable;
  bool get isTraversable => type.isPassable || (type.opensTo != null);
  bool get isTransparent => type.isTransparent;
}