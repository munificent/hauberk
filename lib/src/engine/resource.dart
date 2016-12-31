import 'package:piecemeal/piecemeal.dart';

class ResourceSet<T> {
  final Map<String, _Tag<T>> _tags = {};
  final Map<String, _Resource<T>> _resources = {};

  bool get isEmpty => _resources.isEmpty;
  bool get isNotEmpty => _resources.isNotEmpty;

  Iterable<T> get all => _resources.values.map((resource) => resource.object);

  void add(String name, T object, int depth, int rarity, [String tagNames]) {
    if (_resources.containsKey(name)) {
      throw new ArgumentError('Already have a resource named "$name".');
    }

    var resource = new _Resource(object, depth, 1.0 / rarity);
    _resources[name] = resource;

    if (tagNames != null) {
      for (var tagName in tagNames.split(" ")) {
        var tag = _tags[tagName];
        if (tag == null) throw new ArgumentError('Unknown tag "$name".');
        resource._tags.add(tag);
      }
    }
  }

  /// Given a string like "a/b/c d/e" defines tags for "a", "b", "c", "d", and
  /// "e" (if not already defined) and wires them up such that "c"'s parent is
  /// "b", "b"'s is "a", and "e"'s parent is "d".
  void defineTags(String paths) {
    for (var path in paths.split(" ")) {
      _Tag<T> parent;
      _Tag<T> tag;
      for (var name in path.split("/")) {
        tag = _tags[name];
        if (tag == null) {
          tag = new _Tag<T>(name, parent);
          _tags[name] = tag;
        }

        parent = tag;
      }
    }
  }

  /// Returns the resource with [name].
  T find(String name) {
    var resource = _resources[name];
    if (resource == null) throw new ArgumentError('Unknown resource "$name".');
    return resource.object;
  }

  /// Returns the resource with [name], if any, or else `null`.
  T tryFind(String name) {
    var resource = _resources[name];
    if (resource == null) return null;
    return resource.object;
  }

  /// Gets the names of the tags for the resource with [name].
  Iterable<String> getTags(String name) {
    var resource = _resources[name];
    if (resource == null) throw new ArgumentError('Unknown resource "$name".');
    return resource._tags.map((tag) => tag.name);
  }

  /// Chooses a random resource in [tagName] for [depth].
  ///
  /// Includes all resources of child tags of [tagName]. There is also a random
  /// chance that this will walk "up" and include resources from a parent tag
  /// of [tagName].
  ///
  /// May return `null` if there are no tagged items close enough to the depth.
  T tryChoose(int depth, String tagName) {
    assert(tagName != null);
    var tag = _tags[tagName];
    assert(tag != null);

    // Possibly choose from a parent tag.
    while (tag.parent != null && rng.oneIn(10)) {
      tag = tag.parent;
    }

    return _tryChoose(depth, (resource) {
      for (var resourceTag in resource._tags) {
        if (resourceTag.contains(tag)) return true;
      }

      return false;
    });
  }

  /// Chooses a random resource at [depth] from the set of resources whose tags
  /// match at least one of [tags].
  ///
  /// For example, given tag path "equipment/weapon/sword", if [tags] is
  /// "weapon", this will permit resources tagged "weapon" or "equipment", but
  /// not "sword".
  T tryChooseMatching(int depth, Iterable<String> tags) {
    var tagObjects = tags.map((name) {
      var tag = _tags[name];
      if (tag == null) throw new ArgumentError('Unknown tag "$name".');
      return tag;
    });

    return _tryChoose(depth, (resource) {
      for (var resourceTag in resource._tags) {
        if (tagObjects.any((tag) => tag.contains(resourceTag))) return true;
      }

      return false;
    });
  }

  T _tryChoose(int depth, bool predicate(_Resource<T> resource)) {
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
    var allowed = _resources.values
        .where((resource) => resource.depth >= minDepth &&
        resource.depth <= depth &&
        predicate(resource));

    if (allowed.isEmpty) return null;

    // Determine the weighted range to choose from.
    var totalFrequency = allowed.fold(0.0,
        (frequency, resource) => frequency += resource.frequency);

    // Pick an item. Try a few times and take the best.
    var resource = _pickWeighted(allowed, totalFrequency);
    // TODO: Make tunable?
    for (var i = 0; i < 1; i++) {
      var other = _pickWeighted(allowed, totalFrequency);
      if (other.depth > resource.depth) resource = other;
    }

    return resource.object;
  }

  _Resource<T> _pickWeighted(Iterable<_Resource<T>> resources,
      double totalFrequency) {
    // Pick a point in the probability range.
    var t = rng.float(totalFrequency);

    // Find it in the weighted list.
    // TODO: Use binary search instead of linear.
    for (var resource in resources) {
      if (t < resource.frequency) return resource;

      t -= resource.frequency;
    }

    throw "Unreachable.";
  }
}

class _Resource<T> {
  final T object;
  final int depth;

  /// The reciprocal of the resource's rarity.
  final double frequency;
  final Set<_Tag<T>> _tags = new Set();

  _Resource(this.object, this.depth, this.frequency);
}

class _Tag<T> {
  final String name;
  final _Tag<T> parent;

  _Tag(this.name, this.parent);

  /// Returns `true` if this tag is [tag] or one of this tag's parents is.
  bool contains(_Tag<T> tag) {
    for (var thisTag = this; thisTag != null; thisTag = thisTag.parent) {
      if (tag == thisTag) return true;
    }

    return false;
  }
}
