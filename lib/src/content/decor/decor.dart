import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../dungeon/dungeon.dart';
import 'aquatic.dart';
import 'builder.dart';

class Decor {
  static Decor choose(String theme) {
    if (!all.tagExists(theme)) return null;
    return all.tryChoose(1, theme);
  }

  static final ResourceSet<Decor> all = new ResourceSet();

  static void initialize() {
    // TODO: Make sure themes here line up with room themes.
    // Counters.
    category(1.0, themes: "kitchen laboratory");
    furnishing(Symmetry.mirrorHorizontal, "─┐-│╤╛", """
    ?...
    #─┐.
    #-│.
    #╤╛.
    ?...""");

    furnishing(Symmetry.mirrorHorizontal, "─┐-│╤╛", """
    ?...
    #─┐.
    #-│.
    #-│.
    #╤╛.
    ?...""");

    furnishing(Symmetry.mirrorHorizontal, "─┐-│╤╛", """
    ?...
    #─┐.
    #-│.
    #-│.
    #-│.
    #╤╛.
    ?...""");

    furnishing(Symmetry.none, "┌─┐│-", """
    .....
    .┌─┐.
    .│-│.
    ?###?""");

    furnishing(Symmetry.none, "┌─┐│-", """
    ......
    .┌──┐.
    .│--│.
    ?####?""");

    furnishing(Symmetry.none, "┌─┐│-", """
    .......
    .┌───┐.
    .│---│.
    ?#####?""");

    furnishing(Symmetry.none, "│-╞═╡", """
    ?###?
    .│-│.
    .╞═╡.
    .....""");

    furnishing(Symmetry.none, "│-╞═╡", """
    ?####?
    .│--│.
    .╞══╡.
    ......""");

    furnishing(Symmetry.none, "│-╞═╡", """
    ?#####?
    .│---│.
    .╞═══╡.
    .......""");

    // Separating counters.
    category(0.05, themes: "workshop");
    furnishing(Symmetry.none, "─┐┌╤╛╘", """
    ?.....?
    #─┐.┌─#
    #╤╛.╘╤#
    ?.....?""");

    furnishing(Symmetry.none, "─┐┌╤╛╘═", """
    ?.......?
    #──┐.┌──#
    #═╤╛.╘╤═#
    ?.......?""");

    furnishing(Symmetry.none, "─┐┌╤╛╘═", """
    ?.........?
    #───┐.┌───#
    #══╤╛.╘╤══#
    ?.........?""");

    furnishing(Symmetry.none, "│╞╡┌┐", """
    ?##?
    .││.
    .╞╡.
    ....
    .┌┐.
    .││.
    ?##?""");

    furnishing(Symmetry.none, "│╞╡┌┐", """
    ?##?
    .││.
    .││.
    .╞╡.
    ....
    .┌┐.
    .││.
    .││.
    ?##?""");

    furnishing(Symmetry.none, "│╞╡┌┐", """
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
    category(0.1, themes: "great-hall");
    furnishing(Symmetry.none, "┌─┐│-╞═╡", """
    .....
    .┌─┐.
    .│-│.
    .╞═╡.
    .....""");

    furnishing(Symmetry.none, "┌─┐│-╞═╡", """
    ......
    .┌──┐.
    .│--│.
    .╞══╡.
    ......""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
    .......
    .┌───┐.
    .│---│.
    .╘╤═╤╛.
    .......""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
    ........
    .┌────┐.
    .│----│.
    .╘╤══╤╛.
    ........""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
    .........
    .┌─────┐.
    .│-----│.
    .╘╤═══╤╛.
    .........""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
    ..........
    .┌──────┐.
    .│------│.
    .╘╤════╤╛.
    ..........""");

    furnishing(Symmetry.none, "┌─┐│-╞═╡", """
    .....
    .┌─┐.
    .│-│.
    .│-│.
    .╞═╡.
    .....""");

    furnishing(Symmetry.none, "┌─┐│-╞═╡", """
    ......
    .┌──┐.
    .│--│.
    .│--│.
    .╞══╡.
    ......""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
    .......
    .┌───┐.
    .│---│.
    .│---│.
    .╘╤═╤╛.
    .......""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
    ........
    .┌────┐.
    .│----│.
    .│----│.
    .╘╤══╤╛.
    ........""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
    .........
    .┌─────┐.
    .│-----│.
    .│-----│.
    .╘╤═══╤╛.
    .........""");

    furnishing(Symmetry.none, "┌─┐│-╘╤═╛", """
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
    category(1.0, themes: "great-hall laboratory");
    furnishing(Symmetry.mirrorBoth, "π", """
    ...
    .π.
    ..┌""");

    furnishing(Symmetry.rotate90, "π", """
    ...
    .π.
    .┌?""");

    furnishing(Symmetry.mirrorHorizontal, "π", """
    ..╞
    .π.
    ...""");

    furnishing(Symmetry.rotate90, "π", """
    ?═?
    .π.
    ...""");

    furnishing(Symmetry.none, "π", """
    ?╤?
    .π.
    ...""");

    // Candles.
    // TODO: Other themes.
    category(4.0, themes: "great-hall laboratory");
    furnishing(Symmetry.none, "i", """
    i""");

    // TODO: Other decorations on tables.

    // Barrels.
    category(1.0, themes: "kitchen larder pantry storeroom");
    furnishing(Symmetry.rotate90, "%", """
    ##
    #%""");

    furnishing(Symmetry.rotate90, "%", """
    ?.?
    .%.
    ?.?""");

    furnishing(Symmetry.rotate90, "%", """
    ###
    #%%""");

    furnishing(Symmetry.rotate90, "%", """
    ###
    #%%
    #%.""");

    furnishing(Symmetry.rotate90, "%", """
    ?##?
    .%%.
    ?..?""");

    furnishing(Symmetry.rotate90, "%", """
    ?###?
    .%%%.
    ?...?""");

    furnishing(Symmetry.rotate90, "%", """
    ?###?
    .%%%.
    ?.%.?
    ??.??""");

    // Chests.
    category(1.0, themes: "chamber closet storeroom");
    furnishing(Symmetry.rotate90, "&", """
    ##
    #&""");

    furnishing(Symmetry.rotate90, "&", """
    ?#?
    .&.
    ?.?""");

    // Fountains.
    // TODO: Can these be found anywhere else?
    category(0.03, themes: "aquatic");
    furnishing(Symmetry.none, "≈P", """
    .....
    .≈≈≈.
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, "≈P", """
    #####
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, "≈PI", """
    ##I##
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, "≈PI", """
    #I#I#
    .≈P≈.
    .≈≈≈.
    .....""");

    furnishing(Symmetry.rotate90, "≈PI", """
    ##I#I##
    .≈≈P≈≈.
    ..≈≈≈..
    ?.....?""");

    furnishing(Symmetry.rotate90, "≈Pl", """
    #######
    .l≈P≈l.
    ..≈≈≈..
    ?.....?""");

    furnishing(Symmetry.rotate90, "≈PI", """
    ##I##
    .≈≈P#
    ..≈≈I
    ?..≈#""");

    // TODO: Fireplaces for kitchens and halls.

    aquatic();
  }

  final Array2D<Cell> cells;

  Decor(this.cells);

  bool canPlace(Dungeon dungeon, Vec pos) {
    for (var y = 0; y < cells.height; y++) {
      for (var x = 0; x < cells.width; x++) {
        if (!cells
            .get(x, y)
            .meetsRequirement(dungeon.getTile(pos.x + x, pos.y + y))) {
          return false;
        }
      }
    }

    return true;
  }

  void place(Dungeon dungeon, Vec pos) {
    for (var y = 0; y < cells.height; y++) {
      for (var x = 0; x < cells.width; x++) {
        cells.get(x, y).apply(dungeon, pos.offset(x, y));
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
