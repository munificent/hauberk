
/// A thing that can be picked up.
class Item extends Thing {
  final ItemType type;

  final Power prefix;
  final Power suffix;

  Item(this.type, Vec pos, this.prefix, this.suffix) : super(pos);

  get appearance() => type.appearance;

  bool get canEquip() => equipSlot != null;
  String get equipSlot() => type.equipSlot;

  bool get canUse() => type.use != null;
  Action use() => type.use();

  Attack get attack() {
    if (type.attack == null) return null;
    return new Attack(type.attack.verb, type.attack.damage + damageModifier);
  }

  int get damageModifier() {
    var modifier = 0;

    if (prefix != null) modifier += prefix.damage;
    if (suffix != null) modifier += suffix.damage;

    return modifier;
  }

  String get nounText() {
    final name = new StringBuffer();
    name.add('the ');

    if (prefix != null) {
      name.add(prefix.name);
      name.add(' ');
    }

    name.add(type.name);

    if (suffix != null) {
      name.add(' ');
      name.add(suffix.name);
    }

    if (type.attack != null) {
      name.add(' (');
      name.add(type.attack.damage + damageModifier);
      name.add(')');
    }

    return name.toString();
  }

  int get person() => 3;
  Gender get gender() => Gender.NEUTER;
}

typedef Action ItemUse();

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  final String name;
  final appearance;
  final ItemUse use;
  final Attack attack;

  /// The name of the [Equipment] slot that [Item]s can be placed in. If `null`
  /// then this Item cannot be equipped.
  final String equipSlot;

  ItemType(this.name, this.appearance, this.use, this.equipSlot, this.attack);
}

/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is a Power.
class Power {
  final PowerType type;

  /// The damage modifier.
  final int damage;

  Power(this.type, this.damage);

  String get name() => type.name;
}

/// A kind of [Power]. It has information that is common to all [Power]s of a
/// given type, an can generate specific powers of its type.
class PowerType {
  final String name;
  final List<String> equipSlots;
  final bool isPrefix;
  final int damage;

  PowerType(this.name, String equipSlots,
    [this.damage = 0, this.isPrefix = true])
  : equipSlots = equipSlots.split(' ');

  /// Returns `true` if this PowerType can be applied to an [Item] of the given
  /// [ItemType].
  bool appliesTo(ItemType type) {
    return equipSlots.indexOf(type.equipSlot) != -1;
  }

  Power spawn() {
    final damage = rng.triangleInt(damage, damage ~/ 4);
    return new Power(this, damage);
  }
}

// TODO(bob): Which collection interface should it implement?
/// The collection of [Item]s held by an [Actor].
class Inventory implements Iterable<Item> {
  final List<Item> _items;

  int get length() => _items.length;

  Item operator[](int index) => _items[index];
  void operator[]=(int index, Item value) {
    _items[index] = value;
  }

  Inventory()
  : _items = <Item>[];

  /// Creates a new copy of this Inventory. This is done when the [Hero] enters
  /// a [Level] so that any inventory changes that happen in the level are
  /// discarded if the hero dies.
  Inventory clone() {
    // TODO(bob): If items themselves ever become mutable, will need to deep
    // clone them too.
    final inventory = new Inventory();
    for (final item in this) inventory.tryAdd(item);

    return inventory;
  }

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

  /// Creates a new copy of this Equipment. This is done when the [Hero] enters
  /// a [Level] so that any inventory changes that happen in the level are
  /// discarded if the hero dies.
  Equipment clone() {
    // TODO(bob): If items themselves ever become mutable, will need to deep
    // clone them too.
    final equipment = new Equipment();
    for (var i = 0; i < slotTypes.length; i++) {
      equipment.slots[i] = slots[i];
    }

    return equipment;
  }

  /// Gets the [Item] currently equipped in [slotType], if any.
  Item find(String slotType) {
    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == slotType) {
        return slots[i];
      }
    }

    // Unknown slot.
    return null;
  }

  /// Gets whether or not there is a slot to equip [item].
  bool canEquip(Item item) {
    return slotTypes.some((slot) => item.equipSlot == slot);
  }

  /// Equips [item]. Returns the previously equipped item in that slot, if any.
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