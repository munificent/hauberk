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
        tiles = Array2D.generated(width, height, () => Tile()),
        _actorsByTile = Array2D(width, height) {
    _lighting = Lighting(this);
    _sound = Sound(this);
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

  List<Item> placeDrops(Vec pos, Motility motility, Drop drop) {
    var items = <Item>[];

    // Try to keep dropped items from overlapping.
    var flow = MotilityFlow(this, pos, motility, avoidActors: false);

    drop.spawnDrop((item) {
      items.add(item);

      // Prefer to not place under monsters or stack with other items.
      var itemPos = flow.bestWhere((pos) {
        // Some chance to place on occupied tiles.
        if (rng.oneIn(5)) return true;

        return actorAt(pos) == null && !isItemAt(pos);
      });

      // If that doesn't work, pick any nearby tile.
      if (itemPos == null) {
        var allowed = flow.reachable.take(10).toList();
        if (allowed.isNotEmpty) {
          itemPos = rng.item(allowed);
        } else {
          // Nowhere to place it.
          // TODO: If the starting position doesn't allow the motility (as in
          // when opening a barrel), this does the wrong thing. What should we
          // do then?
          itemPos = pos;
        }
      }

      addItem(item, itemPos);
    });

    return items;
  }

  void addItem(Item item, Vec pos) {
    // Get the inventory for the tile.
    var inventory =
        _itemsByTile.putIfAbsent(pos, () => Inventory(ItemLocation.onGround));
    var result = inventory.tryAdd(item);
    // Inventory is unlimited, so should always succeed.
    assert(result.remaining == 0);

    // If a light source is dropped, we need to light the floor.
    if (item.emanationLevel > 0) floorEmanationChanged();
  }

  /// Returns `true` if there is at least one item at [pos].
  bool isItemAt(Vec pos) => _itemsByTile.containsKey(pos);

  /// Gets the [Item]s at [pos].
  Inventory itemsAt(Vec pos) =>
      _itemsByTile[pos] ?? Inventory(ItemLocation.onGround);
  // TODO: This is kind of slow, probably from creating the inventory each time.
  // Use a const one for the empty case?

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
  void exploreAt(int x, int y, {bool force}) {
    var tile = tiles.get(x, y);
    if (tile.updateExplored(force: force)) {
      if (tile.isVisible) {
        var actor = actorAt(Vec(x, y));
        if (actor != null && actor is Monster) {
          game.hero.seeMonster(actor);
        }
      }
    }
  }

  void explore(Vec pos, {bool force}) {
    exploreAt(pos.x, pos.y, force: force);
  }

  void setVisibility(Vec pos, bool isOccluded, int fallOff) {
    var tile = tiles[pos];
    tile.updateVisibility(isOccluded, fallOff);
    if (tile.isVisible) {
      var actor = actorAt(pos);
      if (actor != null && actor is Monster) {
        game.hero.seeMonster(actor);
      }
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

  /// How loud the hero is from [pos] in terms of sound flow, up to
  /// [Sound.maxDistance].
  double heroVolume(Vec pos) => _sound.heroVolume(pos);

  double volumeBetween(Vec from, Vec to) => _sound.volumeBetween(from, to);
}
