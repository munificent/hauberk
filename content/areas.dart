/// Builder class for defining [Area] objects.
class AreaBuilder extends ContentBuilder {
  List<Area> build() {
    /*
    // Dense, lots of little rooms.
    final options = new DungeonOptions(
      numRoomTries: 2000,
      numJunctionTries: 10,
      roomWidthMin: 3,
      roomWidthMax: 8,
      roomHeightMin: 3,
      roomHeightMax: 6,
      allowOverlapOneIn: 500,
      extraCorridorDistanceMax: 3,
      extraCorridorOneIn: 100,
      extraCorridorDistanceMultiplier: 4
    );

    // Cavernlike, lots of irregular rooms.
    final options = new DungeonOptions(
      numRoomTries: 200,
      numJunctionTries: 10,
      roomWidthMin: 3,
      roomWidthMax: 8,
      roomHeightMin: 3,
      roomHeightMax: 6,
      allowOverlapOneIn: 2,
      extraCorridorDistanceMax: 10,
      extraCorridorOneIn: 50,
      extraCorridorDistanceMultiplier: 4
    );

    // Small number of big open rooms with long corridors between them.
    final options = new DungeonOptions(
      numRoomTries: 200,
      numJunctionTries: 30,
      roomWidthMin: 3,
      roomWidthMax: 16,
      roomHeightMin: 3,
      roomHeightMax: 12,
      allowOverlapOneIn: 500,
      extraCorridorDistanceMax: 20,
      extraCorridorOneIn: 4,
      extraCorridorDistanceMultiplier: 50
    );
    */

    area('Training Grounds', [
      level(new DungeonBuilder(), numMonsters: 12, numItems: 8,
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
          'Scroll of Sidestepping'
        ],
        quest: 'Magical Chalice'),
      level(new DungeonBuilder(), numMonsters: 16, numItems: 9,
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
        quest: 'Magical Chalice'),
      level(new DungeonBuilder(), numMonsters: 20, numItems: 10,
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
        quest: 'Magical Chalice')
    ]);


    var goblinStronghold = new DungeonBuilder(
        numRoomTries: 200,
        numJunctionTries: 50,
        numRoundingTries: 800,
        roomWidthMax: 12,
        roomHeightMax: 9,
        allowOverlapOneIn: 30,
        extraCorridorOneIn: 30);
    area('Goblin Stronghold', [
      level(goblinStronghold, numMonsters: 18, numItems: 8,
        breeds: [
          'scurrilous imp',
          'impish incanter',
          'goblin peon',
          'wild dog'
        ],
        drop: [
          'Soothing Balm'
        ],
        quest: 'Magical Chalice'),
      level(goblinStronghold, numMonsters: 20, numItems: 8,
        breeds: [
          'goblin warrior'
        ],
        drop: [
          'Soothing Balm'
        ],
        quest: 'Magical Chalice')
    ]);
  }

  Level level(StageBuilder builder, [
      int numMonsters, int numItems, List<String> breeds, drop, String quest]) {
    final breedList = <Breed>[];

    for (final name in breeds) breedList.add(_breeds[name]);

    return new Level(builder, numMonsters, numItems, breedList,
        _parseDrop(drop), _items[quest]);
  }

  Area area(String name, List<Level> levels) {
    final area = new Area(name, levels);
    _areas.add(area);
    return area;
  }
}
