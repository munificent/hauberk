import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../stage/painter.dart';
import 'decor.dart';

/// A template-based decor that applies a set of tiles if it matches a set of
/// existing tiles.
class Furnishing extends Decor {
  static void initialize() {
    /*
    // Fountains.
    // TODO: Can these be found anywhere else?
    category(0.03, apply: "≈PIl", themes: "aquatic");
    furnishing(Symmetry.none, """
    .....
    .≈≈≈.
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, """
    #####
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, """
    ##I##
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, """
    #I#I#
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, """
    ##I#I##
    .≈≈P≈≈.
    ..≈≈≈..
    ?.....?""");

    furnishing(Symmetry.rotate90, """
    #######
    .l≈P≈l.
    ..≈≈≈..
    ?.....?""");

    furnishing(Symmetry.rotate90, """
    ##I##
    .≈≈P#
    ..≈≈I
    ?..≈#""");
    */

    // TODO: Fireplaces.
  }

  final Array2D<Cell> _cells;

  Furnishing(this._cells);

  @override
  bool canPlace(Painter painter, Vec pos) {
    for (var y = 0; y < _cells.height; y++) {
      for (var x = 0; x < _cells.width; x++) {
        var absolute = pos.offset(x, y);

        // Should skip these checks for cells that have no requirement.
        if (!painter.bounds.contains(absolute)) return false;
        if (!painter.ownsTile(absolute)) return false;

        if (!_cells.get(x, y).meetsRequirement(painter.getTile(absolute))) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  void place(Painter painter, Vec pos) {
    for (var y = 0; y < _cells.height; y++) {
      for (var x = 0; x < _cells.width; x++) {
        _cells.get(x, y).apply(painter, pos.offset(x, y));
      }
    }
  }
}

class Cell {
  static final uninitialized = Cell();

  final TileType? _apply;
  final Motility? _motility;
  final List<TileType> _require = [];

  Cell(
      {TileType? apply,
      Motility? motility,
      TileType? require,
      List<TileType>? requireAny})
      : _apply = apply,
        _motility = motility {
    if (require != null) _require.add(require);
    if (requireAny != null) _require.addAll(requireAny);
  }

  bool meetsRequirement(TileType tile) {
    if (_motility != null && !tile.canEnter(_motility!)) return false;
    if (_require.isNotEmpty && !_require.contains(tile)) return false;
    return true;
  }

  void apply(Painter painter, Vec pos) {
    if (_apply != null) painter.setTile(pos, _apply!);
  }
}
