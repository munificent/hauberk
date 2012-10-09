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
        quest: floorItem('Magical Chalice')),
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

  Level level(StageBuilder builder, [
      int numMonsters, int numItems, List<String> breeds, drop,
      QuestBuilder quest]) {
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

  QuestBuilder floorItem(String type) =>
      new FloorItemQuestBuilder(_items[type]);
}
