import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../debug.dart';
import '../../engine.dart';
import '../decor/decor.dart';
import '../item/floor_drops.dart';
import '../monster/monsters.dart';
import '../tiles.dart';
import 'architect.dart';
import 'painter.dart';

class Decorator {
  final Architect _architect;
  Vec _heroPos;

  /// The tiles organized by which architect owns them.
  ///
  /// Includes a null key for the tiles with no owner.
  final Map<Architecture, List<Vec>> _tilesByArchitecture = {};

  /// The unique breeds that have already been placed on the stage. Ensures we
  /// don't spawn the same unique more than once.
  var _spawnedUniques = <Breed>{};

  Decorator(this._architect);

  Vec get heroPos => _heroPos;

  Stage get _stage => _architect.stage;

  /// Gets the list of tiles owned by [architecture].
  List<Vec> tilesFor(Architecture architecture) =>
      _tilesByArchitecture[architecture];

  Iterable<String> decorate() sync* {
    _findDoorways();

    for (var pos in _stage.bounds) {
      var owner = _architect.ownerAt(pos);
      _tilesByArchitecture.putIfAbsent(owner, () => []).add(pos);
    }

    // TODO: Consider calculating the "humidity" of each tile by flowing
    // outward from wet tiles. Then use that to place puddles, smoke, ice, or
    // other things that hint at the liquid in the level.

    _paintTiles();

    // TODO: Should this happen before or after painting?
    yield* _placeDecor();

    // Place stairs.
    // TODO: Choose more interesting places for them.
    var stairCount = rng.range(2, 4);
    for (var i = 0; i < stairCount; i++) {
      var pos = _stage.findOpenTile();
      _stage[pos].type = Tiles.stairs;
    }

    // TODO: Instead of bleeding themes around, here's a simpler idea:
    // 1. Choose a random place to spawn a monster/item.
    // 2. Do a random walk from there to a result tile.
    // 3. Use the result tile's architecture/style/whatever to generate the
    //    monster/item.
    // 4. Place it in the original random location.
    // This way, you can get nearby styles and foreshadowing without a lot of
    // complex calculation.

    // TODO: Do something smarter. In particular, we shouldn't spawn the hero
    // in a Keep, Pit or other special area. Since those spawn their own
    // monsters, the hero can end up surrounded by monsters.
    _heroPos = _stage.findOpenTile();

    yield* _spawnMonsters();
    yield* _dropItems();
  }

  /// Marks doorway tiles on the endpoints of passages.
  void _findDoorways() {
    var doorways = <Vec>[];
    for (var pos in _stage.bounds.inflate(-1)) {
      var tile = _stage[pos].type;

      // Must be a passage.
      if (tile != Tiles.passage) continue;

      for (var dir in Direction.cardinal) {
        // Must lead into an open area.
        if (_stage[pos + dir].type != Tiles.open) continue;

        // From another open area or passage.
        var behind = _stage[pos + dir.rotate180].type;
        if (behind != Tiles.open &&
            behind != Tiles.passage &&
            behind != Tiles.doorway) {
          continue;
        }

        // With walls on both sides.
        if (_stage[pos + dir.rotateLeft90].type != Tiles.solid) continue;
        if (_stage[pos + dir.rotateRight90].type != Tiles.solid) continue;

        // It's a doorway.
        _stage[pos].type = Tiles.doorway;
        doorways.add(pos);
        break;
      }
    }

    // The passage generator can generate passages of length 2. The previous
    // code correctly turns both tiles into doorways. That ends up looking
    // funny if both become doors. So go through and randomly turn doorways
    // back to passages if they are adjacent to another doorway.
    rng.shuffle(doorways);
    for (var doorway in doorways) {
      // May have already been turned back into a passage.
      if (_stage[doorway].type != Tiles.doorway) continue;

      for (var neighbor in doorway.cardinalNeighbors) {
        if (_stage[neighbor].type == Tiles.doorway) {
          _stage[rng.oneIn(2) ? doorway : neighbor].type = Tiles.passage;
        }
      }
    }
  }

  /// Turn the temporary tiles into real tiles based on each architecutre's
  /// painters.
  void _paintTiles() {
    for (var entry in _tilesByArchitecture.entries) {
      var architecture = entry.key;
      var paintStyle = PaintStyle.rock;
      if (architecture != null) {
        paintStyle = architecture.paintStyle;
      }

      var painter = Painter(this, _architect, architecture);
      for (var pos in entry.value) {
        painter.setTile(pos, paintStyle.paintTile(painter, pos));
      }
    }
  }

