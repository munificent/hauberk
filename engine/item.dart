
/// A thing that can be picked up.
class Item extends Thing {
  final ItemType type;

  Item(this.type, Vec pos) : super(pos);

  get appearance() => type.appearance;

  bool get canEquip() => equipSlot != null;
  String get equipSlot() => type.equipSlot;

  bool get canUse() => type.use != null;

  String get nounText() => 'the ${type.name}';
  int get person() => 3;
  Gender get gender() => Gender.NEUTER;
}

typedef void ItemUse(Game game, UseAction action);

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  final String name;
  final appearance;
  final ItemUse use;

  /// The name of the [Equipment] slot that [Item]s can be placed in. If `null`
  /// then this Item cannot be equipped.
  final String equipSlot;

  ItemType(this.name, this.appearance, this.use, this.equipSlot);
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

// TODO(bob): Which collection interface should it implement?
/// The collection of wielded [Item]s held by the [Hero]. Unlike [Inventory],
/// the [Equipment] holds each Item in a categorized slot.
class Equipment implements Iterable<Item> {
  final List<String> slotTypes;
  final List<Item> slots;

  // TODO(bob): Slot types should be class-dependent.
  Equipment()
  : slotTypes = const [
      'Weapon',
      'Ring',
      'Necklace',
      'Torso',
      'Cloak',
      'Shield',
      'Helm',
      'Gloves',
      'Boots'
      ],
    slots = new List<Item>(11);

  /// Gets whether or not there is a slot to equip [item].
  bool canEquip(Item item) {
    return slotTypes.some((slot) => item.equipSlot == slot);
  }

  Item equip(Item item) {
    // TODO(bob): Need to handle multiple slots of the same type. In that case,
    // should prefer an empty slot before reusing an in-use one.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == item.equipSlot) {
        final unequipped = slots[i];
        slots[i] = item;
        return unequipped;
      }
    }

    // Should not get here.
    assert(false);
  }
}