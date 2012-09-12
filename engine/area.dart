class Area {
  final String name;
  final List<AreaLevel> levels;

  Area(this.name, this.levels);

  Vec makeLevel(Game game, int depth) {
    final level = game.level;
    final area = levels[depth];

    area.builder.generate(level);

    final heroPos = level.findOpenTile();
    _calculateDistances(level, heroPos);

    /*
    // TODO(bob): Temp for testing.
    final prefixType = new PowerType('Elven', 'Weapon', damage: 3, isPrefix: true);
    final suffixType = new PowerType('of Wounding', 'Weapon', damage: 6, isPrefix: false);
    */

    // Place the items.
    final numItems = rng.taper(area.numItems, 3);
    for (var i = 0; i < numItems; i++) {
      final itemDepth = pickDepth(depth);
      final type = rng.item(levels[itemDepth].items);
      final pos = level.findOpenTile();

      level.spawnItem(type, pos);
      /*
      var prefix, suffix;
      if (rng.oneIn(40) && prefixType.appliesTo(type)) prefix = prefixType.spawn();
      if (rng.oneIn(40) && suffixType.appliesTo(type)) suffix = suffixType.spawn();

      final item = new Item(type, level.findOpenTile(),
          prefix, suffix);

      if (prefix != null || suffix != null) print(item.toString());
      level.items.add(item);
      */
    }

    // Place the monsters.
    final numMonsters = rng.taper(area.numMonsters, 3);
    for (int i = 0; i < numMonsters; i++) {
      final monsterDepth = pickDepth(depth);

      // Place strong monsters farther from the hero.
      var tries = 1;
      if (monsterDepth > depth) tries = 1 + (monsterDepth - depth) * 2;
      final pos = findDistantTile(level, tries);

      final breed = rng.item(levels[monsterDepth].breeds);
      level.spawnMonster(breed, pos);
    }

    // Add the quest item.
    final quest = new Item(area.quest, findDistantTile(level, 10), null, null);
    level.items.add(quest);

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

  Vec findDistantTile(Level level, int tries) {
    var bestDistance = -1;
    var best;

    for (var i = 0; i < tries; i++) {
      final pos = level.findOpenTile();
      if (level[pos].scent2 > bestDistance) {
        best = pos;
        bestDistance = level[pos].scent2;
      }
    }

    return best;
  }

  /// Run Dijkstra's algorithm to calculate the distance from every reachable
  /// tile to the [Hero]. We will use this to place better and stronger things
  /// farther from the Hero. Re-uses the scent data as a convenient buffer for
  /// this.
  void _calculateDistances(Level level, Vec start) {
    // Clear it out.
    for (final pos in level.bounds) level[pos].scent2 = 9999;
    level[start].scent2 = 0;

    final open = new Queue<Vec>();
    open.add(start);

    while (open.length > 0) {
      final start = open.removeFirst();
      final distance = level[start].scent2;

      // Update the neighbor's distances.
      for (var dir in Direction.ALL) {
        final here = start + dir;

        // Can't reach impassable tiles.
        if (!level[here].isTraversable) continue;

        // If we got a new best path to this tile, update its distance and
        // consider its neighbors later.
        if (level[here].scent2 > distance + 1) {
          level[here].scent2 = distance + 1;
          open.add(here);
        }
      }
    }
  }
}

/// Describes one level in a [Area]. When the [Hero] enters a [Level] for an
/// area, this determines how that specific level is generated.
class AreaLevel {
  final LevelBuilder builder;
  final List<Breed> breeds;
  final List<ItemType> items;
  final int numMonsters;
  final int numItems;
  final ItemType quest;

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

  AreaLevel(this.builder, this.numMonsters, this.numItems,
      this.breeds, this.items, this.quest);
}