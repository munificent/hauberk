/// Builder class for defining [Area] objects.
class AreaBuilder extends ContentBuilder {
  final Map<String, Breed> _breeds;
  final Map<String, ItemType> _items;
  final List<Area> _areas;

  AreaBuilder(this._breeds, this._items)
  : _areas = <Area>[];

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

    final options = new DungeonOptions();

    area('Training Grounds', [
      level(options, numMonsters: 12, numItems: 8,
        breeds: [
          'white mouse',
          'sewer rat',
          'mangy cur',
          'giant slug',
          'little brown bat',
          'stray cat',
          'garden spider',
          'giant cockroach'
        ],
        items: [
          'Crusty Loaf of Bread',
          'Mending Salve',
          'Scroll of Sidestepping'
        ],
        quest: 'Magical Chalice'),
      level(options, numMonsters: 16, numItems: 9,
        breeds: [
          'wild dog',
          'giant spider',
          'doddering old mage',
          'drunken priest',
        ],
        items: [
          'Crusty Loaf of Bread',
          'Mending Salve',
          'Robe'
        ],
        quest: 'Magical Chalice'),
      level(options, numMonsters: 20, numItems: 10,
        breeds: [
          'white mouse',
          'sewer rat',
          'mangy cur',
          'giant slug',
          'little brown bat',
          'stray cat',
          'garden spider',
          'giant cockroach'
        ],
        items: [
          'Crusty Loaf of Bread',
          'Mending Salve',
          'Cudgel',
          'Dagger'
        ],
        quest: 'Magical Chalice'),
    ]);

    return _areas;
  }

  AreaLevel level(DungeonOptions options, [
      int numMonsters, int numItems, List<String> breeds, List<String> items,
      String quest]) {
    final breedList = <Breed>[];
    final itemList = <ItemType>[];

    for (final name in breeds) breedList.add(_breeds[name]);
    for (final name in items) itemList.add(_items[name]);

    return new AreaLevel(options, numMonsters, numItems, breedList, itemList,
        _items[quest]);
  }

  Area area(String name, List<AreaLevel> levels) {
    final area = new Area(name, levels);
    _areas.add(area);
    return area;
  }
}
