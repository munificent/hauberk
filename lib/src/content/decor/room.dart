import '../tiles.dart';
import 'furnishing_builder.dart';

void roomDecor() {
  var tableCells = {
    "┌": applyOpen(Tiles.tableTopLeft),
    "─": applyOpen(Tiles.tableTop),
    "┐": applyOpen(Tiles.tableTopRight),
    "-": applyOpen(Tiles.tableCenter),
    "│": applyOpen(Tiles.tableSide),
    "╘": applyOpen(Tiles.tableBottomLeft),
    "═": applyOpen(Tiles.tableBottom),
    "╛": applyOpen(Tiles.tableBottomRight),
    "╞": applyOpen(Tiles.tableLegLeft),
    "╤": applyOpen(Tiles.tableLeg),
    "╡": applyOpen(Tiles.tableLegRight),
  };

  // Counters.
  category(themes: "room", cells: tableCells);
  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    ?...
    #─┐.
    #-│.
    #╤╛.
    ?...""");

  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    ?...
    #─┐.
    #-│.
    #-│.
    #╤╛.
    ?...""");

  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    ?...
    #─┐.
    #-│.
    #-│.
    #-│.
    #╤╛.
    ?...""");

  furnishing(template: """
    .....
    .┌─┐.
    .│-│.
    ?###?""");

  furnishing(template: """
    ......
    .┌──┐.
    .│--│.
    ?####?""");

  furnishing(template: """
    .......
    .┌───┐.
    .│---│.
    ?#####?""");

  furnishing(template: """
    ?###?
    .│-│.
    .╞═╡.
    .....""");

  furnishing(template: """
    ?####?
    .│--│.
    .╞══╡.
    ......""");

  furnishing(template: """
    ?#####?
    .│---│.
    .╞═══╡.
    .......""");

  // Separating counters.
  category(themes: "room", frequency: 0.3, cells: tableCells);
  furnishing(template: """
    ?.....?
    #─┐.┌─#
    #╤╛.╘╤#
    ?.....?""");

  furnishing(template: """
    ?.......?
    #──┐.┌──#
    #═╤╛.╘╤═#
    ?.......?""");

  furnishing(template: """
    ?.........?
    #───┐.┌───#
    #══╤╛.╘╤══#
    ?.........?""");

  furnishing(template: """
    ?##?
    .││.
    .╞╡.
    ....
    .┌┐.
    .││.
    ?##?""");

  furnishing(template: """
    ?##?
    .││.
    .││.
    .╞╡.
    ....
    .┌┐.
    .││.
    .││.
    ?##?""");

  furnishing(template: """
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
  category(themes: "room", cells: tableCells);

  furnishing(template: """
    .....
    .┌─┐.
    .│-│.
    .╞═╡.
    .....""");

  furnishing(template: """
    ......
    .┌──┐.
    .│--│.
    .╞══╡.
    ......""");

  furnishing(template: """
    .......
    .┌───┐.
    .│---│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    ........
    .┌────┐.
    .│----│.
    .╘╤══╤╛.
    ........""");

  furnishing(template: """
    .........
    .┌─────┐.
    .│-----│.
    .╘╤═══╤╛.
    .........""");

  furnishing(template: """
    ..........
    .┌──────┐.
    .│------│.
    .╘╤════╤╛.
    ..........""");

  furnishing(template: """
    .....
    .┌─┐.
    .│-│.
    .│-│.
    .╞═╡.
    .....""");

  furnishing(template: """
    ......
    .┌──┐.
    .│--│.
    .│--│.
    .╞══╡.
    ......""");

  furnishing(template: """
    .......
    .┌───┐.
    .│---│.
    .│---│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    ........
    .┌────┐.
    .│----│.
    .│----│.
    .╘╤══╤╛.
    ........""");

  furnishing(template: """
    .........
    .┌─────┐.
    .│-----│.
    .│-----│.
    .╘╤═══╤╛.
    .........""");

  furnishing(template: """
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
  category(themes: "room", cells: {
    "π": applyOpen(Tiles.chair),
  });

  furnishing(symmetry: Symmetry.mirrorBoth, template: """
    π.
    .┌""");

  furnishing(symmetry: Symmetry.mirrorBoth, template: """
    π.
    ┌?""");

  furnishing(symmetry: Symmetry.mirrorBoth, template: """
    ..
    π┌""");

  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    .╞
    π.""");

  furnishing(symmetry: Symmetry.rotate90, template: """
    ?═?
    .π.""");

  furnishing(template: """
    ?╤?
    .π.""");

  furnishing(symmetry: Symmetry.rotate90, template: """
    π
    #""");

  furnishing(symmetry: Symmetry.rotate90, template: """
    π
    .
    #""");
}