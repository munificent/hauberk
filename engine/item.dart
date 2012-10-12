
/// A thing that can be picked up.
class Item extends Thing implements Comparable {
  final ItemType type;

  final Power prefix;
  final Power suffix;

  Item(this.type, [this.prefix, this.suffix]) : super(Vec.ZERO);

  get appearance => type.appearance;

  bool get canEquip => equipSlot != null;
  String get equipSlot => type.equipSlot;

  bool get canUse => type.use != null;
  Action use() => type.use();

  Attack get attack {
    if (type.attack == null) return null;
    return type.attack.modifyDamage(damageModifier);
  }

  int get damageModifier {
    var modifier = 0;

    if (prefix != null) modifier += prefix.damage;
    if (suffix != null) modifier += suffix.damage;

    return modifier;
  }

  /// The amount of protected provided by the item when equipped.
  int get armor => type.armor;

  String get nounText {
    final name = new StringBuffer();
    name.add('a ');

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

  int get person => 3;
  Gender get gender => Gender.NEUTER;

  int compareTo(Item other) {
    // TODO(bob): Take into account powers.
    return type.sortIndex.compareTo(other.type.sortIndex);
  }
}

typedef Action ItemUse();

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  final String name;
  final appearance;
  final int sortIndex;
  final ItemUse use;
  final Attack attack;
  final int armor;

  /// The name of the [Equipment] slot that [Item]s can be placed in. If `null`
  /// then this Item cannot be equipped.
  final String equipSlot;

  /// A more precise categorization than [equipSlot]. For example, "dagger",
  /// or "cloak". May be `null`.
  final String category;

  ItemType(this.name, this.appearance, this.sortIndex, this.use, this.equipSlot,
      this.category, this.attack, this.armor);

  String toString() => name;
}

/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is a Power.
class Power {
  final PowerType type;

  /// The damage modifier.
  final int damage;

  Power(this.type, this.damage);

  String get name => type.name;
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
abstract class ItemCollection implements Iterable<Item> {
  int get length;
  Item operator[](int index);
  Item removeAt(int index);
  bool tryAdd(Item item);
}

/// The collection of [Item]s held by an [Actor].
class Inventory implements ItemCollection {
  final List<Item> _items;
  final int capacity;

  int get length => _items.length;

  Item operator[](int index) => _items[index];

  Inventory(this.capacity)
  : _items = <Item>[];

  /// Creates a new copy of this Inventory. This is done when the [Hero] enters
  /// a [Stage] so that any inventory changes that happen in the stage are
  /// discarded if the hero dies.
  Inventory clone() {
    // TODO(bob): If items themselves ever become mutable, will need to deep
    // clone them too.
    final inventory = new Inventory(capacity);
    for (final item in this) inventory.tryAdd(item);

    return inventory;
  }

  /// Removes all items from the inventory.
  void clear() => _items.clear();

  Item removeAt(int index) {
    final item = _items[index];
    _items.removeRange(index, 1);
    return item;
  }

  bool tryAdd(Item item) {
    // TODO(bob): Merge stacks.
    if (_items.length >= capacity) return false;

    _items.add(item);
    _items.sort((a, b) => a.compareTo(b));
    return true;
  }

  Iterator<Item> iterator() => _items.iterator();
}

// TODO(bob): Which collection interface should it implement?
/// The collection of wielded [Item]s held by the [Hero]. Unlike [Inventory],
/// the [Equipment] holds each Item in a categorized slot.
class Equipment implements ItemCollection {
  final List<String> slotTypes;
  final List<Item> slots;

  Equipment()
  : slotTypes = const [
      'Weapon',
      'Bow',
      'Ring',
      'Necklace',
      'Body',
      'Cloak',
      'Shield',
      'Helm',
      'Gloves',
      'Boots'
      ],
    slots = new List<Item>(11);

  /// Gets the number of equipped item. Ignores empty slots.
  int get length {
    return slots.reduce(0, (count, item) => count + ((item == null) ? 0 : 1));
  }

  /// Gets the equipped item at the given index. Ignores empty slots.
  Item operator[](int index) {
    // Find the slot, skipping over empty ones.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slots[i] != null) {
        if (index == 0) return slots[i];
        index--;
      }
    }
  }

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

  /// Tries to add the item. This will only succeed if there is an empty slot
  /// that allows the item. Unlike [equip], this will not swap items. It is
  /// used by the [HomeScreen].
  bool tryAdd(Item item) {
    // TODO(bob): Need to handle multiple slots of the same type. In that case,
    // should prefer an empty slot before reusing an in-use one.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slotTypes[i] == item.equipSlot && slots[i] == null) {
        slots[i] = item;
        return true;
      }
    }

    return false;
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

  /// Unequips and returns the [Item] at [index].
  Item removeAt(int index) {
    // Find the slot, skipping over empty ones.
    for (var i = 0; i < slotTypes.length; i++) {
      if (slots[i] != null) {
        if (index == 0) {
          final item = slots[i];
          slots[i] = null;
          return item;
        } else {
          index--;
        }
      }
    }
  }

  Iterator<Item> iterator() {
    // TODO(bob): Would be better if empty slots were shown with a slot label.
    // Don't include empty slots.
    return slots.filter((item) => item != null).iterator();
  }
}

typedef void AddItem(Item item);

abstract class Drop {
  void spawnDrop(Game game, AddItem addItem);
}

/// A recipe defines a set of items that can be placed into the crucible and
/// transmuted into a new item.
// TODO(bob): Figure out how this works with powers.
class Recipe {
  final List<ItemType> ingredients;
  final ItemType result;

  Recipe(this.ingredients, this.result);

  /// Returns `true` if [items] are valid (but not necessarily complete)
  /// ingredients for this recipe.
  bool allows(Iterable<Item> items) => getMissingIngredients(items) != null;

  /// Returns `true` if [items] are the complete ingredients needed for this
  /// recipe.
  bool isComplete(Iterable<Item> items) {
    final missing = getMissingIngredients(items);
    return missing != null && missing.length == 0;
  }

  /// Gets the remaining ingredients needed to complete this recipe given
  /// [items] ingredients. Returns `null` if [items] contains invalid
  /// ingredients.
  List<ItemType> getMissingIngredients(Iterable<Item> items) {
    final missing = new List.from(ingredients);

    for (final item in items) {
      final found = missing.indexOf(item.type);
      if (found == -1) return null;

      // Don't allow extra copies of ingredients.
      missing.removeRange(found, 1);
    }

    return missing;
  }
}
