
/// A thing that can be picked up.
class Item extends Thing {
  final ItemType type;

  Item(this.type, Vec pos) : super(pos);

  get appearance() => type.appearance;

  String get nounText() => 'the ${type.name}';
  int get person() => 3;
  Gender get gender() => Gender.NEUTER;
}

typedef void ItemUse(Game game, Action action);

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  final String name;
  final appearance;
  final ItemUse use;

  ItemType(this.name, this.appearance, this.use);
}

// TODO(bob): Which collection interface should it implement?
/// The collection of [Item]s held by an [Actor].
class Inventory implements Iterable<Item> {
  final List<Item> _items;

  int get length() => _items.length;

  Item operator[](int index) => _items[index];
  void operator[]=(int index, Item value) => _items[index] = value;

  Inventory()
  : _items = <Item>[];

  Item remove(int index) {
    final item = _items[index];
    _items.removeRange(index, 1);
    return item;
  }

  bool tryAdd(Item item) {
    // TODO(bob): Merge stacks.
    if (_items.length >= Option.INVENTORY_MAX_ITEMS) return false;

    _items.add(item);
    return true;
  }

  Iterator<Item> iterator() => _items.iterator();
}