  Iterable<String> _placeDecor() sync* {
    for (var entry in _tilesByArchitecture.entries) {
      var architecture = entry.key;
      if (architecture == null) continue;

      // Shuffle the tiles so that when we pick the first matching tile, it
      // isn't biased.
      var tiles = entry.value.toList();
      rng.shuffle(tiles);

      // TODO: Let the paint style affect the decor too. So, for example, the
      // decor places a table and the paint style changes the material of it.
      var painter = Painter(this, _architect, architecture);

      var decorTiles =
          rng.round(tiles.length * architecture.style.decorDensity);
      decorTiles = rng.float(decorTiles * 0.8, decorTiles * 1.2).ceil();

      var tries = 0;
      while (tries++ < decorTiles && painter.paintedCount < decorTiles) {
        var decor =
            Decor.choose(_architect.depth, architecture.style.decorTheme);
        if (decor == null) continue;

        for (var i = 0; i < tiles.length; i++) {
          var tile = tiles[i];
          if (!decor.canPlace(painter, tile)) continue;

          decor.place(painter, tile);

          // Move the tile index later in the array so we don't retry it as
          // often. In particular, this avoids problems in cases where a decor
          // can be placed on top of itself (like moss) and where it would keep
          // hitting the same tile over and over.
          var j = rng.range(i, tiles.length);
          tiles[i] = tiles[j];
          tiles[j] = tile;

          yield "Placed decor";
          break;
        }
      }
    }
  }

  Iterable<String> _spawnMonsters() sync* {
    // Let the architectures that control their own monsters go.
    var spawned = <Architecture>{};
    _tilesByArchitecture.forEach((architecture, tiles) {
      if (architecture == null) return;

      var painter = Painter(this, _architect, architecture);
      if (architecture.spawnMonsters(painter)) {
        spawned.add(architecture);
      }
    });

    // Build a density map for where monsters should spawn.
    var densityMap = DensityMap(_stage.width, _stage.height);
    Debug.densityMap = densityMap;

    var flow = MotilityFlow(_stage, _heroPos, Motility.all, avoidActors: false);

    for (var pos in _stage.bounds.inflate(-1)) {
      var architecture = _architect.ownerAt(pos);
      if (architecture == null) continue;
      if (spawned.contains(architecture)) continue;

      var distance = flow.costAt(pos);
      if (distance == null) continue;
      if (distance < 10) continue;

      var density = 4 + math.sqrt(distance - 10);
      densityMap[pos] = (density * architecture.style.monsterDensity).toInt();
    }

    // Try spawn as many monsters as needed to reach a total experience value
    // based on the number of open tiles. (In other words, each tile the player
    // explores nets some average expected amount of experience.)
    var experiencePerTile = 2.0 + math.pow(_architect.depth - 1, 2.0) * 0.2;
    var goalExperience = densityMap.possibleTiles * experiencePerTile;

    // Add some randomness so some stages are worth more than others.
    goalExperience += rng.float(goalExperience * 0.2);

    var totalExperience = 0;

    while (totalExperience < goalExperience) {
      var pos = densityMap.choose();

      // If there are no remaining open tiles, abort.
      if (pos == null) break;

      // TODO: Do a random walk from [pos] and use the resulting tile for the
      // group. That way, there is some bleed and foreshadowing between
      // architectures.
      var architecture = _architect.ownerAt(pos);
      var group = rng.item(architecture.style.monsterGroups);
      var breed = Monsters.breeds.tryChoose(_architect.depth, tag: group);

      // Don't place a breed whose motility doesn't match the tile.
      if (!_stage[pos].canEnter(breed.motility)) continue;

      // Don't place dead or redundant uniques.
      if (!_canSpawn(breed)) continue;

      var experience = _spawnMonster(densityMap, pos, breed);
      yield "Spawned monster";

      // Stop if we ran out of open tiles.
      if (experience == null) break;

      totalExperience += experience;
    }

    Debug.densityMap = null;
  }

  Breed chooseBreed(int depth, {String tag, bool includeParentTags}) {
    while (true) {
      var breed = Monsters.breeds
          .tryChoose(depth, tag: tag, includeParents: includeParentTags);

      if (_canSpawn(breed)) return breed;
    }
  }

  /// Whether a monster of [breed] can be spawned.
  ///
  /// Returns `false` if [breed] is a unique that's already been killed or
  /// spawned.
  bool _canSpawn(Breed breed) {
    if (!breed.flags.unique) return true;
    if (_architect.lore.slain(breed) > 0) return false;
    if (_spawnedUniques.contains(breed)) return false;

    return true;
  }

  void spawnMonster(Vec pos, Breed breed) {
    _spawnMonster(null, pos, breed);
  }

