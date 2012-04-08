class Area {
  final String name;
  final List<AreaLevel> levels;

  Area(this.name, this.levels);

  Vec makeLevel(Game game, int depth) {
    final level = game.level;
    final area = levels[depth];

    new Dungeon(level, area.options).generate();

    // TODO(bob): Temp for testing.
    final prefixType = new PowerType('Elven', 'Weapon', damage: 3, isPrefix: true);
    final suffixType = new PowerType('of Wounding', 'Weapon', damage: 6, isPrefix: false);

    // Place the items.
    final numItems = rng.taper(area.numItems, 3);
    for (var i = 0; i < numItems; i++) {
      final type = rng.item(area.items);

      var prefix, suffix;
      if (rng.oneIn(40) && prefixType.appliesTo(type)) prefix = prefixType.spawn();
      if (rng.oneIn(40) && suffixType.appliesTo(type)) suffix = suffixType.spawn();

      final item = new Item(type, level.findOpenTile(),
          prefix, suffix);

      if (prefix != null || suffix != null) print(item.toString());
      level.items.add(item);
    }

    // Place the monsters.
    final numMonsters = rng.taper(area.numMonsters, 3);
    for (int i = 0; i < numMonsters; i++) {
      final pos = level.findOpenTile();

      // TODO(bob): Sometimes generate out-of-depth monsters.
      final monster = rng.item(area.breeds).spawn(game, pos);
      level.actors.add(monster);
    }

    // Add the quest item.
    // TODO(bob): Place it far from the hero.
    final quest = new Item(area.quest, level.findOpenTile(), null, null);
    level.items.add(quest);

    print('$numItems items, $numMonsters monsters');

    /*
    for (final pos in level.bounds) {
      level[pos]._explored = true;
    }
    */

    return level.findOpenTile();
  }
}

/// Describes one level in a [Area]. When the [Hero] enters a [Level] for an
/// area, this determines how that specific level is generated.
class AreaLevel {
  final DungeonOptions options;
  final List<Breed> breeds;
  final List<ItemType> items;
  final int numMonsters;
  final int numItems;
  final ItemType quest;

  AreaLevel(this.options, this.numMonsters, this.numItems,
      this.breeds, this.items, this.quest);
}