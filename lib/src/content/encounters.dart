import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'dungeon/dungeon.dart';
import 'monsters.dart';
import 'tiles.dart';

enum EncounterLocation { anywhere, hugWalls }

class Encounter {
  static final List<Encounter> _encounters = [];

  static void initialize() {
    // TODO: Use a ResourceSet and/or make multiple tables based on biome, etc.
    _encounters.add(new Encounter(
        EncounterLocation.hugWalls,
        new _StainDecorator(Tiles.greenJellyStain),
        [new _Spawn(Monsters.breeds.find("green jelly"), 1, 5)]));
  }

  static Encounter choose() {
    if (_encounters.isEmpty) initialize();

    return rng.item(_encounters);
  }

  final EncounterLocation _location;
  final _Decorator _decorator;
  final List<_Spawn> _spawns;

  Encounter(this._location, this._decorator, this._spawns);

  void spawn(Dungeon dungeon, Vec encounterPos) {
    switch (_location) {
      case EncounterLocation.anywhere:
        // Do nothing.
        break;

      case EncounterLocation.hugWalls:
        encounterPos = _hugWalls(dungeon, encounterPos);
        break;
    }

    // TODO: Temp.
    dungeon.setTileAt(encounterPos, Tiles.tallGrass);

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
  }

  Vec _hugWalls(Dungeon dungeon, Vec pos) {
    var flow = new Flow(dungeon.stage, pos, maxDistance: 15);
    var moved = flow.nearestWhere((pos) {
      for (var dir in Direction.cardinal) {
        if (!dungeon.getTileAt(pos + dir).isTraversable) return true;
      }

      return false;
    });

    return moved ?? pos;
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

  _StainDecorator(this._tile);

  void decorate(Dungeon dungeon, Vec start, int monsterCount) {
    // Make a bunch of wandering paths from the starting point, leaving stains
    // as they go.
    for (var i = 0; i < monsterCount * 2; i++) {
      var pos = start;
      for (var j = 0; j < 4 + monsterCount ~/ 2; j++) {
        if (rng.percent(60) && dungeon.getTileAt(pos).isPassable) {
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
