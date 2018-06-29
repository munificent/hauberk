/*
import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';

class _Region {
  final int id;
  // TODO: Do we actually need the set of tiles?
  final Set<Vec> tiles = new Set();
  final Set<_Junction> junctions = new Set();

  _Region(this.id);
}

class _Junction {
  final int id;
  final Vec position;
  final Set<_Region> regions = new Set();

  _Junction(this.id, this.position);
}

/// Calculates the "choke points" in the dungeon.
///
/// These are junctions that, relative to the starting point, provide the only
/// access to an area of the dungeon. This finds all of the choke points and
/// records how many tiles are only accessible by going through each one.
///
/// The basic algorithm is:
///
/// - Create a graph where each vertex is a region of connected tiles and each
///   edge is a junction tile (door) that separates them.
/// - Repeatedly do depth-first traversals of the graph looking for a cycle.
///   When found, merge all regions in the cycle into one and remove the
///   junctions between them.
/// - When no more cycles are found, the graph is now a tree where each region
///   can only be accessed by going through a single junction.
/// - Walk the tree from the region where the hero starts. Do a post-order
///   calculation of the number of tiles accessible by each junction and record
///   that in the dungeon's tile info.
// TODO: Look up "Tarjan's bridge-finding algorithm".
class ChokePoints {
  final Dungeon _dungeon;
  final Array2D<int> _cells;
  final _junctions = <int, _Junction>{};
  final _regions = <int, _Region>{};

  ChokePoints(this._dungeon)
      : _cells = new Array2D(_dungeon.width, _dungeon.height, 0);

  void calculate(Vec heroPos) {
    // Find the junctions and clear the regions.
    for (var pos in _dungeon.safeBounds) {
      var tile = _dungeon.getTileAt(pos);
      if (!tile.isTraversable) continue;

      if (tile == Tiles.closedDoor) {
        var id = -(_junctions.length + 1);
        _junctions[id] = new _Junction(id, pos);
        _cells[pos] = id;
      } else {
        _cells[pos] = null;
      }
    }

    // Calculate the connected regions.
    _Region startRegion;
    for (var start in _dungeon.safeBounds) {
      if (_cells[start] != null) continue;

      var queue = new Queue<Vec>();
      queue.add(start);

      var region = new _Region(_regions.length + 1);
      _regions[region.id] = region;
      region.tiles.add(start);

      if (start == heroPos) startRegion = region;

      while (queue.isNotEmpty) {
        var pos = queue.removeFirst();

        for (var dir in Direction.all) {
          var neighbor = pos + dir;

          var cell = _cells[neighbor];
          if (cell == null) {
            // Open cell, add it to the region.
            _cells[neighbor] = region.id;
            region.tiles.add(neighbor);
            queue.add(neighbor);

            if (neighbor == heroPos) startRegion = region;
          } else if (cell < 0) {
            // Junction cell, connect it to the region.
            var junction = _junctions[cell];
            junction.regions.add(region);
            region.junctions.add(junction);
          } else {
            // Either hit a wall or a tile already in this region, do nothing.
          }
        }
      }
    }

    // It's possible the dungeon to generate junctions that connect to the same
    // region -- for example, a door between two rooms that both open onto a
    // shore. Clean those up first.
    _pruneJunctions();

    assert(startRegion != null);

    // Merge every cycle we can find. When this is done, we'll be left with a
    // tree of regions, each of which is only reachable from a single junction.
    while (_mergeCycle([startRegion], null)) {}

    for (var pos in _dungeon.bounds) {
      var cell = _cells[pos];
      var info = _dungeon.infoAt(pos);

      if (cell == null) {
      } else if (cell > 0) {
        info.regionId = cell;
      } else if (cell < 0) {
        info.junctionId = -1 - cell;
      }
    }

    _markJunctions(startRegion, []);
  }

  int _markJunctions(_Region region, List<_Region> visited) {
    visited.add(region);

    var allTiles = 0;
    for (var junction in region.junctions) {
      var other = junction.regions.where((r) => r != region).single;
      if (visited.contains(other)) continue;

      var tiles = other.tiles.length + _markJunctions(other, visited);

      allTiles += tiles;
      _dungeon.infoAt(junction.position).reachableTiles = tiles;

      for (var tile in other.tiles) {
        _dungeon.infoAt(tile).chokePoint = junction.position;
      }
    }

    visited.removeLast();
    return allTiles;
  }

  /// Performs a depth-first search over the graph of regions. If a cycle is
  /// detected by hitting a previously visited region, merges all regions
  /// in the cycle into a single region and returns `true`.
  bool _mergeCycle(List<_Region> stack, _Junction incomingJunction) {
    var region = stack.last;
    for (var junction in region.junctions) {
      if (junction == incomingJunction) continue;

      var other = junction.regions.where((r) => r != region).single;

      var backIndex = stack.indexOf(other);
      if (backIndex != -1) {
        var cycle = stack.sublist(backIndex);
        for (var i = 1; i < cycle.length; i++) {
          _merge(cycle[0], cycle[i]);
        }
        return true;
      }

      stack.add(other);
      var hadCycle = _mergeCycle(stack, junction);
      stack.removeLast();
      if (hadCycle) return true;
    }

    return false;
  }

  // Merge [b] into [a].
  void _merge(_Region a, _Region b) {
    // TODO: Temp. Just to visualize that the regions are merged.
    for (var pos in b.tiles) {
      _cells[pos] = a.id;
    }

    // Copy [b]'s tiles and junctions over.
    a.tiles.addAll(b.tiles);
    a.junctions.addAll(b.junctions);

    // Find every reference to [b] in a junction and change it to [a].
    for (var junction in _junctions.values.toList()) {
      var regions = junction.regions.map((r) => r == b ? a : r).toSet();
      junction.regions.clear();
      junction.regions.addAll(regions);
    }

    _pruneJunctions();
  }

  /// Discards any junctions that no longer connect separate regions.
  void _pruneJunctions() {
    var junctions = _junctions.values
        .where((junction) => junction.regions.length <= 1)
        .toList();

    // Remove any junctions that don't connect multiple regions.
    for (var junction in junctions) {
      _cells[junction.position] = null;
      _junctions.remove(junction.id);
    }

    // Remove references to them in regions.
    for (var region in _regions.values) {
      region.junctions.removeAll(junctions);
    }
  }
}
*/