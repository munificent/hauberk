class Area {
  final String name;
  final List<Level> levels;

  Area(this.name, this.levels);

  Vec buildStage(Game game, int depth) {
    final stage = game.stage;
    final area = levels[depth];

    area.builder(stage);

    final heroPos = stage.findOpenTile();
    _calculateDistances(stage, heroPos);

    /*
    // TODO(bob): Temp for testing.
    final prefixType = new PowerType('Elven', 'Weapon', damage: 3, isPrefix: true);
    final suffixType = new PowerType('of Wounding', 'Weapon', damage: 6, isPrefix: false);
    */

    // Place the items.
    final numItems = rng.taper(area.numItems, 3);
    for (var i = 0; i < numItems; i++) {
      final itemDepth = pickDepth(depth);
      final drop = levels[itemDepth].floorDrop;

      drop.spawnDrop(game, (Item item) {
        item.pos = stage.findOpenTile();
        stage.items.add(item);
      });

      /*
      var prefix, suffix;
      if (rng.oneIn(40) && prefixType.appliesTo(type)) prefix = prefixType.spawn();
      if (rng.oneIn(40) && suffixType.appliesTo(type)) suffix = suffixType.spawn();

      final item = new Item(type, stage.findOpenTile(),
          prefix, suffix);

      if (prefix != null || suffix != null) print(item.toString());
      stage.items.add(item);
      */
    }

    // Place the monsters.
    final numMonsters = rng.taper(area.numMonsters, 3);
    for (int i = 0; i < numMonsters; i++) {
      final monsterDepth = pickDepth(depth);

      // Place strong monsters farther from the hero.
      var tries = 1;
      if (monsterDepth > depth) tries = 1 + (monsterDepth - depth) * 2;
      final pos = stage.findDistantOpenTile(tries);

      final breed = rng.item(levels[monsterDepth].breeds);
      stage.spawnMonster(breed, pos);
    }

    area.quest.generate(stage);

    return heroPos;
  }

  int pickDepth(int depth) {
    while (rng.oneIn(4) && depth > 0) depth--;
    while (rng.oneIn(6) && depth < levels.length - 1) depth++;

    return depth;
  }

  /// Selects a random [Breed] for the appropriate depth in this Area. Will
  /// occasionally select out-of-depth breeds.
  Breed pickBreed(int depth) {
    if (rng.oneIn(2)) {
      while (rng.oneIn(2) && depth > 0) depth--;
    } else {
      while (rng.oneIn(4) && depth < levels.length - 1) depth++;
    }

    return rng.item(levels[depth].breeds);
  }

  /// Run Dijkstra's algorithm to calculate the distance from every reachable
  /// tile to the [Hero]. We will use this to place better and stronger things
  /// farther from the Hero. Re-uses the scent data as a convenient buffer for
  /// this.
  void _calculateDistances(Stage stage, Vec start) {
    // Clear it out.
    for (final pos in stage.bounds) stage[pos].scent2 = 9999;
    stage[start].scent2 = 0;

    final open = new Queue<Vec>();
    open.add(start);

    while (open.length > 0) {
      final start = open.removeFirst();
      final distance = stage[start].scent2;

      // Update the neighbor's distances.
      for (var dir in Direction.ALL) {
        final here = start + dir;

        // Can't reach impassable tiles.
        if (!stage[here].isTraversable) continue;

        // If we got a new best path to this tile, update its distance and
        // consider its neighbors later.
        if (stage[here].scent2 > distance + 1) {
          stage[here].scent2 = distance + 1;
          open.add(here);
        }
      }
    }
  }
}

/// Describes one level in a [Area]. When the [Hero] enters a [Level] for an
/// area, this determines how that specific level is generated.
class Level {
  final StageBuilder builder;
  final List<Breed> breeds;
  final Drop floorDrop;
  final int numMonsters;
  final int numItems;
  final Quest quest;

  Level(this.builder, this.numMonsters, this.numItems,
      this.breeds, this.floorDrop, this.quest);
}

abstract class Quest {
  // TODO(bob): Kinds of quests:
  // - Find a certain item (implemented now)
  // - Kill a certain monster
  // - Kill a certain number of monsters of a given type
  // - Get a number or set of items
  // - Explore the entire dungeon
  // - Find a certain location in the dungeon
  // - Find a certain item and use it on a certain monster
  //
  // Restrictions that can modify the above:
  // - Complete quest within a turn limit
  // - Complete quest without killing any monsters
  // - Complete quest without using any items

  abstract void generate(Stage stage);
}

class FloorItemQuest extends Quest {
  final ItemType itemType;

  FloorItemQuest(this.itemType);

  void generate(Stage stage) {
    final item = new Item(itemType);
    item.pos = stage.findDistantOpenTile(10);
    stage.items.add(item);
  }
}

/// Abstract class for a stage generator. An instance of this encapsulation
/// some dungeon generation algorithm. These are implemented in content.
typedef void StageBuilder(Stage stage);
