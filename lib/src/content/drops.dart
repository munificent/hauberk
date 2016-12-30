import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'affixes.dart';
import 'items.dart';

Drop parseDrop(String name, [int level]) {
  var itemType = Items.types.tryFind(name);
  if (itemType != null) return new _ItemDrop(itemType);

  return new _TagDrop(name, level);
}

/// Creates a [Drop] that has a [chance]% chance of dropping [drop].
Drop percentDrop(int chance, drop, [int level]) {
  return new _PercentDrop(chance, parseDrop(drop, level));
}

/// Creates a [Drop] that drops all of [drops].
Drop dropAllOf(List<Drop> drops) => new _AllOfDrop(drops);

Drop repeatDrop(int count, drop, [int level]) {
  return new _RepeatDrop(count, parseDrop(drop, level));
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
  final String _tag;

  /// The average depth of the drop.
  final int _depth;

  _TagDrop(this._tag, this._depth);

  void spawnDrop(AddItem addItem) {
    var itemType = Items.types.tryChoose(_depth, _tag);
    if (itemType == null) return;

    // TODO: Item rarity?

    // Compare the item's actual level to the original desired level. If the
    // item is below that level, it increases the chances of an affix. (A weaker
    // item deeper in the dungeon is more likely to be magic.) Likewise, an
    // already-out-of-depth item is less likely to also be special.
    // TODO: Get this working again.
//    var depthOffset = itemType.depth - _depth;

    addItem(Affixes.createItem(itemType));
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
    var taper = 5;
    if (_count > 3) taper = 4;
    if (_count > 6) taper = 3;

    var count = rng.triangleInt(_count, _count ~/ 2) + rng.taper(0, taper);
    for (var i = 0; i < count; i++) {
      _drop.spawnDrop(addItem);
    }
  }
}
