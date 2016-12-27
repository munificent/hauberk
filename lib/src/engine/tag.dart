import 'package:piecemeal/piecemeal.dart';

// TODO: Use this for ItemType too.

/// Base class for objects that are organized into a hierarchy with levels for
/// each object.
class Tagged {
  /// The object's depth.
  ///
  /// Higher depth objects are found later in the game.
  final int depth;

  final Set<Tag> tags = new Set();

  Tagged(this.depth);

  Set<Tag> get allTags {
    var tags = new Set<Tag>();
    for (var tag in this.tags) tag._addTags(tags);
    return tags;
  }

  bool hasTag(String name) => tags.any((tag) => tag.hasTag(name));
}

class Tag {
  final String name;
  final Set<Tag> parents = new Set();

  Tag(this.name);

  bool hasTag(String name) {
    if (name == this.name) return true;
    return parents.any((tag) => tag.hasTag(name));
  }

  // TODO: Make generic.
  Tagged choose(int depth, Iterable<Tagged> all) {
    // Possibly choose from a parent tag.
    var tag = this;
    while (tag.parents.isNotEmpty && rng.oneIn(10)) {
      tag = rng.item(tag.parents.toList());
    }

    var minDepth = depth ~/ 2;

    // Bell curve around goal depth.
    var width = depth ~/ 5;
    for (var i = 0; i < 3; i++) {
      depth += rng.triangleInt(0, width);
    }

    // Chance of out-of-depth items.
    if (rng.oneIn(1000)) {
      depth += rng.range(25, 100);
    } else if (rng.oneIn(100)) {
      depth += rng.range(5, 25);
    } else if (rng.oneIn(10)) {
      depth += rng.range(1, 5);
    }

    // Find all of the objects at or below the max depth and with the tag.
    var allowed = all
        .where((tagged) => tagged.depth >= minDepth &&
            tagged.depth <= depth &&
            tagged.hasTag(tag.name))
        .toList();

    // TODO: Rarity?

    if (allowed.isEmpty) return null;

    // Pick an item. Try a few times and take the best.
    var object = rng.item(allowed);
    for (var i = 0; i < 3; i++) {
      var thisObject = rng.item(allowed);
      if (thisObject.depth > object.depth) object = thisObject;
    }

    return object;
  }

  void _addTags(Set<Tag> tags) {
    if (tags.contains(this)) return;

    tags.add(this);
    for (var parent in parents) parent._addTags(tags);
  }

  String toString() => name;
}
