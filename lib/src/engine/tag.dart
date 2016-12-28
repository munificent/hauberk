import 'package:piecemeal/piecemeal.dart';

/// Base class for objects that are organized into a hierarchy with levels for
/// each object.
abstract class Tagged<T> {
  String get name;

  /// The object's depth.
  ///
  /// Higher depth objects are found later in the game.
  final int depth;

  final Set<Tag<T>> tags = new Set();

  Tagged(this.depth);

  Set<Tag<T>> get allTags {
    var tags = new Set<Tag<T>>();
    for (var tag in this.tags) tag._addTags(tags);
    return tags;
  }

  bool hasTag(String name) => tags.any((tag) => tag.contains(name));
}

class Tag<T> {
  final String name;
  final Set<Tag<T>> parents = new Set();

  Tag(this.name);

  /// Returns `true` if this tag or any of its parents (transitively) are
  /// [name].
  bool contains(String name) {
    if (name == this.name) return true;
    return parents.any((tag) => tag.contains(name));
  }

  void _addTags(Set<Tag<T>> tags) {
    if (tags.contains(this)) return;

    tags.add(this);
    for (var parent in parents) parent._addTags(tags);
  }

  String toString() => name;
}

class TagSet<T extends Tagged<T>> {
  final String _rootTagName;
  final Map<String, T> _tagged = {};
  final Map<String, Tag<T>> _tags = {};

  TagSet(String rootTag)
      : _rootTagName = rootTag {
    _tags[_rootTagName] = new Tag(_rootTagName);
  }

  Iterable<T> get all => _tagged.values;

  Tag<T> findTag(String name) {
    var tag = _tags[name];
    if (tag == null) throw new ArgumentError('Unknown tag "$name".');
    return tag;
  }

  T find(String name) {
    var element = _tagged[name];
    if (element == null) throw new ArgumentError('Unknown element "$name".');
    return element;
  }

  Tag<T> defineTag(String tagPath) {
    if (tagPath == _rootTagName) return _tags[_rootTagName];

    var parent = _tags[_rootTagName];
    Tag<T> tag;
    for (var name in tagPath.split("/")) {
      tag = _tags[name];
      if (tag == null) {
        tag = new Tag<T>(name);
        _tags[name] = tag;
      }

      tag.parents.add(parent);
      parent = tag;
    }

    return tag;
  }

  void add(T element, [String tagNames]) {
    var tags = <Tag<T>>[];
    if (tagNames == null) {
      tags.add(_tags[_rootTagName]);
    } else {
      for (var name in tagNames.split(" ")) {
        tags.add(findTag(name));
      }
    }

    element.tags.addAll(tags);
    _tagged[element.name] = element;
  }

  // TODO: This is kind of lame. Needed to disambiguate between adding to the
  // root tag from adding to no tag, but still feels odd. This only exists
  // because there are some ItemTypes that are only dropped by monsters but
  // never randomly generated. If that changes, can get rid of this.
  void addUntagged(T element) {
    _tagged[element.name] = element;
  }

  T choose(int depth, [String tagName]) {
    if (tagName == null) tagName = _rootTagName;
    var tag = _tags[tagName];
    assert(tag != null);

    // Possibly choose from a parent tag.
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
    var allowed = _tagged.values
        .where((tagged) => tagged.depth >= minDepth &&
        tagged.depth <= depth &&
        tagged.hasTag(tag.name))
        .toList();

    // TODO: Rarity?

    if (allowed.isEmpty) return null;

    // Pick an item. Try a few times and take the best.
    var object = rng.item(allowed);
    // TODO: Make tunable?
    for (var i = 0; i < 3; i++) {
      var thisObject = rng.item(allowed);
      if (thisObject.depth > object.depth) object = thisObject;
    }

    return object;
  }
}
