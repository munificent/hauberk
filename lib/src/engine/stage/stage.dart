import 'package:piecemeal/piecemeal.dart';

import '../core/actor.dart';
import '../core/game.dart';
import '../hero/hero.dart';
import '../items/inventory.dart';
import '../items/item.dart';
import '../items/item_type.dart';
import '../monster/monster.dart';
import 'flow.dart';
import 'lighting.dart';
import 'sound.dart';
import 'tile.dart';

/// The game's live play area.
class Stage {
  final Game game;

  final _actors = <Actor>[];
  Lighting _lighting;
  Sound _sound;

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

  Stage(int width, int height, Game game)
      : game = game,
        tiles = new Array2D<Tile>.generated(width, height, () => new Tile()),
        _actorsByTile = new Array2D<Actor>(width, height) {
    _lighting = new Lighting(this);
    _sound = new Sound(this);
  }

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

    refreshView();
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
    var flow = new MotilityFlow(this, pos, motilities, ignoreActors: true);

    drop.spawnDrop((item) {
      items.add(item);
      var itemPos = pos;
      if (isItemAt(pos)) {
        itemPos = flow.bestWhere((pos) {
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

    // If a light source is dropped, we need to light the floor.
    if (item.emanationLevel > 0) floorEmanationChanged();
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

    // If a light source is picked up, we need to unlight the floor.
    if (item.emanationLevel > 0) floorEmanationChanged();

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

  /// Marks the illumination and field-of-view as needing recalculation.
  void tileOpacityChanged() {
    _lighting.dirtyFloorLight();
    _lighting.dirtyActorLight();
    _lighting.dirtyVisibility();
    _sound.dirty();
  }

  /// Marks the floor illumination as needing recalculation.
  ///
  /// This should be called when a tile's emanation changes, or a
  /// light-emitting item is dropped or picked up.
  void floorEmanationChanged() {
    _lighting.dirtyFloorLight();
  }

  /// Marks the actor illumination as needed recalculation.
  ///
  /// This should be called whenever an actor that emanates light moves or
  /// when its emanation changes (for example, the [Hero] equipping a light
  /// source).
  void actorEmanationChanged() {
    _lighting.dirtyActorLight();
  }

  /// Marks the visibility as needing recalculation.
  ///
  /// This should be called whenever the [Hero] moves or their sight changes.
  void heroVisibilityChanged() {
    _lighting.dirtyVisibility();
  }

  /// Marks this tile at [pos] as explored if the hero can see it and hasn't
  /// previously explored it.
  ///
  /// Returns 1 if this tile was explored just now or 0 otherwise.
  int exploreAt(int x, int y, {bool force}) {
    var tile = tiles.get(x, y);
    // make return bool, remove calls to this
    if (tile.updateExplored(force: force)) {
      if (tile.isVisible) {
        var actor = actorAt(new Vec(x, y));
        if (actor != null && actor is Monster) game.hero.seeMonster(actor);
      }
      return 1;
    }

    return 0;
  }

  int explore(Vec pos, {bool force}) => exploreAt(pos.x, pos.y, force: force);

  void setOcclusion(Vec pos, bool isOccluded) {
    tiles[pos].updateOcclusion(isOccluded);
    if (!isOccluded) {
      var actor = actorAt(pos);
      if (actor != null && actor is Monster) game.hero.seeMonster(actor);
    }
  }

  /// Recalculates any lighting or visibility state that needs it.
  void refreshView() {
    _lighting.refresh();
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

  /// How far away the [Hero] is from [pos] in terms of sound flow, up to
  /// [Sound.maxDistance].
  ///
  /// Returns the auditory equivalent of the number of open tiles away the hero
  /// is. (It may be fewer actual tiles if there are sound-deadening obstacles
  /// in the way like doors or walls.
  int heroAuditoryDistance(Vec pos) => _sound.heroAuditoryDistance(pos);
}
