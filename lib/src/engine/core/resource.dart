import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'math.dart';

class ResourceSet<T> {
  final Map<String, _Tag<T>> _tags = {};
  final Map<String, _Resource<T>> _resources = {};

  // TODO: Evict old queries from the cache if it gets too large.
  final Map<_QueryKey, _ResourceQuery<T>> _queries = {};

  bool get isEmpty => _resources.isEmpty;

  bool get isNotEmpty => _resources.isNotEmpty;

  Iterable<T> get all => _resources.values.map((resource) => resource.object);

  void add(T object, {String name, int depth, double frequency, String tags}) {
    _add(object, name, depth, depth, frequency, frequency, tags);
  }

  void addRanged(T object,
      {String name,
      int start,
      int end,
      double startFrequency,
      double endFrequency,
      String tags}) {
    _add(object, name, start, end, startFrequency, endFrequency, tags);
  }

  void _add(T object, String name, int startDepth, int endDepth,
      double startFrequency, double endFrequency, String tags) {
    name ??= _resources.length.toString();
    startDepth ??= 1;
    endDepth ??= startDepth;

    startFrequency ??= 1.0;
    endFrequency ??= startFrequency;

    if (_resources.containsKey(name)) {
      throw ArgumentError('Already have a resource named "$name".');
    }

    var resource =
        _Resource(object, startDepth, endDepth, startFrequency, endFrequency);
    _resources[name] = resource;

    if (tags != null && tags != "") {
      for (var tagName in tags.split(" ")) {
        var tag = _tags[tagName];
        if (tag == null) throw ArgumentError('Unknown tag "$tagName".');
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
          tag = _Tag<T>(name, parent);
          _tags[name] = tag;
        }

        parent = tag;
      }
    }
  }

  /// Returns the resource with [name].
  T find(String name) {
    var resource = _resources[name];
    if (resource == null) throw ArgumentError('Unknown resource "$name".');
    return resource.object;
  }

  /// Returns the resource with [name], if any, or else `null`.
  T tryFind(String name) {
    var resource = _resources[name];
    if (resource == null) return null;
    return resource.object;
  }

  /// Returns whether the resource with [name] has [tagName] as one of its
  /// immediate tags or one of their parents.
  bool hasTag(String name, String tagName) {
    var resource = _resources[name];
    if (resource == null) throw ArgumentError('Unknown resource "$name".');

    var tag = _tags[tagName];
    if (tag == null) throw ArgumentError('Unknown tag "$tagName".');

    return resource._tags.any((thisTag) => thisTag.contains(tag));
  }

  /// Gets the names of the tags for the resource with [name].
  Iterable<String> getTags(String name) {
    var resource = _resources[name];
    if (resource == null) throw ArgumentError('Unknown resource "$name".');
    return resource._tags.map((tag) => tag.name);
  }

  bool tagExists(String tagName) => _tags.containsKey(tagName);

  /// Chooses a random resource in [tagName] for [depth].
  ///
  /// Includes all resources of child tags of [tagName]. For example, given tag
  /// path "equipment/weapon/sword", if [tagName] is "weapon", this will permit
  /// resources tagged "weapon" or "sword", with equal probability.
  ///
  /// Resources in parent tags, or in children of those tags, are also possible,
  /// but with less probability. So in the above example, anything tagged
  /// "equipment" is included but rare. Likewise, "equipment/armor" may also
  /// show up, but is less frequent. The odds of a resource outside of [tag] or
  /// its children show up are based on the common ancestor tag that contains
  /// both [tag] and the resource. Each level of ancestry divides the chances
  /// by ten.
  ///
  /// If no tag is given, chooses from all resources based only on depth.
  ///
  /// May return `null` if there are no resources with [tag].
  T tryChoose(int depth, {String tag, bool includeParents}) {
    includeParents ??= true;

    if (tag == null) return _runQuery("", depth, (_) => 1.0);

    var goalTag = _tags[tag];
    assert(goalTag != null);

    var label = goalTag.name;
    if (!includeParents) label += " (only)";

    return _runQuery(label, depth, (resource) {
      var scale = 1.0;
      for (var thisTag = goalTag; thisTag != null; thisTag = thisTag.parent) {
        for (var resourceTag in resource._tags) {
          if (resourceTag.contains(thisTag)) return scale;
        }

        if (!includeParents) break;

        // Resources in sibling trees are included with lower probability based
        // on how far their common ancestor is. So if the goal is
        // "equipment/weapon/sword", then "equipment/weapon/dagger" has a 1/10
        // chance, and "equipment/armor" has 1/100.
        scale /= 10.0;
      }

      return 0.0;
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
      if (tag == null) throw ArgumentError('Unknown tag "$name".');
      return tag;
    });

    var tagNames = tags.toList();
    tagNames.sort();

    return _runQuery("${tagNames.join('|')} (match)", depth, (resource) {
      for (var resourceTag in resource._tags) {
        if (tagObjects.any((tag) => tag.contains(resourceTag))) return 1.0;
      }

      return 0.0;
    });
  }

  T _runQuery(String name, int depth, double scale(_Resource<T> resource)) {
    // Reuse a cached query, if possible.
    var key = _QueryKey(name, depth);
    var query = _queries[key];
    if (query == null) {
      var resources = <_Resource<T>>[];
      var chances = <double>[];
      var totalChance = 0.0;

      // Determine the weighted chance for each resource.
      for (var resource in _resources.values) {
        var chance = scale(resource);
        if (chance == 0.0) continue;

        chance *=
            resource.frequencyAtDepth(depth) * resource.chanceAtDepth(depth);

        // The depth scale is so narrow at low levels that highly out of depth
        // items can have a 0% chance of being generated due to floating point
        // rounding. Since that breaks the query chooser, and because it's a
        // little sad, always have some non-zero minimum chance.
        chance = math.max(0.0000001, chance);

        totalChance += chance;
        resources.add(resource);
        chances.add(totalChance);
      }

      query = _ResourceQuery<T>(depth, resources, chances, totalChance);
      _queries[key] = query;
    }

    return query.choose();
  }
}

