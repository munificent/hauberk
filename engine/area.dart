class Area {
  final String name;
  final List<AreaLevel> levels;

  Area(this.name, this.levels);

  // TODO(bob): Get rid of content param.
  Vec makeLevel(Game game, int depth) {
    final level = game.level;

    new Dungeon(level, levels[depth].options).generate();

    final pos = level.findOpenTile();

    // TODO(bob): Temp for testing.
    final prefixType = new PowerType('Elven', 'Weapon', damage: 3, isPrefix: true);
    final suffixType = new PowerType('of Wounding', 'Weapon', damage: 6, isPrefix: false);

    for (var i = 0; i < 20; i++) {
      final type = rng.item(levels[depth].items);

      var prefix, suffix;
      if (rng.oneIn(40) && prefixType.appliesTo(type)) prefix = prefixType.spawn();
      if (rng.oneIn(40) && suffixType.appliesTo(type)) suffix = suffixType.spawn();

      final item = new Item(type, level.findOpenTile(),
          prefix, suffix);

      if (prefix != null || suffix != null) print(item.toString());
      level.items.add(item);
    }

    for (int i = 0; i < 30; i++) {
      final pos = level.findOpenTile();

      // TODO(bob): Sometimes generate out-of-depth monsters.
      final monster = rng.item(levels[depth].breeds).spawn(game, pos);
      level.actors.add(monster);
    }

    /*
    for (final pos in level.bounds) {
      level[pos]._explored = true;
    }
    */
    // End temp.

    return level.findOpenTile();
  }
}

/// Describes one level in a [Area]. When the [Hero] enters a [Level] for an
/// area, this determines how that specific level is generated.
class AreaLevel {
  final DungeonOptions options;
  final List<Breed> breeds;
  final List<ItemType> items;

  AreaLevel(this.options, this.breeds, this.items);
}