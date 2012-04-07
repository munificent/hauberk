/// Builder class for defining [Territory] objects.
class TerritoryBuilder extends ContentBuilder {
  final Map<String, Breed> _breeds;
  final Map<String, ItemType> _items;
  final List<Territory> _territories;

  TerritoryBuilder(this._breeds, this._items)
  : _territories = <Territory>[];

  List<Territory> build() {
    territory('Training Grounds', [
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

    return _territories;
  }

  TerritoryLevel level([List<String> breeds, List<String> items]) {
    final breedList = <Breed>[];

    for (final name in breeds) {
      breedList.add(_breeds[name]);
    }

    final itemList = <ItemType>[];

    for (final name in items) {
      itemList.add(_items[name]);
    }

    return new TerritoryLevel(breedList, itemList);
  }

  Territory territory(String name, int numLevels) {
    final territory = new Territory(name, numLevels);
    _territories.add(territory);
    return territory;
  }
}
