import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

class ResourceSet<T> {
  final Map<String, _Tag<T>> _tags = {};
  final Map<String, _Resource<T>> _resources = {};

  // TODO: Evict old queries from the cache if it gets too large.
  final Map<_QueryKey, _ResourceQuery<T>> _queries = {};

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
  /// Includes all resources of child tags of [tagName]. For example, given tag
  /// path "equipment/weapon/sword", if [tagName] is "weapon", this will permit
  /// resources tagged "weapon" or "sword", but not "equipment" or other child
  /// tags of "equipment" (unless the random chance to walk up to it succeeded).
  ///
  /// There is also a random chance that this will walk "up" and include
  /// resources from a parent tag of [tagName].
  ///
  /// May return `null` if there are no resources with [tagName].
  T tryChoose(int depth, String tagName) {
    assert(tagName != null);
    var tag = _tags[tagName];
    assert(tag != null);

    // Possibly choose from a parent tag.
    while (tag.parent != null && rng.oneIn(10)) {
      tag = tag.parent;
    }

    return _runQuery(tag.name, depth, (resource) {
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

    var tagNames = tags.toList();
    tagNames.sort();

    return _runQuery("${tagNames.join('|')} (match)", depth, (resource) {
      for (var resourceTag in resource._tags) {
        if (tagObjects.any((tag) => tag.contains(resourceTag))) return true;
      }

      return false;
    });
  }

  T _runQuery(String name, int depth, bool predicate(_Resource<T> resource)) {
    // Reuse a cached query, if possible.
    var key = new _QueryKey(name, depth);
    var query = _queries[key];
    if (query == null) {
      var allowed = _resources.values.where(predicate).toList(growable: false);

      // Determine the weighted chance for each resource.
      var chances = new List<double>.filled(allowed.length, 0.0, growable: false);
      var chance = 0.0;
      for (var i = 0; i < allowed.length; i++) {
        var resource = allowed[i];
        chance += resource.frequency * _depthScale(depth, resource.depth);
        chances[i] = chance;
      }

      query = new _ResourceQuery<T>(depth, allowed, chances, chance);
      _queries[key] = query;
    }

    return query.choose();
  }

  /// Gets the probability adjustment for choosing a resource with [depth] at
  /// a goal of [targetDepth].
  ///
  /// This is based on a normal distribution, with some tweaks. Unlike the
  /// real normal distribution, this does *not* ensure that all probabilities
  /// sum to zero. We don't need to since we normalize separately.
  ///
  /// Instead, this always returns `1.0` for the most probable [depth], which is
  /// when it's equal to [targetDepth]. On either side of that, we have a bell
  /// curve. The curve widens as you go deeper in the dungeon. This reflects
  /// the fact that encountering a depth 4 monster at depth 1 is a lot more
  /// dangerous than a depth 54 monster at depth 51.
  ///
  /// The curve is also asymmetric. It widens out more quickly on the left.
  /// This means that as you venture deeper, weaker things you've already seen
  /// "linger" and are more likely to appear than out-of-depth *stronger*
  /// things are.
  ///
  /// https://en.wikipedia.org/wiki/Normal_distribution
  double _depthScale(int depth, int targetDepth) {
    var distance = (depth - targetDepth).toDouble();
    double deviation;
    if (distance <= 0.0) {
      // As you get deeper in the dungeon, the probability curve widens so that
      // you still find weaker stuff fairly frequently.
      deviation = 0.2 + targetDepth * 0.3;

      // But don't let it get *too* wide. We don't want the hero finding a lot
      // of sticks at the bottom of the dungeon.
      if (deviation > 20.0) deviation = 20.0;
    } else {
      deviation = 0.4 + targetDepth * 0.1;
    }

    return math.exp(-0.5 * distance * distance / (deviation * deviation));
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

/// Uniquely identifies a query.
class _QueryKey {
  final String name;
  final int depth;

  _QueryKey(this.name, this.depth);

  int get hashCode => name.hashCode ^ depth.hashCode;
  bool operator ==(other) {
    assert(other is _QueryKey);
    return name == other.name && depth == other.depth;
  }
}

/// A stored query that let us quickly choose a random weighted resource for
/// some given criteria.
///
/// The basic process for picking a random resource is:
///
/// 1. Find all of the resources that could be chosen.
/// 2. Calculate the chance of choosing each item.
/// 3. Pick a random number up to the total chance.
/// 4. Find the resource whose chance contains that number.
///
/// The first two steps are quite slow: they involve iterating over all
/// resources, allocating a list, etc. Fortunately, we can reuse the results of
/// them for every call to [tryChoose] or [tryChooseMatching] with the same
/// arguments.
///
/// This caches that state.
class _ResourceQuery<T> {
  final int depth;
  final List<_Resource<T>> resources;
  final List<double> chances;
  final double totalChance;

  _ResourceQuery(this.depth, this.resources, this.chances, this.totalChance);

  /// Choose a random resource that matches this query.
  T choose() {
    if (resources.isEmpty) return null;

    // Pick a point in the probability range.
    var t = rng.float(totalChance);

    // Binary search to find the resource in that chance range.
    var first = 0;
    var last = resources.length - 1;

    while (true) {
      var middle = (first + last) ~/ 2;

      if (middle > 0 && t < chances[middle - 1]) {
        last = middle - 1;
      } else if (t < chances[middle]) {
        return resources[middle].object;
      } else {
        first = middle + 1;
      }
    }
  }
}
