import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'affixes.dart';
import 'items.dart';

Drop parseDrop(String name, int depth) {
  var itemType = Items.types.tryFind(name);
  if (itemType != null) return _ItemDrop(itemType, depth);

  return _TagDrop(name, depth);
}

/// Creates a [Drop] that has a [chance]% chance of dropping [drop].
Drop percentDrop(int chance, String drop, int depth) {
  return _PercentDrop(chance, parseDrop(drop, depth));
}

/// Creates a [Drop] that drops all of [drops].
Drop dropAllOf(List<Drop> drops) => _AllOfDrop(drops);

Drop repeatDrop(int count, drop, [int level]) {
  if (drop is String) drop = parseDrop(drop, level);
  return _RepeatDrop(count, drop);
}

/// Drops an item of a given type.
class _ItemDrop implements Drop {
  final ItemType _type;
  final int _depth;

  _ItemDrop(this._type, this._depth);

  void spawnDrop(AddItem addItem) {
    addItem(Affixes.createItem(_type, _depth));
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

    addItem(Affixes.createItem(itemType, _depth));
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
