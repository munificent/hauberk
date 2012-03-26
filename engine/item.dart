
/// A thing that can be picked up.
class Item extends Thing {
  final ItemType type;

  Item(this.type, Vec pos) : super(pos);

  get appearance() => type.appearance;

  String get nounText() => 'the ${type.name}';
  int get person() => 3;
  Gender get gender() => Gender.NEUTER;
}

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  final String name;
  final appearance;

  ItemType(this.name, this.appearance);
}

/// The collection of [Item]s held by an [Actor].
class Inventory {
  final List<Item> _items;

  Inventory()
  : _items = <Item>[];

  bool tryAdd(Item item) {
    // TODO(bob): Merge stacks.
    if (_items.length >= Option.INVENTORY_MAX_ITEMS) return false;

    _items.add(item);
    return true;
  }
}