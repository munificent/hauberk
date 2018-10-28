import 'dart:collection';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
//import '../decor/decor.dart';
import '../item/floor_drops.dart';
import '../monster/monsters.dart';
import '../stage/blob.dart';
import '../tiles.dart';
import 'aquatic.dart';
import 'place.dart';
import 'rooms.dart';

// TODO: Eliminate biome as a class and just have dungeon call it directly?
abstract class Biome {
  Iterable<String> generate();
}

// TODO: Rename to something generic like "Generator" and then use "Dungeon"
// to refer to the "rooms and passages" biome.
class Dungeon {
  // TODO: Generate magical shrine/chests that let the player choose from one
  // of a few items. This should help reduce the number of useless-for-this-hero
  // items that are dropped.

  // TODO: Hack temp. Static so that dungeon_test can access these while it's
  // being generated.
  static Dungeon last;
  static List<Place> debugPlaces;

  final Lore _lore;
  final Stage stage;
  final int depth;

  final List<Biome> _biomes = [];

  final List<Place> _places = [];
  final Array2D<Place> _cells;

  /// The unique breeds that have already been place on the stage. Ensures we
  /// don't spawn the same unique more than once.
  var _spawnedUniques = Set<Breed>();

  Rect get bounds => stage.bounds;

  Rect get safeBounds => stage.bounds.inflate(-1);

  int get width => stage.width;

  int get height => stage.height;

  Dungeon(this._lore, this.stage, this.depth)
      : _cells = Array2D(stage.width, stage.height);

  Iterable<String> generate(Function(Vec) placeHero) sync* {
    last = this;
    debugPlaces = _places;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        setTile(x, y, Tiles.rock);
      }
    }

    _chooseBiomes();

    for (var biome in _biomes) {
      yield* biome.generate();
    }

    yield "Applying themes";

    // Apply and spread themes from the biomes.
    _places.sort((a, b) => b.cells.length.compareTo(a.cells.length));
    _findConnections(this, _places);

    for (var place in _places) {
      place.applyThemes();
    }

    // TODO: Get this working again with new themes.
