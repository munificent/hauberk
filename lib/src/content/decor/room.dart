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
    "i": applyOpen(Tiles.candle),
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
    #i│.
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
    #i│.
    #i│.
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

  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    ?...
    #─┐.
    #-│.
    #i│.
    #-│.
    #╤╛.
    ?...""");

  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    ?...
    #─┐.
    #i│.
    #-│.
    #i│.
    #╤╛.
    ?...""");

  furnishing(template: """
    .....
    .┌─┐.
    .│-│.
    ?###?""");

  furnishing(template: """
    .....
    .┌─┐.
    .│i│.
    ?###?""");

  furnishing(template: """
    ......
    .┌──┐.
    .│--│.
    ?####?""");

  furnishing(template: """
    ......
    .┌──┐.
    .│ii│.
    ?####?""");

  furnishing(template: """
    .......
    .┌───┐.
    .│---│.
    ?#####?""");

  furnishing(template: """
    .......
    .┌───┐.
    .│-i-│.
    ?#####?""");

  furnishing(template: """
    .......
    .┌───┐.
    .│i-i│.
    ?#####?""");

  furnishing(template: """
    ?###?
    .│-│.
    .╞═╡.
    .....""");

  furnishing(template: """
    ?###?
    .│i│.
    .╞═╡.
    .....""");

  furnishing(template: """
    ?####?
    .│--│.
    .╞══╡.
    ......""");

  furnishing(template: """
    ?####?
    .│ii│.
    .╞══╡.
    ......""");

  furnishing(template: """
    ?#####?
    .│---│.
    .╞═══╡.
    .......""");

  furnishing(template: """
    ?#####?
    .│-i-│.
    .╞═══╡.
    .......""");

  furnishing(template: """
    ?#####?
    .│i-i│.
    .╞═══╡.
    .......""");

  // Separating counters.
  category(themes: "room", cells: tableCells);
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
    .....
    .┌─┐.
    .│i│.
    .╞═╡.
    .....""");

  furnishing(template: """
    ......
    .┌──┐.
    .│--│.
    .╞══╡.
    ......""");

  furnishing(template: """
    ......
    .┌──┐.
    .│ii│.
    .╞══╡.
    ......""");

  furnishing(template: """
    .......
    .┌───┐.
    .│---│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    .......
    .┌───┐.
    .│-i-│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    .......
    .┌───┐.
    .│i-i│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    ........
    .┌────┐.
    .│----│.
    .╘╤══╤╛.
    ........""");

  furnishing(template: """
    ........
    .┌────┐.
    .│i--i│.
    .╘╤══╤╛.
    ........""");

  furnishing(template: """
    .........
    .┌─────┐.
    .│-----│.
    .╘╤═══╤╛.
    .........""");

  furnishing(template: """
    .........
    .┌─────┐.
    .│--i--│.
    .╘╤═══╤╛.
    .........""");

  furnishing(template: """
    .........
    .┌─────┐.
    .│-i-i-│.
    .╘╤═══╤╛.
    .........""");

  furnishing(template: """
    ..........
    .┌──────┐.
    .│------│.
    .╘╤════╤╛.
    ..........""");

  furnishing(template: """
    ..........
    .┌──────┐.
    .│-i--i-│.
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
    .....
    .┌─┐.
    .│i│.
    .│i│.
    .╞═╡.
    .....""");

  furnishing(template: """
    ......
    .┌──┐.
    .│--│.
    .│--│.
    .╞══╡.
    ......""");

  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    ......
    .┌──┐.
    .│i-│.
    .│-i│.
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
    .......
    .┌───┐.
    .│-i-│.
    .│-i-│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    .......
    .┌───┐.
    .│-i-│.
    .│i-i│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    .......
    .┌───┐.
    .│i-i│.
    .│-i-│.
    .╘╤═╤╛.
    .......""");

  furnishing(template: """
    ........
    .┌────┐.
    .│----│.
    .│----│.
    .╘╤══╤╛.
    ........""");

  furnishing(symmetry: Symmetry.mirrorHorizontal, template: """
    ........
    .┌────┐.
    .│i---│.
    .│---i│.
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
    .........
    .┌─────┐.
    .│--i--│.
    .│-i-i-│.
    .╘╤═══╤╛.
    .........""");

  furnishing(template: """
    .........
    .┌─────┐.
    .│i---i│.
    .│--i--│.
    .╘╤═══╤╛.
    .........""");

  furnishing(template: """
    ..........
    .┌──────┐.
    .│------│.
    .│------│.
    .╘╤════╤╛.
    ..........""");

  furnishing(template: """
    ..........
    .┌──────┐.
    .│-i--i-│.
    .│-i--i-│.
    .╘╤════╤╛.
    ..........""");

  // TODO: More table sizes? Shapes?

  // Chairs.
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