import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'affixes.dart';
import 'items.dart';

Drop parseDrop(String name, {int? depth, int? affixChance}) {
  // See if we're parsing a drop for a single item type.
  var itemType = Items.types.tryFind(name);
  if (itemType != null) return _ItemDrop(itemType, depth, affixChance);

  // Otherwise, it's a tag name.
  return _TagDrop(name, depth, affixChance);
}

/// Creates a [Drop] that has a [chance]% chance of dropping [drop].
Drop percentDrop(int chance, String drop, [int? depth, int? affixChance]) {
  return _PercentDrop(
      chance, parseDrop(drop, depth: depth, affixChance: affixChance));
}

/// Creates a [Drop] that drops all of [drops].
Drop dropAllOf(List<Drop> drops) => _AllOfDrop(drops);

/// Creates a [Drop] that drops one of [drops] based on their frequency.
Drop dropOneOf(Map<Drop, double> drops) => _OneOfDrop(drops);

Drop repeatDrop(int count, Object drop, [int? depth]) {
  if (drop is String) drop = parseDrop(drop, depth: depth);
  return _RepeatDrop(count, drop as Drop);
}

/// Drops an item of a given type.
class _ItemDrop implements Drop {
  final ItemType _type;

  /// The depth to use for selecting affixes.
  ///
  /// If `null`, uses the current depth when the drop is generated.
  final int? _depth;

  /// Modifier to the apply to the percent chance of adding an affix.
  final int? _affixChance;

  _ItemDrop(this._type, this._depth, this._affixChance);

  @override
  void dropItem(int depth, AddItem addItem) {
    addItem(Affixes.createItem(_type, _depth ?? depth, _affixChance));
  }
}

/// Drops a randomly selected item near a level with a given tag.
class _TagDrop implements Drop {
  /// The tag to choose from.
  final String _tag;

  /// The average depth of the drop.
  ///
  /// If `null`, uses the current depth when the drop is generated.
  final int? _depth;

  /// Modifier to the apply to the percent chance of adding an affix.
  final int? _affixChance;

  _TagDrop(this._tag, this._depth, this._affixChance);

  @override
  void dropItem(int depth, AddItem addItem) {
    var itemType = Items.types.tryChoose(_depth ?? depth, tag: _tag);
    if (itemType == null) return;

    addItem(Affixes.createItem(itemType, _depth ?? depth, _affixChance));
  }
}

/// A [Drop] that will create an inner drop some random percentage of the time.
class _PercentDrop implements Drop {
  final int _chance;
  final Drop _drop;

  _PercentDrop(this._chance, this._drop);

  @override
  void dropItem(int depth, AddItem addItem) {
    if (rng.range(100) >= _chance) return;
    _drop.dropItem(depth, addItem);
  }
}

/// A [Drop] that drops all of a list of child drops.
class _AllOfDrop implements Drop {
  final List<Drop> _drops;

  _AllOfDrop(this._drops);

  @override
  void dropItem(int depth, AddItem addItem) {
    for (var drop in _drops) {
      drop.dropItem(depth, addItem);
    }
  }
}

/// A [Drop] that drops one of a set of child drops.
class _OneOfDrop implements Drop {
  final ResourceSet<Drop> _drop = ResourceSet();

  _OneOfDrop(Map<Drop, double> drops) {
    drops.forEach((drop, frequency) {
      // TODO: Allow passing in depth?
      _drop.add(drop, frequency: frequency);
    });
  }

  @override
  void dropItem(int depth, AddItem addItem) {
    // TODO: Allow passing in depth?
    var drop = _drop.tryChoose(1);
    if (drop == null) return;

    drop.dropItem(depth, addItem);
  }
}

/// A [Drop] that drops a child drop more than once.
class _RepeatDrop implements Drop {
  final int _count;
  final Drop _drop;

  _RepeatDrop(this._count, this._drop);

  @override
  void dropItem(int depth, AddItem addItem) {
    var taper = 5;
    if (_count > 3) taper = 4;
    if (_count > 6) taper = 3;

    var count = rng.triangleInt(_count, _count ~/ 2) + rng.taper(0, taper);
    for (var i = 0; i < count; i++) {
      _drop.dropItem(depth, addItem);
    }
  }
}
