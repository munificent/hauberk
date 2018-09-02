import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../dungeon/dungeon.dart';
import 'aquatic.dart';
import 'decor.dart';
import 'furnishing_builder.dart';

/// A template-based decor that applies a set of tiles if it matches a set of
/// existing tiles.
class Furnishing extends Decor {
  static void initialize() {
    // TODO: Make sure themes here line up with room themes.
    // Counters.
    category(1.0, apply: "┌─┐-│╘╤═╛╞╡", themes: "kitchen laboratory");
    furnishing(Symmetry.mirrorHorizontal, """
    ?...
    #─┐.
    #-│.
    #╤╛.
    ?...""");

    furnishing(Symmetry.mirrorHorizontal, """
    ?...
    #─┐.
    #-│.
    #-│.
    #╤╛.
    ?...""");

    furnishing(Symmetry.mirrorHorizontal, """
    ?...
    #─┐.
    #-│.
    #-│.
    #-│.
    #╤╛.
    ?...""");

    furnishing(Symmetry.none, """
    .....
    .┌─┐.
    .│-│.
    ?###?""");

    furnishing(Symmetry.none, """
    ......
    .┌──┐.
    .│--│.
    ?####?""");

    furnishing(Symmetry.none, """
    .......
    .┌───┐.
    .│---│.
    ?#####?""");

    furnishing(Symmetry.none, """
    ?###?
    .│-│.
    .╞═╡.
    .....""");

    furnishing(Symmetry.none, """
    ?####?
    .│--│.
    .╞══╡.
    ......""");

    furnishing(Symmetry.none, """
    ?#####?
    .│---│.
    .╞═══╡.
    .......""");

    // Separating counters.
    category(0.05, apply: "┌─┐-│╘╤═╛╞╡", themes: "workshop");
    furnishing(Symmetry.none, """
    ?.....?
    #─┐.┌─#
    #╤╛.╘╤#
    ?.....?""");

    furnishing(Symmetry.none, """
    ?.......?
    #──┐.┌──#
    #═╤╛.╘╤═#
    ?.......?""");

    furnishing(Symmetry.none, """
    ?.........?
    #───┐.┌───#
    #══╤╛.╘╤══#
    ?.........?""");

    furnishing(Symmetry.none, """
    ?##?
    .││.
    .╞╡.
    ....
    .┌┐.
    .││.
    ?##?""");

    furnishing(Symmetry.none, """
    ?##?
    .││.
    .││.
    .╞╡.
    ....
    .┌┐.
    .││.
    .││.
    ?##?""");

    furnishing(Symmetry.none, """
    ?##?
    .││.
    .││.
    .││.
    .╞╡.
    ....
    .┌┐.
    .││.
    .││.
    .││.
    ?##?""");

    // Tables.
    category(0.1, apply: "┌─┐-│╘╤═╛╞╡", themes: "great-hall");
    furnishing(Symmetry.none, """
    .....
    .┌─┐.
    .│-│.
    .╞═╡.
    .....""");

    furnishing(Symmetry.none, """
    ......
    .┌──┐.
    .│--│.
    .╞══╡.
    ......""");

    furnishing(Symmetry.none, """
    .......
    .┌───┐.
    .│---│.
    .╘╤═╤╛.
    .......""");

    furnishing(Symmetry.none, """
    ........
    .┌────┐.
    .│----│.
    .╘╤══╤╛.
    ........""");

    furnishing(Symmetry.none, """
    .........
    .┌─────┐.
    .│-----│.
    .╘╤═══╤╛.
    .........""");

    furnishing(Symmetry.none, """
    ..........
    .┌──────┐.
    .│------│.
    .╘╤════╤╛.
    ..........""");

    furnishing(Symmetry.none, """
    .....
    .┌─┐.
    .│-│.
    .│-│.
    .╞═╡.
    .....""");

    furnishing(Symmetry.none, """
    ......
    .┌──┐.
    .│--│.
    .│--│.
    .╞══╡.
    ......""");

    furnishing(Symmetry.none, """
    .......
    .┌───┐.
    .│---│.
    .│---│.
    .╘╤═╤╛.
    .......""");

    furnishing(Symmetry.none, """
    ........
    .┌────┐.
    .│----│.
    .│----│.
    .╘╤══╤╛.
    ........""");

    furnishing(Symmetry.none, """
    .........
    .┌─────┐.
    .│-----│.
    .│-----│.
    .╘╤═══╤╛.
    .........""");

    furnishing(Symmetry.none, """
    ..........
    .┌──────┐.
    .│------│.
    .│------│.
    .╘╤════╤╛.
    ..........""");

    // TODO: More table sizes? Shapes?

    // Chairs.
    // TODO: Instead of spawning these freely, make them sub-furnishings of the
    // appropriate furnishings.
    // TODO: Other themes.
    category(1.0, apply: "π", themes: "great-hall laboratory");
    furnishing(Symmetry.mirrorBoth, """
    ...
    .π.
    ..┌""");

    furnishing(Symmetry.rotate90, """
    ...
    .π.
    .┌?""");

    furnishing(Symmetry.mirrorHorizontal, """
    ..╞
    .π.
    ...""");

    furnishing(Symmetry.rotate90, """
    ?═?
    .π.
    ...""");

    furnishing(Symmetry.none, """
    ?╤?
    .π.
    ...""");

    // Candles.
    // TODO: Other themes.
    category(4.0, apply: "i", themes: "great-hall laboratory");
    furnishing(Symmetry.none, """
    i""");

    // TODO: Other decorations on tables.

    // TODO: Some fraction of the time, should place open barrels and chests.
    // Barrels.
    category(1.0, apply: "%", themes: "kitchen larder pantry storeroom");
    furnishing(Symmetry.rotate90, """
    ##
    #%""");

    furnishing(Symmetry.rotate90, """
    ?.?
    .%.
    ?.?""");

    furnishing(Symmetry.rotate90, """
    ###
    #%%""");

    furnishing(Symmetry.rotate90, """
    ###
    #%%
    #%.""");

    furnishing(Symmetry.rotate90, """
    ?##?
    .%%.
    ?..?""");

    furnishing(Symmetry.rotate90, """
    ?###?
    .%%%.
    ?...?""");

    furnishing(Symmetry.rotate90, """
    ?###?
    .%%%.
    ?.%.?
    ??.??""");

    // Chests.
    category(1.0, apply: "&", themes: "chamber storeroom treasure-room");
    furnishing(Symmetry.rotate90, """
    ##
    #&""");

    furnishing(Symmetry.rotate90, """
    ?#?
    .&.
    ?.?""");

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

    // Streams.
    category(10.0, apply: "≈≡", themes: "aquatic");
    furnishing(Symmetry.rotate90, """
    #...#
    #≈≡≈#
    #...#""");

    furnishing(Symmetry.rotate90, """
    #....#
    #≈≈≡≈#
    #....#""");

    furnishing(Symmetry.rotate90, """
    #.....#
    #≈≈≡≈≈#
    #.....#""");

    furnishing(Symmetry.rotate90, """
    #.....#
    #≈≡≈≡≈#
    #.....#""");

    furnishing(Symmetry.rotate90, """
    #......#
    #......#
    #≈≈≡≈≈≈#
    #......#
    #......#""");

    furnishing(Symmetry.rotate90, """
    #......#
    #......#
    #≈≡≈≈≡≈#
    #......#
    #......#""");

    furnishing(Symmetry.rotate90, """
    #.......#
    #≈≈≈≡≈≈≈#
    #.......#
    #.......#""");

    furnishing(Symmetry.rotate90, """
    #.......#
    #.......#
    #≈≈≡≈≡≈≈#
    #.......#
    #.......#""");

    furnishing(Symmetry.rotate90, """
    #.......#
    #.......#
    #≈≡≈≈≈≡≈#
    #.......#
    #.......#""");

    furnishing(Symmetry.rotate90, """
    #........#
    #........#
    #≈≈≈≡≈≈≈≈#
    #........#
    #........#""");

    furnishing(Symmetry.rotate90, """
    #........#
    #........#
    #≈≈≡≈≈≡≈≈#
    #........#
    #........#""");

    furnishing(Symmetry.rotate90, """
    #.........#
    #.........#
    #≈≈≈≈≡≈≈≈≈#
    #.........#
    #.........#""");

    furnishing(Symmetry.rotate90, """
    #.........#
    #.........#
    #≈≈≡≈≈≈≡≈≈#
    #.........#
    #.........#""");

    furnishing(Symmetry.rotate90, """
    #.........#
    #.........#
    #≈≈≈≈≡≈≈≈≈#
    #≈≈≈≈≡≈≈≈≈#
    #.........#
    #.........#""");

    furnishing(Symmetry.rotate90, """
    #.........#
    #.........#
    #≈≈≡≈≈≈≡≈≈#
    #≈≈≡≈≈≈≡≈≈#
    #.........#
    #.........#""");

    // TODO: Fireplaces for kitchens and halls.

    aquatic();
  }