class _Resource<T> {
  final T object;
  final int startDepth;
  final int endDepth;

  final double startFrequency;
  final double endFrequency;

  final Set<_Tag<T>> _tags = {};

  _Resource(this.object, this.startDepth, this.endDepth, this.startFrequency,
      this.endFrequency) {
    if (startDepth == null) throw "!";
  }

  /// The resource's frequency at [depth].
  ///
  /// Between the [startDepth] and [endDepth], this linearly interpolates
  /// between [startFrequency] and [endFrequency]. Outside of that range, it
  /// uses either the start or end.
  double frequencyAtDepth(int depth) {
    if (startDepth == endDepth) return startFrequency;
    return lerpDouble(
        depth, startDepth, endDepth, startFrequency, endFrequency);
  }

  /// Gets the probability adjustment for choosing this resource at [depth].
  ///
  /// This is based on a normal distribution, with some tweaks. Unlike the
  /// real normal distribution, this does *not* ensure that all probabilities
  /// sum to zero. We don't need to since we normalize separately.
  ///
  /// Instead, this always returns `1.0` for depths within the resource's
  /// [startDepth] and [endDepth]. On either side of that, we have a bell curve.
  /// The curve widens as you go deeper in the dungeon. This reflects the fact
  /// that encountering a depth 4 monster at depth 1 is a lot more dangerous
  /// than a depth 54 monster at depth 51.
  ///
  /// The curve is also asymmetric. It widens out more quickly on the left.
  /// This means that as you venture deeper, weaker things you've already seen
  /// "linger" and are more likely to appear than out-of-depth *stronger*
  /// things are.
  ///
  /// https://en.wikipedia.org/wiki/Normal_distribution
  double chanceAtDepth(int depth) {
    if (depth < startDepth) {
      var relative = startDepth - depth;
      var deviation = 0.6 + depth * 0.2;

      return math.exp(-0.5 * relative * relative / (deviation * deviation));
    } else if (depth > endDepth) {
      var relative = depth - endDepth;

      // As you get deeper in the dungeon, the probability curve widens so that
      // you still find weaker stuff fairly frequently.
      var deviation = 1.0 + depth * 0.1;

      return math.exp(-0.5 * relative * relative / (deviation * deviation));
    } else {
      // Within the resource's depth range.
      return 1.0;
    }
  }
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

  String toString() {
    if (parent == null) return name;
    return "$parent/$name";
  }
}

/// Uniquely identifies a query.
class _QueryKey {
  final String name;
  final int depth;

  _QueryKey(this.name, this.depth);

  int get hashCode => name.hashCode ^ depth.hashCode;

  bool operator ==(Object other) {
    var query = other as _QueryKey;
    return name == query.name && depth == query.depth;
  }

  String toString() => "$name ($depth)";
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

  void dump(_QueryKey key) {
    print(key);
    for (var i = 0; i < resources.length; i++) {
      var chance = chances[i];
      if (i > 0) chance -= chances[i - 1];
      var percent =
          (100.0 * chance / totalChance).toStringAsFixed(5).padLeft(8);
      print("$percent% ${resources[i].object}");
    }
  }
}
