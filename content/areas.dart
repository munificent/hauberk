part of content;

/// Builder class for defining [Area] objects.
class AreaBuilder extends ContentBuilder {
  List<Area> build() {
    trainingGrounds() => new TrainingGrounds().generate;

    area('Training Grounds', [
      level(trainingGrounds(), numMonsters: 12, numItems: 8,
        breeds: [
          'white mouse',
          'mangy cur',
          'giant slug',
          'little brown bat',
          'stray cat',
          'garden spider',
          'giant cockroach',
          'simpering knave'
        ],
        drop: [
          'Parchment',
          'Soothing Balm',
          'Scroll of Sidestepping',
          // TODO(bob): Do something better than just have them on the ground.
          'Short Bow'
        ],
        quest: kill('wild dog', 3)),
      level(trainingGrounds(), numMonsters: 16, numItems: 9,
        breeds: [
          'brown spider',
          'crow',
          'wild dog',
          'sewer rat',
          'drunken priest',
        ],
        drop: [
          'Parchment',
          'Soothing Balm',
          'Robe'
        ],
        quest: floorItem('Magical Chalice')),
      level(trainingGrounds(), numMonsters: 20, numItems: 10,
        breeds: [
          'giant spider',
          'doddering old mage',
          'raven',
          'tree snake',
          'earthworm'
        ],
        drop: [
          'Soothing Balm',
          'Cudgel',
          'Dagger'
        ],
        quest: floorItem('Magical Chalice'))
    ]);

    goblinStronghold(int depth) => new GoblinStronghold(depth).generate;

    area('Goblin Stronghold', [
      level(goblinStronghold(0), numMonsters: 18, numItems: 8,
        breeds: [
          'scurrilous imp',
          'impish incanter',
          'goblin peon',
          'wild dog'
        ],
        drop: [
          'Soothing Balm'
        ],
        quest: floorItem('Magical Chalice')),
      level(goblinStronghold(10), numMonsters: 20, numItems: 8,
        breeds: [
          'goblin warrior'
        ],
        drop: [
          'Soothing Balm'
        ],
        quest: floorItem('Magical Chalice'))
    ]);
  }

  Level level(StageBuilder builder, {
      int numMonsters, int numItems, List<String> breeds, drop,
      QuestBuilder quest}) {
    final breedList = <Breed>[];

    for (final name in breeds) breedList.add(_breeds[name]);

    return new Level(builder, numMonsters, numItems, breedList,
        _parseDrop(drop), quest);
  }

  Area area(String name, List<Level> levels) {
    final area = new Area(name, levels);
    _areas.add(area);
    return area;
  }

  QuestBuilder kill(String breed, [int count = 1]) =>
      new MonsterQuestBuilder(_breeds[breed], count);

  QuestBuilder floorItem(String type) =>
      new FloorItemQuestBuilder(_items[type]);
}

/// Builds a quest for killing a certain number of a certain [Monster].
class MonsterQuestBuilder extends QuestBuilder {
  final Breed breed;
  final int count;

  MonsterQuestBuilder(this.breed, this.count);

  Quest generate(Stage stage) {
    for (var i = 0; i < count; i++) {
      var pos = stage.findOpenTile();
      stage.spawnMonster(breed, pos);
    }

    return new MonsterQuest(breed, count);
  }
}

/// Builds a quest for finding an item on the ground in the [Stage].
class FloorItemQuestBuilder extends QuestBuilder {
  final ItemType itemType;

  FloorItemQuestBuilder(this.itemType);

  Quest generate(Stage stage) {
    final item = new Item(itemType);
    item.pos = stage.findDistantOpenTile(10);
    stage.items.add(item);

    return new ItemQuest(itemType);
  }
}

/// A quest to find an [Item] of a certain [ItemType].
class ItemQuest extends Quest {
  final ItemType itemType;

  ItemQuest(this.itemType);

  void announce(Log log) {
    // TODO(bob): Handle a/an.
    log.add("You must find a ${itemType.name}.");
  }

  bool onPickUpItem(Game game, Item item) => item.type == itemType;
}
/// A quest to kill a number of [Monster]s of a certain [Breed].
class MonsterQuest extends Quest {
  final Breed breed;
  int remaining;

  void announce(Log log) {
    // TODO(bob): Handle pluralization correctly.
    log.add("You must kill $remaining ${breed.name}s.");
  }

  MonsterQuest(this.breed, this.remaining);

  bool onKillMonster(Game game, Monster monster) {
    if (monster.breed == breed) {
      remaining--;

      if (remaining > 0) {
        // TODO(bob): Handle pluralization correctly.
        game.log.add("$remaining more ${breed.name}s await death at your hands.");
      }
    }

    return remaining <= 0;
  }
}
