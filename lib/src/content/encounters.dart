import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'drops.dart';
import 'dungeon/dungeon.dart';
import 'monsters.dart';
import 'tiles.dart';

typedef Vec ChooseLocation(Dungeon dungeon);

final ResourceSet<Encounter> _encounters = new ResourceSet();

int _depth = 1;
_EncounterBuilder _builder;

class Encounters {
  static void initialize() {
    _encounters.defineTags("encounter");

    // TODO: Encounters with mixed monster types.

    setDepth(1);
    monster("green jelly", 0, 4).hugWall().stain(Tiles.greenJellyStain, 5);
    monster("brown spider", 0, 2).preferCorridor().stain(Tiles.spiderweb, 3);
    monster("forest sprite", 1, 2);
    monster("giant cockroach", 2, 5).hugCorner();
    monster("hapless adventurer");
    monster("giant slug");
    monster("lazy eye").avoidWall();
    monster("mouse", 1, 3).hugWall();
    monster("frog").prefer(Tiles.grass);
    monster("garter snake").prefer(Tiles.grass);
    monster("stray cat");

    setDepth(2);
    monster("blood worm", 2, 4);
    monster("brown bat", 1, 3).hugWall();
    monster("giant earthworm").preferCorridor();
    monster("gray spider").preferCorridor().stain(Tiles.spiderweb, 4);
    // TODO: Too similar to green jelly.
    monster("green slime", 0, 4).hugCorner().stain(Tiles.greenJellyStain, 5);
    monster("mangy cur", 1, 3);
    monster("sewer rat", 1, 5).hugWall();
    monster("simpering knave");

    setDepth(3);
    monster("gray spider", 0, 1).preferCorridor().stain(Tiles.spiderweb, 4);
    monster("brown snake").prefer(Tiles.grass);
    monster("decrepit mage");
    monster("giant centipede").preferCorridor();
    monster("house sprite", 1, 2).avoidWall();
    monster("sickly rat", 2, 5).hugWall();
    monster("crow", 3, 7);

    setDepth(4);
    monster("frosty slime", 0, 4).hugCorner().stain(Tiles.whiteJellyStain, 5);
    monster("giant bat").hugWall();
    monster("goblin peon", 2, 4).avoidWall();
    monster("drunken priest");

    encounter().monster("kobold", 0, 2).monster("wild dog", 0, 3);
    encounter().monster("scurrilous imp", 1, 2).monster("vexing imp", 1, 2);

    setDepth(5);
    monster("unlucky ranger");
    monster("mad eye").avoidWall();
    monster("cave bat", 2, 6).hugWall();

    setDepth(6);
    monster("mud slime", 0, 4).hugCorner().stain(Tiles.brownJellyStain, 5);
    monster("giant spider", 0, 1).preferCorridor().stain(Tiles.spiderweb, 5);
    monster("plague rat", 3, 6).hugWall();
    monster("raven", 3, 6);
    monster("suppurating slug");

    encounter()
        .monster("goblin fighter", 0, 2)
        .monster("goblin archer", 0, 2)
        .monster("goblin peon", 0, 2);

    setDepth(7);
    monster("cave snake").preferCorridor();
    monster("giant cave worm").preferCorridor();
    monster("juvenile salamander").avoidWall();
    monster("mongrel", 2, 5);

    encounter()
        .monster("mischievous sprite", 1, 2)
        .monster("house sprite", 1, 2);

    setDepth(8);
    encounter()
        .monster("goblin warrior", 1, 3)
        .monster("goblin fighter", 0, 1)
        .monster("goblin archer", 0, 1)
        .monster("goblin peon", 0, 1);

    setDepth(9);
    monster("floating eye").avoidWall();

    encounter()
        .monster("goblin mage")
        .monster("goblin fighter", 0, 1)
        .monster("goblin archer", 0, 1)
        .monster("goblin peon", 2, 3);

    setDepth(10);
    monster("fire worm", 3, 7).hugWall();

    encounter()
        .monster("kobold shaman")
        .monster("kobold", 1, 2)
        .monster("wild dog", 0, 2);

    setDepth(11);
    monster("lizard guard", 1, 3);

    encounter()
        .monster("imp incanter")
        .monster("scurrilous imp", 0, 2)
        .monster("vexing imp", 0, 2);

    setDepth(12);

    encounter()
        .monster("goblin ranger", 0, 2)
        .monster("goblin mage", 0, 1)
        .monster("goblin fighter", 0, 2)
        .monster("goblin archer", 0, 1);

    setDepth(13);
    monster("salamander");

    encounter()
        .monster("kobold trickster")
        .monster("kobold shaman", 0, 1)
        .monster("kobold", 1, 2)
        .monster("wild dog", 0, 1);

    setDepth(14);
    // TODO: Figure out how to handle uniques.
    monster("Erlkonig, the Goblin Prince");

    encounter()
        .monster("imp warlock")
        .monster("imp incanter", 1, 2)
        .monster("scurrilous imp", 0, 2)
        .monster("vexing imp", 0, 1);

    setDepth(15);
    monster("smoking slime", 0, 4).hugCorner().stain(Tiles.redJellyStain, 5);

    encounter()
        .monster("kobold priest")
        .monster("kobold shaman", 0, 1)
        .monster("kobold", 1, 2)
        .monster("wild dog", 0, 1);

    encounter()
        .monster("lizard protector", 2, 3)
        .monster("salamander", 1, 2);

    setDepth(17);
    encounter()
        .monster("armored lizard", 2, 3)
        .monster("lizard protector", 0, 2)
        .monster("salamander", 0, 2);

    setDepth(19);
    encounter()
        .monster("scaled guardian", 2, 3)
        .monster("armored lizard", 0, 2)
        .monster("lizard protector", 0, 2)
        .monster("salamander", 0, 2);

    setDepth(20);
    monster("sparkling slime", 0, 4).hugCorner().stain(Tiles.violetJellyStain, 5);
    monster("baleful eye").avoidWall();
    // TODO: Figure out how to handle uniques.
    monster("Feng");

    setDepth(21);
    encounter()
        .monster("saurian", 2, 3)
        .monster("scaled guardian", 1, 2)
        .monster("armored lizard", 0, 2)
        .monster("salamander", 0, 2);

    setDepth(22);
    setDepth(23);
    setDepth(24);

    setDepth(25);
    monster("caustic slime", 0, 4).hugCorner().stain(Tiles.greenJellyStain, 5);

    setDepth(26);
    setDepth(27);
    setDepth(28);
    setDepth(29);

    setDepth(30);
    monster("malevolent eye").avoidWall();

    setDepth(35);
    monster("virulent slime", 0, 4).hugCorner().stain(Tiles.greenJellyStain, 5);

    setDepth(36);
    setDepth(37);
    setDepth(38);
    setDepth(39);

    setDepth(40);
    monster("murderous eye").avoidWall();

    setDepth(41);
    setDepth(42);
    setDepth(43);
    setDepth(44);

    setDepth(45);
    monster("ectoplasm", 0, 4).hugCorner().stain(Tiles.grayJellyStain, 5);

    setDepth(46);
    setDepth(47);
    setDepth(48);
    setDepth(49);

    setDepth(50);
    // TODO: Should have hoard of treasure around it.
    monster("red dragon").avoidWall();

    setDepth(51);
    setDepth(52);
    setDepth(53);
    setDepth(54);
    setDepth(55);
    setDepth(56);
    setDepth(57);
    setDepth(58);
    setDepth(59);

    setDepth(60);
    monster("watcher").avoidWall();

    _finishBuilder();

    // Add generic stuff at every depth.
    for (var i = 1; i <= 100; i++) {
      setDepth(i);

      // TODO: Tune this.
      encounter()
          .hugWall()
          .drop(60, "Skull")
          .drop(30, "weapon")
          .drop(30, "armor")
          .drop(30, "magic")
          .drop(30, "magic");

      // TODO: Rarer at greater depths?
      encounter().hugCorner().drop(100, "Rock");
      encounter().prefer(Tiles.grass).drop(100, "Rock");
    }
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
    // TODO: Allow spawning flying monsters on flyable tiles.
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

Vec _avoidWalls(Dungeon dungeon, int tries) {
  var bestWalls = 100;
  Vec best;
  for (var i = 0; i < tries; i++) {
    var pos = dungeon.stage.findOpenTile();
    var walls = Direction.all.where((dir) {
      return !dungeon.getTileAt(pos + dir).isWalkable;
    }).length;

    // Early out as soon as we find a good enough spot.
    if (walls == 0) return pos;

    if (walls < bestWalls) {
      best = pos;
      bestWalls = walls;
    }
  }

  // Otherwise, take the best we could find.
  return best;
}

Vec _prefer(Dungeon dungeon, TileType tile, int tries) {
  // TODO: This isn't very efficient. Probably better to build a cached set of
  // all tile positions by type.
  for (var i = 0; i < tries; i++) {
    var pos = dungeon.stage.findOpenTile();
    if (dungeon.getTileAt(pos) == tile) return pos;
  }

  // Pick any tile.
  return dungeon.stage.findOpenTile();
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

  _EncounterBuilder avoidWall() {
    _location = (dungeon) => _avoidWalls(dungeon, 20);
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

  _EncounterBuilder prefer(TileType tile) {
    _location = (dungeon) => _prefer(dungeon, tile, 40);
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