  final Array2D<Cell> _cells;

  Furnishing(this._cells);

  bool canPlace(Dungeon dungeon, Vec pos) {
    for (var y = 0; y < _cells.height; y++) {
      for (var x = 0; x < _cells.width; x++) {
        if (!_cells
            .get(x, y)
            .meetsRequirement(dungeon.getTile(pos.x + x, pos.y + y))) {
          return false;
        }
      }
    }

    return true;
  }

  void place(Dungeon dungeon, Vec pos) {
    for (var y = 0; y < _cells.height; y++) {
      for (var x = 0; x < _cells.width; x++) {
        _cells.get(x, y).apply(dungeon, pos.offset(x, y));
      }
    }
  }
}

class Cell {
  final TileType _apply;
  final Motility _motility;
  final List<TileType> _require = [];

  Cell(
      {TileType apply,
      Motility motility,
      TileType require,
      List<TileType> requireAny})
      : _apply = apply,
        _motility = motility {
    if (require != null) _require.add(require);
    if (requireAny != null) _require.addAll(requireAny);
  }

  bool meetsRequirement(TileType tile) {
    if (_motility != null && !tile.canEnter(_motility)) return false;
    if (_require.isNotEmpty && !_require.contains(tile)) return false;
    return true;
  }

  void apply(Dungeon dungeon, Vec pos) {
    if (_apply != null) dungeon.setTileAt(pos, _apply);
  }
}