//    yield "Placing decor";
//    for (var place in _places) {
//      var density = place.cells.length * place.decorDensity;
//      var decorCount = rng.round(rng.float(density * 0.8, density * 1.2));
//
//      for (var i = 0; i < decorCount; i++) {
//        var theme = place.chooseTheme();
//        var decor = Decor.choose(theme);
//        if (decor == null) continue;
//
//        var allowed = <Vec>[];
//
//        for (var cell in place.cells) {
//          var offset = cell.offset(-1, -1);
//          if (decor.canPlace(this, offset)) {
//            allowed.add(offset);
//          }
//        }
//
//        if (allowed.isNotEmpty) {
//          decor.place(this, rng.item(allowed));
//          yield "Placed decor";
//        }
//      }
//    }

    // Some places are naturally fully illuminated.
    for (var place in _places) {
      if (place.emanates) {
        for (var cell in place.cells) {
          var tile = stage[cell];
          if (tile.isFlyable) {
            tile.addEmanation(128);
          }
        }
      }
    }

    // TODO: Should we do a sanity check for traversable tiles that ended up
    // unreachable?

    // TODO: Use room places and themes for placing stairs.
    var stairCount = rng.range(2, 4);
    for (var i = 0; i < stairCount; i++) {
      var pos = stage.findOpenTile();
      setTileAt(pos, Tiles.stairs);
    }

    for (var place in _places) {
      // TODO: Doing this here is kind of hacky.
      rng.shuffle(place.cells);

      _placeMonsters(place);
      _placeItems(place);
    }

    // Place the hero in the starting place.
    var startPlace = _places.firstWhere((place) => place.hasHero);
    // TODO: Because every dungeon has a room biome, we assume there is a place
    // that's marked to have the hero. If that's not the case, we'll need to
    // pick a place here.

    placeHero(_tryFindSpawnPos(startPlace, Motility.walk, SpawnLocation.open,
        avoidActors: true));
  }

  Place placeAt(Vec pos) {
    if (_cells == null) return null;
    return _cells[pos];
  }

  TileType getTile(int x, int y) => stage.get(x, y).type;

  TileType getTileAt(Vec pos) => stage[pos].type;

  void setTile(int x, int y, TileType type) {
    var tile = stage.get(x, y);
    tile.type = type;
    _tileEmanation(tile);
  }

  void setTileAt(Vec pos, TileType type) {
    var tile = stage[pos];
    tile.type = type;
    _tileEmanation(tile);
  }

  void _tileEmanation(Tile tile) {
    // TODO: Move this code somewhere better.
    // Water has occasional sparkles.
    if (tile.type == Tiles.water && rng.percent(2)) {
      tile.addEmanation(Lighting.emanationForLevel(5));
    }
  }

  bool isRock(int x, int y) => stage.get(x, y).type == Tiles.rock;

  bool isRockAt(Vec pos) => stage[pos].type == Tiles.rock;

  /// Returns `true` if the cell at [pos] has at least one adjacent tile with
  /// type [tile].
  bool hasCardinalNeighbor(Vec pos, List<TileType> tiles) {
    for (var neighbor in pos.cardinalNeighbors) {
      if (!safeBounds.contains(neighbor)) continue;

      if (tiles.contains(stage[neighbor].type)) return true;
    }

    return false;
  }

  /// Returns `true` if the cell at [pos] has at least one adjacent tile with
  /// type [tile].
  bool hasNeighbor(Vec pos, TileType tile) {
    for (var neighbor in pos.neighbors) {
      if (!safeBounds.contains(neighbor)) continue;

      if (stage[neighbor].type == tile) return true;
    }

    return false;
  }

  void addPlace(Place place) {
    _places.add(place);
    place.bind(this);

    for (var cell in place.cells) {
      assert(_cells[cell] == null, "Places should not overlap.");
      _cells[cell] = place;
    }
  }

  void _findConnections(Dungeon dungeon, List<Place> places) {
    // Find adjacent places.
    for (var pos in dungeon.safeBounds) {
      var from = _cells[pos];
      if (from == null) continue;

      for (var neighbor in pos.cardinalNeighbors) {
        var to = _cells[neighbor];
        if (to != null && to != from) {
          from.neighbors.add(to);
          to.neighbors.add(from);
        }
      }
    }
  }

  void spreadTheme(Place start, String theme, double strength) {
    var visited = {start: strength};
    var queue = Queue<Place>();
    queue.add(start);

    while (queue.isNotEmpty) {
      var here = queue.removeFirst();
      // TODO: Attenuate less based on place size or type? It might be nice if
      // passages didn't attenuate as much as rooms.
      var strength = visited[here] / 2.0;
      if (strength < 0.3) continue;

      for (var neighbor in here.neighbors) {
        if (visited.containsKey(neighbor)) continue;

        neighbor.themes.putIfAbsent(theme, () => 0.0);
        neighbor.themes[theme] += strength;
        neighbor.totalStrength += strength;

        visited[neighbor] = strength;
        queue.add(neighbor);
      }
    }
  }

  void _placeMonsters(Place place) {
    // Don't spawn monsters in the hero's starting room.
    if (place.hasHero) return;

    var spawnCount = _rollCount(place, place.monsterDensity);
    while (spawnCount > 0) {
      var theme = place.chooseTheme();
      var breed = Monsters.breeds.tryChoose(depth, theme);

      // Don't place dead or redundant uniques.
      if (breed.flags.unique) {
        if (_lore.slain(breed) > 0) continue;
        if (_spawnedUniques.contains(breed)) continue;

        _spawnedUniques.add(breed);
      }

      var spawned = _spawnMonster(place, breed);

      // Stop if we ran out of open tiles.
      if (spawned == null) break;

      spawnCount -= spawned;
    }
  }

  void _placeItems(Place place) {
    var density = place.itemDensity;

    // Increase the odds of the hero immediately finding something.
    if (place.hasHero) density *= 1.2;

    var dropCount = _rollCount(place, density);
    for (var i = 0; i < dropCount; i++) {
      var theme = place.chooseTheme();

      var floorDrop = FloorDrops.choose(theme, depth);
      var pos = _tryFindSpawnPos(place, Motility.walk, floorDrop.location,
          avoidActors: false);
      if (pos == null) break;

      stage.placeDrops(pos, Motility.walk, floorDrop.drop);
    }
  }

  /// Rolls how many of something should be dropped in [place], taking the
  /// place's size and [density] into account.
  int _rollCount(Place place, double density) {
    // TODO: Tune based on depth?
    // Calculate the average number of monsters for a place with this many
    // cells.
    //
    // We want a roughly even difficulty across places of different sizes. That
    // means more monsters in bigger places. However, monsters can easily cross
    // an open space which means scaling linearly makes larger places more
    // difficult -- it's easy for the hero to get swarmed. The exponential
    // tapers that off a bit so that larger areas don't scale quite linearly.
    var base = math.pow(place.cells.length, 0.80) * density;

    // From the average, roll an actual number using a normal distribution
    // centered on the base number. The distribution gets wider as the base
    // gets larger.
    return rng.countFromFloat(base + rng.normal() * (base / 2));
  }

  int _spawnMonster(Place place, Breed breed) {
    var pos = _tryFindSpawnPos(place, breed.motility, breed.location,
        avoidActors: true);

    // If there are no remaining open tiles, abort.
    if (pos == null) return null;

    var isCorpse = rng.oneIn(8);
    var breeds = breed.spawnAll();

    var spawned = 0;
    spawn(Breed breed, Vec pos) {
      if (isCorpse) {
        stage.placeDrops(pos, breed.motility, breed.drop);
      } else {
        stage.addActor(breed.spawn(stage.game, pos));
        spawned++;
      }

      if (breed.stain != null) {
        // TODO: Larger stains for stronger monsters?
        _stain(breed.stain, pos, 5, 2);
      }
    }

    // TODO: Hack. Flow doesn't include the starting tile, so handle it here.
    spawn(breeds[0], pos);

    for (var breed in breeds.skip(1)) {
      // TODO: Hack. Need to create a new flow each iteration because it doesn't
      // handle actors being placed while the flow is being used -- it still
      // thinks those tiles are available. Come up with a better way to place
      // the monsters.
      var flow = MotilityFlow(stage, pos, breed.motility);

      // TODO: Ideally, this would follow the location preference of the breed
      // too, even for minions of different breeds.
      var here = flow.reachable.firstWhere((_) => true, orElse: () => null);

      // If there are no open tiles, discard the remaining monsters.
      if (here == null) break;

      spawn(breed, here);
    }

    return spawned;
  }

  Vec _tryFindSpawnPos(Place place, Motility motility, SpawnLocation location,
      {bool avoidActors}) {
    int minWalls;
    int maxWalls;

    switch (location) {
      case SpawnLocation.anywhere:
        minWalls = 0;
        maxWalls = 8;
        break;

      case SpawnLocation.wall:
        minWalls = 3;
        maxWalls = 8;
        break;

      case SpawnLocation.corner:
        minWalls = 4;
        maxWalls = 8;
        break;

      case SpawnLocation.open:
        minWalls = 0;
        maxWalls = 0;
        break;
    }

    Vec acceptable;
    for (var pos in place.cells) {
      if (!getTileAt(pos).canEnter(motility)) continue;

      if (stage.actorAt(pos) != null) continue;

      var wallCount = pos.neighbors
          .where((neighbor) => !getTileAt(neighbor).isWalkable)
          .length;

      if (wallCount >= minWalls && wallCount <= maxWalls) return pos;

      // This position isn't ideal, but if we don't find anything else, we'll
      // settle for it.
      acceptable = pos;
    }

    return acceptable;
  }

  void _stain(TileType tile, Vec start, int distance, int count) {
    // Make a bunch of wandering paths from the starting point, leaving stains
    // as they go.
    for (var i = 0; i < count; i++) {
      var pos = start;
      for (var j = 0; j < distance; j++) {
        if (rng.percent(60) && getTileAt(pos) == Tiles.floor) {
          setTileAt(pos, tile);
        }

        var dirs = Direction.all
            .where((dir) => getTileAt(pos + dir).isTraversable)
            .toList();
        if (dirs.isEmpty) return;
        pos += rng.item(dirs);
      }
    }
  }

  void _chooseBiomes() {
    // TODO: Take depth into account.
    var hasWater = _tryRiver();

    if (_tryLake64(hasWater)) hasWater = true;
    if (_tryLake32(hasWater)) hasWater = true;
    if (_tryLakes16(hasWater)) hasWater = true;

    _biomes.add(RoomsBiome(this));
  }

  bool _tryRiver() {
    if (!rng.oneIn(3)) return false;

    _biomes.add(RiverBiome(this));
    return true;
  }

  bool _tryLake64(bool hasWater) {
    if (width <= 64 || height <= 64) return false;

    var odds = hasWater ? 20 : 10;
    if (!rng.oneIn(odds)) return false;

    // TODO: 64 is pretty big. Might want to make these a little smaller, but
    // not all the way down to 32.
    _biomes.add(LakeBiome(this, Blob.make(64)));
    return true;
  }

  bool _tryLake32(bool hasWater) {
    if (width <= 32 || height <= 32) return false;

    var odds = hasWater ? 10 : 5;
    if (!rng.oneIn(odds)) return false;

    _biomes.add(LakeBiome(this, Blob.make(32)));
    return true;
  }

  bool _tryLakes16(bool hasWater) {
    if (!rng.oneIn(5)) return false;

    var ponds = rng.taper(0, 3);
    for (var i = 0; i < ponds; i++) {
      _biomes.add(LakeBiome(this, Blob.make(16)));
    }

    return true;
  }
}
