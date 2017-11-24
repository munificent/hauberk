import 'package:piecemeal/piecemeal.dart';

import '../hero/hero.dart';
import '../items/inventory.dart';
import '../items/item.dart';
import '../monster/monster.dart';
import 'actor.dart';
import 'flow.dart';
import 'fov.dart';
import 'game.dart';

/// The game's live play area.
class Stage {
  final Game game;

  final _actors = <Actor>[];
  final Fov _fov;
  int _currentActorIndex = 0;

  /// The total number of tiles the [Hero] can explore in the stage.
  int get numExplorable => _numExplorable;
  int _numExplorable;

  int get width => tiles.width;
  int get height => tiles.height;
  Rect get bounds => tiles.bounds;

  Iterable<Actor> get actors => _actors;

  Actor get currentActor => _actors[_currentActorIndex];

  final Array2D<Tile> tiles;

  final _itemsByTile = <Vec, Inventory>{};

  /// A spatial partition to let us quickly locate an actor by tile.
  ///
  /// This is a performance bottleneck since pathfinding needs to ensure it
  /// doesn't step on other actors.
  final Array2D<Actor> _actorsByTile;

  bool _visibilityDirty = true;

  /// Tracks global pathfinding distances to the hero, ignoring other actors.
  Flow _heroPaths;

  Stage(int width, int height, Game game)
      : game = game,
        tiles = new Array2D<Tile>.generated(width, height, () => new Tile()),
        _actorsByTile = new Array2D<Actor>(width, height),
        _fov = new Fov(game);

  Tile operator [](Vec pos) => tiles[pos];

  /// Iterates over every item on the ground on the stage.
  Iterable<Item> get allItems sync* {
    for (var inventory in _itemsByTile.values) {
      yield* inventory;
    }
  }

  Tile get(int x, int y) => tiles.get(x, y);
  void set(int x, int y, Tile tile) => tiles.set(x, y, tile);

  /// Called after the level generator has finished laying out the stage.
  void finishBuild() {
    // Count the explorable tiles. We assume the level is fully reachable, so
    // any traversable tile or tile next to a traversable one is explorable.
    _numExplorable = 0;
    for (var pos in bounds.inflate(-1)) {
      var tile = this[pos];
      if (tile.isTraversable) {
        _numExplorable++;
      } else {
        // See if it's next to an traversable one.
        for (var dir in Direction.all) {
          if (this[pos + dir].isTraversable) {
            _numExplorable++;
            break;
          }
        }
      }
    }

    _fov.refresh(game.hero.pos);
  }

  void addActor(Actor actor) {
    assert(_actorsByTile[actor.pos] == null);

    _actors.add(actor);
    _actorsByTile[actor.pos] = actor;
  }

  /// Called when an [Actor]'s position has changed so the stage can track it.
  void moveActor(Vec from, Vec to) {
    var actor = _actorsByTile[from];
    _actorsByTile[from] = null;
    _actorsByTile[to] = actor;
  }

  void removeActor(Actor actor) {
    assert(_actorsByTile[actor.pos] == actor);

    var index = _actors.indexOf(actor);
    if (_currentActorIndex > index) _currentActorIndex--;
    _actors.removeAt(index);

    if (_currentActorIndex >= _actors.length) _currentActorIndex = 0;

    _actorsByTile[actor.pos] = null;
  }

  void advanceActor() {
    _currentActorIndex = (_currentActorIndex + 1) % _actors.length;
  }

  Actor actorAt(Vec pos) => _actorsByTile[pos];

  List<Item> placeDrops(Vec pos, MotilitySet motilities, Drop drop) {
    var items = <Item>[];

    // TODO: Is using the breed's motility correct? We probably don't want
    // drops going through doors.
    // Try to keep dropped items from overlapping.
    var flow = new Flow(this, pos, motilities, ignoreActors: true);

    drop.spawnDrop((item) {
      items.add(item);
      var itemPos = pos;
      if (isItemAt(pos)) {
        itemPos = flow.nearestWhere((pos) {
          if (rng.oneIn(5)) return true;
          return !isItemAt(pos);
        });

        if (itemPos == null) itemPos = pos;
      }

      addItem(item, itemPos);
    });

    return items;
  }

  void addItem(Item item, Vec pos) {
    // Get the inventory for the tile.
    var inventory = _itemsByTile.putIfAbsent(pos, () => new Inventory(null));
    var result = inventory.tryAdd(item);
    // Inventory is unlimited, so should always succeed.
    assert(result.remaining == 0);
  }

  /// Returns `true` if there is at least one item at [pos].
  bool isItemAt(Vec pos) => _itemsByTile.containsKey(pos);

  /// Gets the [Item]s at [pos].
  Iterable<Item> itemsAt(Vec pos) {
    var inventory = _itemsByTile[pos];
    if (inventory == null) return const [];
    return inventory;
  }

  /// Removes [item] from the stage at [pos].
  ///
  /// It is an error to call this if [item] is not on the ground at [pos].
  void removeItem(Item item, Vec pos) {
    var inventory = _itemsByTile[pos];
    assert(inventory != null);

    inventory.remove(item);

    // Discard empty inventories. Note that [isItemAt] assumes this is done.
    if (inventory.isEmpty) _itemsByTile.remove(pos);
  }

