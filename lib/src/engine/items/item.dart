library hauberk.engine.items.item;

import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../actor.dart';
import '../attack.dart';

/// A thing that can be picked up.
class Item extends Thing implements Comparable {
  final ItemType type;

  final Affix prefix;
  final Affix suffix;

  Item(this.type, [this.prefix, this.suffix]) : super(Vec.ZERO);

  get appearance => type.appearance;

  bool get isRanged => type.attack is RangedAttack;

  bool get canEquip => equipSlot != null;
  String get equipSlot => type.equipSlot;

  bool get canUse => type.use != null;
  Action use() => type.use();

  /// Gets the melee [Attack] for the item, taking into account any [Affixes]s
  // it has.
  Attack get attack {
    if (type.attack == null) return null;

    var attack = type.attack;
    if (prefix != null) attack = prefix.modifyAttack(attack);
    if (suffix != null) attack = suffix.modifyAttack(attack);

    return attack;
  }

  /// The amount of protected provided by the item when equipped.
  int get armor => type.armor;

  String get nounText {
    final name = new StringBuffer();
    name.write('a ');

    if (prefix != null) {
      name.write(prefix.name);
      name.write(' ');
    }

    name.write(type.name);

    if (suffix != null) {
      name.write(' ');
      name.write(suffix.name);
    }

    if (attack != null) {
      name.write(' (');
      name.write(attack);
      name.write(')');
    }

    return name.toString();
  }

  int compareTo(Item other) {
    // TODO: Take into account affixes.
    return type.sortIndex.compareTo(other.type.sortIndex);
  }
}

typedef Action ItemUse();

/// A kind of [Item]. Each item will have a type that describes the item.
class ItemType {
  final String name;
  final appearance;

  /// The item's level.
  ///
  /// Higher level items are found later in the game. Some items may not have
  /// a level.
  final int level;

  final int sortIndex;

  /// The name of the [Equipment] slot that [Item]s can be placed in. If `null`
  /// then this Item cannot be equipped.
  final String equipSlot;

  final ItemUse use;

  /// The item's [Attack] or `null` if the item is not a weapon.
  final Attack attack;

  final int armor;

  /// The path to this item type in the hierarchical organization of items.
  ///
  /// May be empty for uncategorized items.
  final List<String> categories;

  /// A more precise categorization than [equipSlot]. For example, "dagger",
  /// or "cloak". May be `null`.
  String get category {
    if (categories.isEmpty) return null;
    return categories.last;
  }

  ItemType(this.name, this.appearance, this.level, this.sortIndex,
      this.categories, this.equipSlot, this.use, this.attack, this.armor);

  String toString() => name;
}

/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is an affix.
abstract class Affix {
  String get name;

  // TODO: Affix, TrainedStat, Condition and HeroClass all have this or
  // something similar. Should we have a generic interface for stuff that can
  // modify an attack?
  Attack modifyAttack(Attack attack) => attack;
}

typedef void AddItem(Item item);

abstract class Drop {
  void spawnDrop(AddItem addItem);
}