  int _spawnMonster(DensityMap density, Vec pos, Breed breed) {
    var isCorpse = !breed.flags.unique && rng.oneIn(10);

    var experience = 0;
    void spawn(Breed breed, Vec pos) {
      if (_architect.stage.actorAt(pos) != null) return;
      if (!_canSpawn(breed)) return;

      if (breed.flags.unique) _spawnedUniques.add(breed);

      if (isCorpse) {
        _architect.stage.placeDrops(pos, breed.motility, breed.drop);
      } else {
        var monster = breed.spawn(_architect.stage.game, pos);
        _architect.stage.addActor(monster);
        experience += monster.experience;

        // Don't cluster monsters too much.
        // TODO: Increase distance for stronger monsters?
        if (density != null) density.reduceAround(_stage, pos, Motility.all, 5);
      }

      // TODO: Get this working again. Instead of setting the tile type, we may
      // want a second attribute for a stain applied on top of the tile.
//      if (breed.stain != null) {
//        // TODO: Larger stains for stronger monsters?
//        _stain(breed.stain, pos, 5, 2);
//      }
    }

    var breeds = breed.spawnAll();

    // TODO: Hack. Flow doesn't include the starting tile, so handle it here.
    spawn(breeds[0], pos);

    for (var breed in breeds.skip(1)) {
      // TODO: Hack. Need to create a new flow each iteration because it doesn't
      // handle actors being placed while the flow is being used -- it still
      // thinks those tiles are available. Come up with a better way to place
      // the monsters.
      var flow = MotilityFlow(_architect.stage, pos, breed.motility);

      // TODO: Ideally, this would follow the location preference of the breed
      // too, even for minions of different breeds.
      var here = flow.reachable.firstWhere((_) => true, orElse: () => null);

      // If there are no open tiles, discard the remaining monsters.
      if (here == null) break;

      spawn(breed, here);
    }

    return experience;
  }

//  void _stain(TileType tile, Vec start, int distance, int count) {
//    // Make a bunch of wandering paths from the starting point, leaving stains
//    // as they go.
//    for (var i = 0; i < count; i++) {
//      var pos = start;
//      for (var j = 0; j < distance; j++) {
//        if (rng.percent(60) && getTileAt(pos) == Tiles.floor) {
//          setTileAt(pos, tile);
//        }
//
//        var dirs = Direction.all
//            .where((dir) => getTileAt(pos + dir).isTraversable)
//            .toList();
//        if (dirs.isEmpty) return;
//        pos += rng.item(dirs);
//      }
//    }
//  }

  Iterable<String> _dropItems() sync* {
    // Build a density map for where items should drop.
    var densityMap = DensityMap(_stage.width, _stage.height);
    Debug.densityMap = densityMap;

    var flow = MotilityFlow(_stage, _heroPos, Motility.doorAndWalk,
        avoidActors: false);

    for (var pos in _stage.bounds.inflate(-1)) {
      var architecture = _architect.ownerAt(pos);
      if (architecture == null) continue;

      var distance = flow.costAt(pos);
      if (distance == null) continue;

      // Don't place items on doors.
      if (!_stage[pos].isWalkable) continue;

      // TODO: Increase density in an area right around the hero so there's a
      // chance of finding something as soon as they show up.

      var density = 10 + math.sqrt(distance + 1);
      // TODO: Increase density if we go past articulation points, secret doors,
      // strong monsters, etc.
      densityMap[pos] = (density * architecture.style.itemDensity).toInt();
    }

    // Try to drop as many items as needed to reach a total price value based
    // on the number of open tiles. (In other words, each tile the player
    // explores nets some average expected amount of value.) Note that this
    // doesn't include the items dropped by corpses.
    // TODO: Prices are very untuned, which in turn makes this very untuned.
    // Once prices are in a better state, tweak this to follow.
    var pricePerTile = 0.05 + (_architect.depth - 1) * 0.05;
    var goalPrice = densityMap.possibleTiles * pricePerTile;

    // Add some randomness so some stages are worth more than others.
    goalPrice += rng.float(goalPrice * 0.2);

    var totalPrice = 0;

    while (totalPrice < goalPrice) {
      var pos = densityMap.choose();

      // If there are no remaining open tiles, abort.
      if (pos == null) break;

      // TODO: Style-specific drop types.
      var floorDrop = FloorDrops.choose(_architect.depth);

      var items =
          _architect.stage.placeDrops(pos, Motility.walk, floorDrop.drop);
      for (var item in items) {
        // Give worthless items a little price so we don't clutter too many of
        // them.
        totalPrice += math.max(item.price, 1);
      }

      densityMap.reduceAround(_stage, pos, Motility.doorAndWalk, 3);

      yield "Spawned item";
    }

    Debug.densityMap = null;
  }
}

class DensityMap {
  final Array2D<int> _density;
  int _total = 0;

  DensityMap(int width, int height) : _density = Array2D(width, height, 0);

  int operator [](Vec pos) => _density[pos];

  operator []=(Vec pos, int value) {
    var old = _density[pos];
    _total = _total - old + value;
    _density[pos] = value;

    if (old == 0 && value > 0) _possibleTiles++;
    if (old > 0 && value == 0) _possibleTiles--;
  }

  /// The number of tiles whose density is non-zero.
  int get possibleTiles => _possibleTiles;
  int _possibleTiles = 0;

  /// Picks a random tile from the map, weighed by the density of each tile.
  ///
  /// Returns `null` if no tiles have any density.
  Vec choose() {
    if (_total == 0) return null;

    var n = rng.range(_total);
    for (var pos in _density.bounds) {
      var density = _density[pos];
      if (n < density) return pos;
      n -= density;
    }

    throw "unreachable";
  }

  void reduceAround(Stage stage, Vec start, Motility motility, int range) {
    this[start] = 0;

    var flow = MotilityFlow(stage, start, motility, maxDistance: range);
    for (var pos in flow.reachable) {
      var scale = flow.costAt(pos) / range;
      this[pos] = (this[pos] * scale).toInt();
    }
  }
}
