import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'drops.dart';
import 'dungeon/dungeon.dart';
import 'monsters.dart';
import 'tiles.dart';

typedef Vec ChooseLocation(Dungeon dungeon);

final _spawnPattern = new RegExp(r"(.*) (\d+)-(\d+)");

final ResourceSet<Encounter> _encounters = new ResourceSet();

int _depth = 1;
_EncounterBuilder _builder;

class Encounters {
  static void initialize() {
    _encounters.defineTags("encounter");

    setDepth(1);
    monster("green jelly", 0, 5).hugWall().stain(Tiles.greenJellyStain, 5);
    monster("brown spider", 0, 2).preferCorridor().stain(Tiles.spiderweb, 3);
    monster("forest sprite", 1, 3);
    monster("giant cockroach", 2, 5).hugCorner();
    monster("hapless adventurer");

    // TODO: Tune this?
    encounter()
        .hugWall()
        .drop(60, "Skull", 1)
        .drop(30, "weapon", 1)
        .drop(30, "armor", 1)
        .drop(40, "magic", 1);

    encounter().hugCorner().drop(100, "Rock");

    setDepth(2);
    monster("stray cat");

    setDepth(3);
    monster("gray spider", 0, 1).preferCorridor().stain(Tiles.spiderweb, 4);

    _finishBuilder();
  }

  static Encounter choose(int depth) =>
      _encounters.tryChoose(depth, "encounter");
}

class Encounter {
  final ChooseLocation _location;
  final _Decorator _decorator;
  final List<_Spawn> _spawns;
  final List<Drop> _drops;

  Encounter(this._location, this._decorator, this._spawns, this._drops);

  void spawn(Dungeon dungeon) {
    var encounterPos = _location(dungeon);

    var monsterCount = 0;
    var flow = new Flow(dungeon.stage, encounterPos);

    for (var spawn in _spawns) {
      var count = rng.inclusive(spawn.min, spawn.max);
      if (count == 0) continue;

      for (var i = 0; i < count; i++) {
        var monsterPos = encounterPos;
        if (dungeon.stage.actorAt(monsterPos) != null) {
          monsterPos =
              flow.nearestWhere((pos) => dungeon.stage.actorAt(pos) == null);
        }
        if (monsterPos == null) break;

        dungeon.spawnMonster(spawn.breed, monsterPos);
        monsterCount++;
      }
    }

    if (_decorator != null) {
      _decorator.decorate(dungeon, encounterPos, monsterCount);
    }

    for (var drop in _drops) {
      // TODO: Mostly copied from Monster.onDied(). Refactor.
      // Try to keep dropped items from overlapping.
      var flow = new Flow(dungeon.stage, encounterPos,
          canOpenDoors: false, ignoreActors: true);

      drop.spawnDrop((item) {
        var itemPos = encounterPos;
        if (dungeon.stage.isItemAt(itemPos)) {
          itemPos = flow.nearestWhere((pos) {
            if (rng.oneIn(5)) return true;
            return !dungeon.stage.isItemAt(pos);
          });

          if (itemPos == null) itemPos = encounterPos;
        }

        dungeon.stage.addItem(item, itemPos);
      });
    }
  }
}

Vec _preferWalls(Dungeon dungeon, int tries, int idealWalls) {
  var bestWalls = -1;
  Vec best;
  for (var i = 0; i < tries; i++) {
    var pos = dungeon.stage.findOpenTile();
    var walls = Direction.all.where((dir) {
      return !dungeon.getTileAt(pos + dir).isTraversable;
    }).length;

    // Don't try to crowd corridors.
    if (walls >= 6 && !rng.oneIn(3)) continue;

    // Early out as soon as we find a good enough spot.
    if (walls >= idealWalls) return pos;

    if (walls > bestWalls) {
      best = pos;
      bestWalls = walls;
    }
  }

  // Otherwise, take the best we could find.
  return best;
}

void setDepth(int depth) {
  _finishBuilder();
  _depth = depth;
}

void _finishBuilder() {
  if (_builder == null) return;

  _builder.build();
  _builder = null;
}

_EncounterBuilder monster(String name, [int minOrMax, int max]) =>
    encounter().monster(name, minOrMax, max);

_EncounterBuilder encounter() {
  _finishBuilder();
  _builder = new _EncounterBuilder();
  return _builder;
}

class _EncounterBuilder {
  _Decorator _decorator;
  ChooseLocation _location = (dungeon) => dungeon.stage.findOpenTile();
  final List<_Spawn> _spawns = [];
  final List<Drop> _drops = [];

  _EncounterBuilder monster(String name, [int minOrMax, int max]) {
    if (minOrMax == null) {
      minOrMax = 1;
      max = 1;
    } else if (max == null) {
      max = minOrMax;
      minOrMax = 1;
    }

    _spawns.add(new _Spawn(Monsters.breeds.find(name), minOrMax, max));
    return this;
  }

  _EncounterBuilder drop(int chance, String name, [int depthOffset = 0]) {
    _drops.add(percentDrop(chance, name, _depth + depthOffset));
    return this;
  }

  _EncounterBuilder stain(TileType tile, int distance) {
    _decorator = new _StainDecorator(tile, distance);
    return this;
  }

  _EncounterBuilder hugWall() {
    _location = (dungeon) => _preferWalls(dungeon, 20, 3);
    return this;
  }

  _EncounterBuilder hugCorner() {
    _location = (dungeon) => _preferWalls(dungeon, 20, 4);
    return this;
  }

  _EncounterBuilder preferCorridor() {
    _location = (dungeon) {
      // Don't *always* go in corridors.
      if (rng.oneIn(6)) return _preferWalls(dungeon, 20, 4);

      return dungeon.findOpenCorridor();
    };
    return this;
  }

  void build() {
    var encounter = new Encounter(_location, _decorator, _spawns, _drops);
    _encounters.addUnnamed(encounter, _depth, 1, "encounter");
  }
}

class _Spawn {
  final Breed breed;
  final int min;
  final int max;

  _Spawn(this.breed, this.min, this.max);
}

abstract class _Decorator {
  void decorate(Dungeon dungeon, Vec pos, int mounterCount);
}

class _StainDecorator extends _Decorator {
  final TileType _tile;
  final int _distance;

  _StainDecorator(this._tile, this._distance);

  void decorate(Dungeon dungeon, Vec start, int monsterCount) {
    // Make a bunch of wandering paths from the starting point, leaving stains
    // as they go.
    for (var i = 0; i < 1 + monsterCount * 2; i++) {
      var pos = start;
      for (var j = 0; j < _distance; j++) {
        if (rng.percent(60) && dungeon.getTileAt(pos) == Tiles.floor) {
          dungeon.setTileAt(pos, _tile);
        }

        var dirs = Direction.all.where((dir) {
          return dungeon.getTileAt(pos + dir).isTraversable;
        }).toList();
        pos += rng.item(dirs);
      }
    }
  }
}
