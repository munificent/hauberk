library hauberk.engine.fov;

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';

/// Calculates the [Hero]'s field of view of the dungeon.
class Fov {
  final Game _game;

  List<_Shadow> _shadows;

  Fov(this._game);

  Stage get _stage => _game.stage;

  /// Updates the visible flags in [stage] given the [Hero]'s [pos].
  void refresh(Vec pos) {
    var numExplored = 0;

    // Sweep through the octants.
    for (var octant = 0; octant < 8; octant++) {
      numExplored += _refreshOctant(pos, octant);
    }

    // The starting position is always visible.
    if (_stage[pos].setVisible(true)) numExplored++;

    _game.hero.explore(numExplored);
  }

  int _refreshOctant(Vec start, int octant) {
    var numExplored = 0;
    var rowInc;
    var colInc;

    // Figure out which direction to increment based on the octant. Octant 0
    // starts at 12 - 2 o'clock, and octants proceed clockwise from there.
    switch (octant) {
      case 0: rowInc = new Vec(0, -1); colInc = new Vec( 1, 0); break;
      case 1: rowInc = new Vec( 1, 0); colInc = new Vec(0, -1); break;
      case 2: rowInc = new Vec( 1, 0); colInc = new Vec(0,  1); break;
      case 3: rowInc = new Vec(0,  1); colInc = new Vec( 1, 0); break;
      case 4: rowInc = new Vec(0,  1); colInc = new Vec(-1, 0); break;
      case 5: rowInc = new Vec(-1, 0); colInc = new Vec(0,  1); break;
      case 6: rowInc = new Vec(-1, 0); colInc = new Vec(0, -1); break;
      case 7: rowInc = new Vec(0, -1); colInc = new Vec(-1, 0); break;
    }

    _shadows = <_Shadow>[];

    final bounds = _stage.bounds;
    var fullShadow = false;

    // Sweep through the rows ('rows' may be vertical or horizontal based on
    // the incrementors). Start at row 1 to skip the center position.
    for (var row = 1;; row++) {
      var pos = start + (rowInc * row);

      // If we've traversed out of bounds, bail.
      // Note: this improves performance, but works on the assumption that the
      // starting tile of the FOV is in bounds.
      if (!bounds.contains(pos)) break;

      for (var col = 0; col <= row; col++) {
        var blocksLight = false;
        var visible = false;
        var projection = null;

        // If we know the entire row is in shadow, we don't need to be more
        // specific.
        if (!fullShadow) {
          blocksLight = !_stage[pos].isTransparent;
          projection = getProjection(col, row);
          visible = !_isInShadow(projection);
        }

        // Set the visibility of this tile.
        if (_stage[pos].setVisible(visible)) numExplored++;

        // Add any opaque tiles to the shadow map.
        if (blocksLight) {
          fullShadow = _addShadow(projection);
        }

        // Move to the next column.
        pos += colInc;

        // If we've traversed out of bounds, bail on this row.
        // note: this improves performance, but works on the assumption that
        // the starting tile of the FOV is in bounds.
        if (!bounds.contains(pos)) break;
      }
    }

    return numExplored;
  }

  /// Creates a [Shadow] that corresponds to the projected silhouette of the
  /// given tile. This is used both to determine visibility (if any of the
  /// projection is visible, the tile is) and to add the tile to the shadow map.
  static _Shadow getProjection(int col, int row) {
    // The bottom edge of row 0 is 1 wide.
    final rowBottomWidth = row + 1;

    // The top edge of row 0 is 2 wide.
    final rowTopWidth = row + 2;

    // Unify the bottom and top edges of the tile.
    final start = math.min(col / rowBottomWidth, col / rowTopWidth);
    final end   = math.max((col + 1) / rowBottomWidth, (col + 1) / rowTopWidth);

    return new _Shadow(start, end);
  }

  bool _isInShadow(_Shadow projection) {
    // Check the shadow list.
    for (final shadow in _shadows) {
      if (shadow.contains(projection)) return true;
    }

    return false;
  }

  bool _addShadow(_Shadow shadow) {
    var index = 0;
    for (index = 0; index < _shadows.length; index++) {
      // See if we are at the insertion point for this shadow.
      if (_shadows[index].start > shadow.start) {
        // Break out and handle inserting below.
        break;
      }
    }

    // The new shadow is going here. See if it overlaps the previous or next.
    var overlapsPrev = ((index > 0) && (_shadows[index - 1].end > shadow.start));
    var overlapsNext = ((index < _shadows.length) && (_shadows[index].start < shadow.end));

    // Insert and unify with overlapping shadows.
    if (overlapsNext) {
      if (overlapsPrev) {
        // Overlaps both, so unify one and delete the other.
        _shadows[index - 1].end =
            math.max(_shadows[index - 1].end, _shadows[index].end);
        _shadows.removeAt(index);
      } else {
        // Just overlaps the next shadow, so unify it with that.
        _shadows[index].start = math.min(_shadows[index].start, shadow.start);
      }
    } else {
      if (overlapsPrev) {
        // Just overlaps the previous shadow, so unify it with that.
        _shadows[index - 1].end = math.max(_shadows[index - 1].end, shadow.end);
      } else {
        // Does not overlap anything, so insert.
        _shadows.insert(index, shadow);
      }
    }

    // See if we are now shadowing everything.
    return (_shadows.length == 1) &&
           (_shadows[0].start == 0) &&
           (_shadows[0].end == 1);
  }
}

/// Represents the 1D projection of a 2D shadow onto a normalized line. In
/// other words, a range from 0.0 to 1.0.
class _Shadow {
  num start;
  num end;

  _Shadow(this.start, this.end);

  String toString() => '($start-$end)';

  bool contains(_Shadow projection) {
    return (start <= projection.start) && (end >= projection.end);
  }
}