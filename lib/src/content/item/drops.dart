import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'affixes.dart';
import 'items.dart';

enum ItemQuality { normal, good, great }

Drop parseDrop(String name, {int? depth, ItemQuality? quality}) {
  // See if we're parsing a drop for a single item type.
  var itemType = Items.types.tryFind(name);
  if (itemType != null) return _ItemDrop(itemType, depth, quality);

  // Otherwise, it's a tag name.
  return _TagDrop(name, depth, quality);
}

/// Creates a [Drop] that has a [chance]% chance of dropping [drop].
Drop percentDrop(int chance, String drop, {int? depth, ItemQuality? quality}) {
  return _PercentDrop(chance, parseDrop(drop, depth: depth, quality: quality));
}

/// Creates a [Drop] that drops all of [drops].
Drop dropAllOf(List<Drop> drops) => _AllOfDrop(drops);

/// Creates a [Drop] that drops one of [drops] based on their frequency.
Drop dropOneOf(Map<Drop, double> drops) => _OneOfDrop(drops);

Drop repeatDrop(int count, Object drop) {
  if (drop is String) drop = parseDrop(drop);
  return _RepeatDrop(count, drop as Drop);
}

abstract class _BaseDrop {
  /// The average depth of the drop.
  ///
  /// If `null`, uses the current depth when the drop is generated.
  final int? _depth;

  final ItemQuality _quality;

  _BaseDrop(this._depth, ItemQuality? quality)
      : _quality = quality ?? ItemQuality.normal;

  Item _makeItem(Lore? lore, int dropDepth, ItemType itemType) {
    // Only equipped items have affixes.
    if (itemType.equipSlot == null) return Item(itemType, 1);

    // TODO: If we're deeper than the item's type, then slightly boost the
    // chances of of it being something good.

    // Try to make an artifact first.
    if (lore != null) {
      var artifact = _rollArtifact(lore, itemType, dropDepth);
      if (artifact != null) return Item(itemType, 1, [artifact]);
    }

    // Otherwise, try a prefix and/or suffix.
    var prefix = _rollAffix(Affixes.prefixes, itemType, dropDepth);
    var suffix = _rollAffix(Affixes.suffixes, itemType, dropDepth);

    // Having two affixes is rarer than the odds of just generating two, since
    // it's more valuable to have two affixes on a single item slot.
    if (prefix != null && suffix != null && !rng.oneIn(4)) {
      if (rng.oneIn(2)) {
        prefix = null;
      } else {
        suffix = null;
      }
    }

    return Item(
        itemType, 1, [if (prefix != null) prefix, if (suffix != null) suffix]);
  }

  Affix? _rollArtifact(Lore lore, ItemType itemType, int depth) {
    // See if we want to make it.
    var (min, max) = switch (_quality) {
      ItemQuality.normal => (0.0001, 0.1),
      ItemQuality.good => (0.001, 0.2),
      ItemQuality.great => (0.01, 0.5),
    };

    var chance = lerpDouble(depth, 0, Option.maxDepth, min, max);
    if (rng.float(1.0) > chance) return null;

    // Try multiple times so that if we hit a previously created one, we might
    // be able to find another.
    for (var i = 0; i < 10; i++) {
      var artifact = Affixes.tryChoose(Affixes.artifacts, itemType, depth);

      // If there are no artifacts for this category, give up.
      if (artifact == null) break;

      // Don't create duplicates.
      if (lore.createdArtifact(artifact)) continue;

      lore.createArtifact(artifact);
      return artifact;
    }

    // If we got here, we failed to find an uncreated artifact for the item
    // type.
    return null;
  }

  Affix? _rollAffix(ResourceSet<Affix> affixes, ItemType itemType, int depth) {
    var (min, max) = switch (_quality) {
      ItemQuality.normal => (0.002, 0.8),
      ItemQuality.good => (0.1, 1.0),
      ItemQuality.great => (1.0, 1.0),
    };

    var chance = lerpDouble(depth, 0, Option.maxDepth, min, max);
    if (rng.float(1.0) > chance) return null;

    return Affixes.tryChoose(affixes, itemType, depth);
  }
}

/// Drops an item of a given type.
class _ItemDrop extends _BaseDrop implements Drop {
  final ItemType _type;

  _ItemDrop(this._type, super._depth, super._quality);

  @override
  void dropItem(Lore? lore, int depth, AddItem addItem) {
    addItem(_makeItem(lore, depth, _type));
  }
}

/// Drops a randomly selected item near a level with a given tag.
class _TagDrop extends _BaseDrop implements Drop {
  /// The tag to choose from.
  final String _tag;

  _TagDrop(this._tag, super._depth, super._quality);

  @override
  void dropItem(Lore? lore, int depth, AddItem addItem) {
    // Pick a random item type.
    var itemType = Items.types.tryChoose(_depth ?? depth, tag: _tag);

    // TODO: Can this happen?
    if (itemType == null) return;

    addItem(_makeItem(lore, depth, itemType));
  }
}

/// A [Drop] that will create an inner drop some random percentage of the time.
class _PercentDrop implements Drop {
  final int _chance;
  final Drop _drop;

  _PercentDrop(this._chance, this._drop);

  @override
  void dropItem(Lore? lore, int depth, AddItem addItem) {
    if (rng.range(100) >= _chance) return;
    _drop.dropItem(lore, depth, addItem);
  }
}

/// A [Drop] that drops all of a list of child drops.
class _AllOfDrop implements Drop {
  final List<Drop> _drops;

  _AllOfDrop(this._drops);

  @override
  void dropItem(Lore? lore, int depth, AddItem addItem) {
    for (var drop in _drops) {
      drop.dropItem(lore, depth, addItem);
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
  void dropItem(Lore? lore, int depth, AddItem addItem) {
    // TODO: Allow passing in depth?
    var drop = _drop.tryChoose(1);
    if (drop == null) return;

    drop.dropItem(lore, depth, addItem);
  }
}

/// A [Drop] that drops a child drop more than once.
class _RepeatDrop implements Drop {
  final int _count;
  final Drop _drop;

  _RepeatDrop(this._count, this._drop);

  @override
  void dropItem(Lore? lore, int depth, AddItem addItem) {
    var taper = 5;
    if (_count > 3) taper = 4;
    if (_count > 6) taper = 3;

    var count = rng.triangleInt(_count, _count ~/ 2) + rng.taper(0, taper);
    for (var i = 0; i < count; i++) {
      _drop.dropItem(lore, depth, addItem);
    }
  }
}