  /// Iterates over every item on the stage and returns the item and its
  /// position.
  void forEachItem(callback(Item item, Vec pos)) {
    _itemsByTile.forEach((pos, inventory) {
      for (var item in inventory) {
        callback(item, pos);
      }
    });
  }

  void dirtyVisibility() {
    _visibilityDirty = true;
  }

  void refreshVisibility(Hero hero) {
    if (_visibilityDirty) {
      _fov.refresh(hero.pos);
      _visibilityDirty = false;
    }
  }

  // TODO: This is hackish and may fail to terminate.
  // TODO: Consider flyable tiles for flying monsters.
  /// Selects a random passable tile that does not have an [Actor] on it.
  Vec findOpenTile() {
    while (true) {
      var pos = rng.vecInRect(bounds);

      if (!this[pos].isWalkable) continue;
      if (actorAt(pos) != null) continue;

      return pos;
    }
  }

  /// Gets the number of tiles to walk from [pos] to the [Hero]'s current
  /// position taking into account which tiles are traversable.
  int getHeroDistanceTo(Vec pos) {
    _refreshDistances();
    return _heroPaths.getDistance(pos);
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
      var distance = _heroPaths.getDistance(pos);
      if (distance > bestDistance) {
        best = pos;
        bestDistance = distance;
      }
    }

    return best;
  }

  /// Lazily calculates the paths from every reachable tile to the [Hero]. We
  /// use this to place better and stronger things farther from the Hero. Sound
  /// propagation is also based on this.
  void _refreshDistances() {
    // Don't recalculate if still valid.
    if (_heroPaths != null && game.hero.pos == _heroPaths.start) return;

    // TODO: Is this the right motility set?
    _heroPaths = new Flow(this, game.hero.pos,
        new MotilitySet([Motility.walk, Motility.fly, Motility.door]),
        ignoreActors: true);
  }
}

/// Enum-like class defining ways that monsters can move over tiles.
///
/// Each [TileType] has a set of motilities that determine which kind of
/// movement is needed to enter the tile. Monsters and the hero have a set of
/// motilities that determine which ways they are able to move. In order to
/// move into a tile, the actor must have one of the tile's motilities.
class Motility {
  // TODO: Should these be in content, engine, or a mixture of both?
  static final Motility door = new Motility("door");
  static final Motility fly = new Motility("fly");
  static final Motility swim = new Motility("swim");
  static final Motility walk = new Motility("walk");

  /// Each motility object has a bit value that is used by MotilitySet to store
  /// a set of motilities efficiently.
  static int _nextBit = 1;

  final String name;
  final int _bit = _nextBit;

  Motility(this.name) {
    _nextBit <<= 1;
  }
}

class MotilitySet {
  static final walk = new MotilitySet([Motility.walk]);
  static final walkAndDoor = new MotilitySet([Motility.walk, Motility.door]);
  static final walkAndFly = new MotilitySet([Motility.walk, Motility.fly]);

  int _bitMask = 0;

  MotilitySet([Iterable<Motility> iterable]) {
    if (iterable != null) {
      for (var motility in iterable) {
        add(motility);
      }
    }
  }

  void add(Motility motility) {
    _bitMask = _bitMask | motility._bit;
  }

  void addAll(Iterable<Motility> motilities) {
    motilities.forEach(add);
  }

  bool contains(Motility motility) => _bitMask & motility._bit != 0;

  bool overlaps(MotilitySet other) => _bitMask & other._bitMask != 0;
}

class TileType {
  final String name;
  final bool isExit;
  final appearance;
  TileType opensTo;
  TileType closesTo;

  final MotilitySet motilities;

  bool get isTraversable => canEnter(Motility.walk) || (opensTo != null);
  bool get isWalkable => canEnter(Motility.walk);

  TileType(this.name, this.appearance, Iterable<Motility> motilities,
      {this.isExit})
      : motilities = new MotilitySet(motilities);

  bool canEnter(Motility motility) => this.motilities.contains(motility);
  bool canEnterAny(MotilitySet motilities) =>
      this.motilities.overlaps(motilities);
}

class Tile {
  TileType type;
  bool _visible = false;

  Tile();

  bool get visible => _visible;
  void set visible(bool value) {
    if (value) isExplored = true;
    _visible = value;
  }

  /// Sets the visibility of this tile to [visible].
  ///
  /// Returns `true` if this is the first time the tile has been made visible.
  bool setVisible(bool visible) {
    _visible = visible;

    if (visible && !isExplored) {
      isExplored = true;
      return true;
    }

    return false;
  }

  bool isExplored = false;
  bool get isWalkable => type.isWalkable;
  bool get isTraversable => type.isTraversable;
  bool get isFlyable => canEnter(Motility.fly);
  bool get isExit => type.isExit;

  bool canEnter(Motility motility) => type.canEnter(motility);
  bool canEnterAny(MotilitySet motilities) => type.canEnterAny(motilities);
}
