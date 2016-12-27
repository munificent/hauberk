import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'affixes.dart';
import 'items.dart';

Drop parseDrop(String name, [int level]) {
  if (level == null) return _itemDrop(name);

  var tag = Items.tags[name];
  if (tag == null) throw 'Could not find tag "$name".';
  return new _TagDrop(tag, level);
}

/// Creates a single drop [Rarity].
Rarity rarity(int rarity, String name, [int level]) {
  return new Rarity(rarity, parseDrop(name, level));
}

/// Creates a [Drop] that has a [chance]% chance of dropping [drop].
Drop percent(int chance, drop, [int level]) {
  return new _PercentDrop(chance, parseDrop(drop, level));
}

/// Creates a [Drop] that drops all of [drops].
Drop dropAllOf(List<Drop> drops) => new _AllOfDrop(drops);

/// Creates a [Drop] that has a chance to drop one of [drops] each with its
/// own [Frequency].
Drop dropOneOf(List<Rarity> drops) => new _RarityDrop(drops);

Drop repeatDrop(int count, Drop drop) => new _RepeatDrop(count, drop);

/// A rarity for a single case in a [_RarityDrop].
///
/// This determines how rare a drop is relative to other cases in the drop. A
/// rarity of five means other drops are five times more common that this one.
///
/// Frequency and rarity are inverses of each other. If one case becomes more
/// rare, that's equivalent to the frequencies of all other drops increasing.
class Rarity {
  final int _rarity;
  final Drop _drop;

  /// The inverse of [_rarity]. Calculated by [_RarityDrop].
  int _frequency = 1;

  Rarity(this._rarity, this._drop);
}

Drop _itemDrop(String name) {
  var itemType = Items.all[name];
  if (itemType == null) throw 'Could not find item type "$name".';

  // See if the item is in a group.
  return new _ItemDrop(itemType);
}

/// Drops an item of a given type.
class _ItemDrop implements Drop {
  final ItemType _type;

  _ItemDrop(this._type);

  void spawnDrop(AddItem addItem) {
    addItem(Affixes.createItem(_type));
  }
}

/// Drops a randomly selected item near a level with a given tag.
class _TagDrop implements Drop {
  /// The tag to choose from.
  final Tag _tag;

  /// The average depth of the drop.
  final int _depth;

  _TagDrop(this._tag, this._depth);

  void spawnDrop(AddItem addItem) {
    // TODO: Instead of downcast, make Tagged generic?
    var itemType = _tag.choose(_depth, Items.all.values) as ItemType;
    if (itemType == null) return;

    // TODO: Item rarity?

    // Compare the item's actual level to the original desired level. If the
    // item is below that level, it increases the chances of an affix. (A weaker
    // item deeper in the dungeon is more likely to be magic.) Likewise, an
    // already-out-of-depth item is less likely to also be special.
    var depthOffset = itemType.depth - _depth;

    addItem(Affixes.createItem(itemType, depthOffset));
  }
}

/// Chooses a single [Drop] from a list of possible options with a rarity for
/// each.
class _RarityDrop implements Drop {
  final List<Rarity> _drops;

  int _total;

  _RarityDrop(this._drops) {
    // Convert rarity to frequency by using each drop's rarity to increase the
    // frequency of all of the others.
    for (var drop in _drops) {
      for (var other in _drops) {
        if (other == drop) continue;
        other._frequency *= drop._rarity;
      }
    }

    _total = _drops.fold(0, (total, drop) => total + drop._frequency);
  }

  void spawnDrop(AddItem addItem) {
    var roll = rng.range(_total);

    for (var i = 0; i < _drops.length; i++) {
      roll -= _drops[i]._frequency;
      if (roll < 0) {
        _drops[i]._drop.spawnDrop(addItem);
        return;
      }
    }
  }
}

/// A [Drop] that will create an inner drop some random percentage of the time.
class _PercentDrop implements Drop {
  final int _chance;
  final Drop _drop;

  _PercentDrop(this._chance, this._drop);

  void spawnDrop(AddItem addItem) {
    if (rng.range(100) >= _chance) return;
    _drop.spawnDrop(addItem);
  }
}

/// A [Drop] that drops all of a list of child drops.
class _AllOfDrop implements Drop {
  final List<Drop> _drops;

  _AllOfDrop(this._drops);

  void spawnDrop(AddItem addItem) {
    for (var drop in _drops) drop.spawnDrop(addItem);
  }
}

/// A [Drop] that drops a child drop more than once.
class _RepeatDrop implements Drop {
  final int _count;
  final Drop _drop;

  _RepeatDrop(this._count, this._drop);

  void spawnDrop(AddItem addItem) {
    var count = rng.triangleInt(_count, _count ~/ 2) + rng.taper(0, 5);
    for (var i = 0; i < count; i++) {
      _drop.spawnDrop(addItem);
    }
  }
}
