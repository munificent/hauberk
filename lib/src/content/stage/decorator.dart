import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../decor/decor.dart';
import '../monster/monsters.dart';
import 'architect.dart';
import 'painter.dart';

class Decorator {
  final Architect _architect;
  Vec _heroPos;

  /// The unique breeds that have already been placed on the stage. Ensures we
  /// don't spawn the same unique more than once.
  var _spawnedUniques = Set<Breed>();

  Decorator(this._architect);

  Vec get heroPos => _heroPos;

  Stage get _stage => _architect.stage;

  Iterable<String> decorate() sync* {
    _paintTiles();

    // TODO: Should this happen before or after painting?
    yield* _placeDecor();

    // TODO: Place stairs.

    // TODO: Place doors.

    // TODO: Instead of bleeding themes around, here's a simpler idea:
    // 1. Choose a random place to spawn a monster/item.
    // 2. Do a random walk from there to a result tile.
    // 3. Use the result tile's architecture/style/whatever to generate the
    //    monster/item.
    // 4. Place it in the original random location.
    // This way, you can get nearby styles and foreshadowing without a lot of
    // complex calculation.

    // TODO: Do something smarter.
    _heroPos = _stage.findOpenTile();

    yield* _spawnMonsters();

    // TODO: Items.
  }

  /// Turn the temporary tiles into real tiles based on each architecutre's
  /// painters.
  void _paintTiles() {
    for (var pos in _architect.stage.bounds) {
      var tile = _stage[pos];
      var owner = _architect.ownerAt(pos);
      if (owner == null) {
        tile.type = Painter.base.paint(tile.type);
      } else {
        tile.type = owner.painter.paint(tile.type);
      }
    }
  }

  Iterable<String> _placeDecor() sync* {
    var tilesByOwner = <Architecture, List<Vec>>{};
    for (var pos in _stage.bounds) {
      var owner = _architect.ownerAt(pos);
      if (owner != null) {
        tilesByOwner.putIfAbsent(owner, () => []).add(pos);
      }
    }

    for (var entry in tilesByOwner.entries) {
      var architecture = entry.key;
      var tiles = entry.value;

      var painter = DecorPainter._(_architect, architecture);

      // TODO: Let architecture/theme control density.
      var decorTiles = rng.round(tiles.length * 0.1);
      decorTiles = rng.float(decorTiles * 0.8, decorTiles * 1.2).ceil();

      var tries = 0;
      while (tries++ < decorTiles && painter._painted < decorTiles) {
        var decor = Decor.choose(architecture.style.decorTheme);
        if (decor == null) continue;

        var allowed = <Vec>[];

        for (var tile in tiles) {
          if (decor.canPlace(painter, tile)) {
            allowed.add(tile);
          }
        }

        if (allowed.isNotEmpty) {
          decor.place(painter, rng.item(allowed));
          yield "Placed decor";
        }
      }
    }
  }

  Iterable<String> _spawnMonsters() sync* {
    var densityMap = DensityMap(_stage.width, _stage.height);
    var flow = MotilityFlow(_stage, _heroPos, Motility.all);

    for (var pos in _stage.bounds.inflate(-1)) {
      var architecture = _architect.ownerAt(pos);
      if (architecture == null) continue;

      var distance = flow.costAt(pos);
      if (distance == null) continue;
      if (distance < 10) continue;

      var density = 4 + math.sqrt(distance - 10);
      density *= architecture.style.monsterDensity;
      densityMap[pos] = density.toInt();
    }

    // TODO: Tune this.
    var monsterCount = 200;
    var monsters = 0;

    while (monsters < monsterCount) {
      var pos = densityMap.pickRandom();

      // If there are no remaining open tiles, abort.
      if (pos == null) break;

      var architecture = _architect.ownerAt(pos);
      var group = rng.item(architecture.style.monsterGroups);
      var breed = Monsters.breeds.tryChoose(_architect.depth, group);

      // Don't place a breed whose motility doesn't match the tile.
      if (!_stage[pos].canEnter(breed.motility)) continue;

      // Don't place dead or redundant uniques.
      if (breed.flags.unique) {
        if (_architect.lore.slain(breed) > 0) continue;
        if (_spawnedUniques.contains(breed)) continue;

        _spawnedUniques.add(breed);
      }

      var spawned = _spawnMonster(densityMap, pos, breed);
      yield "Spawn monster";

      // Stop if we ran out of open tiles.
      if (spawned == null) break;

      monsters += spawned;
    }
  }

  int _spawnMonster(DensityMap density, Vec pos, Breed breed) {
    var isCorpse = rng.oneIn(8);
    var breeds = breed.spawnAll();

    var spawned = 0;
    spawn(Breed breed, Vec pos) {
      if (isCorpse) {
        _architect.stage.placeDrops(pos, breed.motility, breed.drop);
      } else {
        _architect.stage.addActor(breed.spawn(_architect.stage.game, pos));
        spawned++;

        // Don't place another monster here.
        density[pos] = 0;

        // TODO: Subtract density from nearby tiles to avoid clustering
        // monsters.
      }

      // TODO: Get this working again. Instead of setting the tile type, we may
      // want a second attribute for a stain applied on top of the tile.
//      if (breed.stain != null) {
//        // TODO: Larger stains for stronger monsters?
//        _stain(breed.stain, pos, 5, 2);
//      }
    }

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

    return spawned;
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
}

// TODO: Figure out how this interacts with Painter.
class DecorPainter {
  final Architect _architect;
  final Architecture _architecture;
  int _painted = 0;

  DecorPainter._(this._architect, this._architecture);

  Rect get bounds => _architect.stage.bounds;

  bool ownsTile(Vec pos) => _architect.ownerAt(pos) == _architecture;

  TileType getTile(Vec pos) {
    assert(ownsTile(pos));
    return _architect.stage[pos].type;
  }

  void setTile(Vec pos, TileType type) {
    assert(_architect.ownerAt(pos) == _architecture);
    _architect.stage[pos].type = type;
    _painted++;
  }
}

class DensityMap {
  final Array2D<int> _density;
  int _total = 0;

  DensityMap(int width, int height) : _density = Array2D(width, height, 0);

  operator [](Vec pos) => _density[pos];

  operator []=(Vec pos, int value) {
    var old = _density[pos];
    _total = _total - old + value;
    _density[pos] = value;
  }

  Vec pickRandom() {
    if (_total == 0) return null;

    var n = rng.range(_total);
    for (var pos in _density.bounds) {
      var density = _density[pos];
      if (n < density) return pos;
      n -= density;
    }

    throw "unreachable";
  }
}
