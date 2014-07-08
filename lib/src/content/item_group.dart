library hauberk.content.item_group;

import '../engine.dart';
import '../util.dart';
import 'builder.dart';
import 'affixes.dart';

/// The root of the [ItemGroup] tree that contains all items.
final _rootGroup = new ItemGroup("item", null);

/// Maps group names to the actual group object. This lets drops refer to just
/// the short name of the group (which is assumed to be unique) instead of the
/// full path.
final _allGroups = new Map<String, ItemGroup>();

class ItemGroup {
  static void define(String name, ItemType itemType, int level) {
    _rootGroup.add(name, itemType, level);
  }

  // TODO: The ItemGroup data structures aren't really organized for efficient
  // use right now. Do something better.

  /// Finds the item group that directly contains [type], or returns `null` if
  /// the item is not in any group.
  static ItemGroup find(ItemType type) {
    return _allGroups.values.firstWhere(
        (group) => group.items.values.contains(type), orElse: () => null);
  }

  /// Finds the level of [type].
  static int findLevel(ItemType type) {
    for (var group in _allGroups.values) {
      for (var level in group.items.keys) {
        if (group.items[level] == type) return level;
      }
    }
  }

  final String name;
  final ItemGroup parent;

  /// The child groups contained within this group.
  final groups = new Map<String, ItemGroup>();

  /// The [ItemType]s that live directly in this group, keyed by their level.
  final items = new Map<int, ItemType>();

  ItemGroup(this.name, this.parent);

  /// Gets whether this group is [name], or is contained in a parent group with
  /// that name.
  bool isWithin(String name) {
    // Walk up the path looking for the name.
    var group = this;
    var child = this;
    while (group != null) {
      if (group.name == name) return true;
      group = group.parent;
    }

    return false;
  }

  /// Adds [item] to the group at [path]. Creates child groups as needed.
  void add(String path, ItemType item, int level) {
    _add(path.split("/"), item, level);
  }

  void _add(Iterable<String> path, ItemType item, int level) {
    // If we've navigated to the end of the path, add it here.
    if (path.isEmpty) {
      items[level] = item;
      return;
    }

    // Otherwise, it goes into a child group;
    var group = groups.putIfAbsent(path.first,
        () => _allGroups[path.first] = new ItemGroup(path.first, this));
    group._add(path.skip(1), item, level);
  }

  Item createItem(int level) {
    // Possibly choose from the parent group.
    if (parent != null && rng.oneIn(10)) return parent.createItem(level);

    // Possibly tweak the level.
    if (rng.oneIn(2)) {
      while (level > 1 && rng.oneIn(3)) level--;
    } else {
      while (level < 100 && rng.oneIn(2)) level++;
    }

    // Take all of the items in this group and organize them by level.
    var itemsByLevel = {};

    addGroup(ItemGroup group) {
      // Recurse into child groups.
      group.groups.values.forEach(addGroup);

      group.items.forEach((level, item) {
        var itemsAtLevel = itemsByLevel.putIfAbsent(level, () => []);
        itemsAtLevel.add(item);
      });
    }

    addGroup(this);

    // Find the greatest level at or below the target. If no levels are below
    // the target, will just pick the first level. This ensures this can always
    // find some item for the group.
    var levels = itemsByLevel.keys.toList();
    levels.sort();

    var bestLevel = levels.lastWhere((l) => l < level,
    orElse: () => levels.first);
    var items = itemsByLevel[bestLevel];

    // Note: This doesn"t distribute things very evenly. In particular, if
    // items aren"t smoothly distributed across levels, then items near gaps
    // will get picked more frequently. This isn"t a bug, but it is something
    // to keep in mind when assigning items to levels.

    // Pick one of the items at that level randomly.
    var itemType = rng.item(items);

    // TODO: Take into account out of depth items when choosing affixes.
    return Affixes.createItem(itemType);
  }

  void _dump([String indent = ""]) {
    items.forEach((level, item) {
      print("$indent$level $item");
    });

    groups.forEach((name, group) {
      print("$indent$name/");
      group._dump("$indent  ");
    });
  }
}

/// Drops a randomly chosen item near a given level from a given group within
/// the group tree. Has a chance to walk upwards and choose from a different
/// group.
///
/// To spawn a drop, first it selects a group. Normally, this will be the group
/// at the drop's path. (If the path points to a parent group, the "group"
/// will be the union of all of its children.) There is a slight chance it will
/// walk up to a parent group (recursively). For example, a
/// "equipment/armor/boots" drop will usually drop some kind of footwear, but
/// may drop any armor and has an even smaller chance of dropping any equipment.
///
/// Once the group is selected, all of the items contained in that group (and
/// any child groups) are collected and sorted by level. The level of the drop
/// is perturbed randomly, then the item nearst that level is chosen.
class GroupDrop implements Drop {
  /// The name of the group to choose from.
  final String _group;

  /// The average level of the drop.
  final int _level;

  GroupDrop(this._group, this._level);

  void spawnDrop(Game game, AddItem addItem) {
    addItem(_allGroups[_group].createItem(_level));
  }
}
