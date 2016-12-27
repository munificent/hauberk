import 'package:piecemeal/piecemeal.dart';

// TODO: Use this for ItemType too.

/// Base class for objects that are organized into a hierarchy with levels for
/// each object.
class Tagged {
  /// The object's depth.
  ///
  /// Higher depth objects are found later in the game.
  final int depth;

  final List<Tag> tags = [];

  Tagged(this.depth);

  bool hasTag(Tag tag) => tags.any((thisTag) => thisTag.hasTag(tag));
}

class Tag {
  final String name;
  final List<Tag> parents = [];

  Tag(this.name);

  bool hasTag(Tag tag) {
    if (tag == this) return true;
    return parents.any((thisTag) => thisTag.hasTag(tag));
  }

  // TODO: Make generic.
  // TODO: This is copied from _CategoryDrop. Unify them.
  Tagged choose(int depth, List<Tagged> all) {
    // Possibly choose from a parent tag.
    var tag = this;
    while (tag.parents.isNotEmpty && rng.oneIn(10)) {
      tag = rng.item(tag.parents);
    }

    var minDepth = depth ~/ 2;

    // Bell curve around goal depth.
    var before = depth;
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
            tagged.hasTag(tag))
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
}
