/// Builder class for defining [Area] objects.
class AreaBuilder extends ContentBuilder {
  final Map<String, Breed> _breeds;
  final Map<String, ItemType> _items;
  final List<Area> _areas;

  AreaBuilder(this._breeds, this._items)
  : _areas = <Area>[];

  List<Area> build() {
    area('Training Grounds', [
      level(breeds: [
        'rat',
        'mangy cur',
        'giant slug',
        'giant dragonfly'
      ],
      items: [
        'Magical chalice',
        'Crusty Loaf of Bread',
        'Mending Salve',
        'Cudgel',
        'Dagger'
      ])
    ]);

    return _areas;
  }

  AreaLevel level([List<String> breeds, List<String> items]) {
    final breedList = <Breed>[];

    for (final name in breeds) {
      breedList.add(_breeds[name]);
    }

    final itemList = <ItemType>[];

    for (final name in items) {
      itemList.add(_items[name]);
    }

    return new AreaLevel(breedList, itemList);
  }

  Area area(String name, int numLevels) {
    final area = new Area(name, numLevels);
    _areas.add(area);
    return area;
  }
}
