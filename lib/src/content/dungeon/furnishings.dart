import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'dungeon.dart';

enum Symmetry {
  none,
  mirrorHorizontal,
  mirrorVertical,
  mirrorBoth,
  rotate90,
  rotate180,
}

class Furnishings {
  static Furnishing choose() {
    return _furnishings.tryChoose(1, "furnishing");
  }

  static final ResourceSet<Furnishing> _furnishings = new ResourceSet();
  static double _frequency = 1.0;

  static final Map<String, Cell> _applyCells = {
    "┌": new Cell(apply: Tiles.tableTopLeft, motility: Motility.walk),
    "─": new Cell(apply: Tiles.tableTop, motility: Motility.walk),
    "┐": new Cell(apply: Tiles.tableTopRight, motility: Motility.walk),
    "-": new Cell(apply: Tiles.tableCenter, motility: Motility.walk),
    "│": new Cell(apply: Tiles.tableSide, motility: Motility.walk),
    "╘": new Cell(apply: Tiles.tableBottomLeft, motility: Motility.walk),
    "═": new Cell(apply: Tiles.tableBottom, motility: Motility.walk),
    "╛": new Cell(apply: Tiles.tableBottomRight, motility: Motility.walk),
    "╞": new Cell(apply: Tiles.tableLegLeft, motility: Motility.walk),
    "╤": new Cell(apply: Tiles.tableLeg, motility: Motility.walk),
    "╡": new Cell(apply: Tiles.tableLegRight, motility: Motility.walk),
    "π": new Cell(apply: Tiles.chair, motility: Motility.walk),
    "i": new Cell(apply: Tiles.candle, require: Tiles.tableCenter),
    "I": new Cell(apply: Tiles.wallTorch, require: Tiles.wall),
    "l": new Cell(apply: Tiles.wallTorch, motility: Motility.walk),
    "P": new Cell(apply: Tiles.statue, motility: Motility.walk),
    "≈": new Cell(apply: Tiles.water, motility: Motility.walk),
  };

  static final Map<String, Cell> _requireCells = {
    "?": new Cell(),
    ".": new Cell(motility: Motility.walk),
    "#": new Cell(require: Tiles.wall),
    "┌": new Cell(require: Tiles.tableTopLeft),
    "─": new Cell(require: Tiles.tableTop),
    "┐": new Cell(require: Tiles.tableTopRight),
    "-": new Cell(require: Tiles.tableCenter),
    "│": new Cell(require: Tiles.tableSide),
    "╘": new Cell(require: Tiles.tableBottomLeft),
    "═": new Cell(require: Tiles.tableBottom),
    "╛": new Cell(require: Tiles.tableBottomRight),
    "╞": new Cell(require: Tiles.tableLegLeft),
    "╤": new Cell(require: Tiles.tableLeg),
    "╡": new Cell(require: Tiles.tableLegRight),
    "π": new Cell(require: Tiles.chair),
    "≈": new Cell(require: Tiles.water),
  };

  static final _mirrorHorizontal = [
    "┌┐",
    "╛╘",
    "╞╡",
  ];

  static final _mirrorVertical = [
    "┌╘",
    "┐╛",
    "─═",
  ];

  static final _rotate = [
    "┌┐╛╘",
    "─│═│",
  ];

  static void initialize() {
    _furnishings.defineTags("furnishing");

    // Counters.
    _frequency = 0.1;
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
    _frequency = 0.05;
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
    _frequency = 0.1;
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
    _frequency = 6.0;
    furnishing(Symmetry.mirrorBoth, "π", """
    ...
    .π.
    ..┌""");

    furnishing(Symmetry.mirrorHorizontal, "π", """
    ..╞
    .π.
    ...""");

    furnishing(Symmetry.rotate90, "π", """
    ..?
    .π│
    ..?""");

    // Candles.
    _frequency = 4.0;
    furnishing(Symmetry.none, "i", """
    i""");

    // TODO: Other decorations on tables.

    // Fountains.
    _frequency = 0.03;
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
  }

  static void furnishing(Symmetry symmetry, String applied, String template) {
    var lines = template.split("\n").map((line) => line.trim()).toList();
    _singleFurnishing(applied, lines);

    if (symmetry == Symmetry.mirrorHorizontal ||
        symmetry == Symmetry.mirrorBoth) {
      var mirrorApplied = _mapString(applied, _mirrorCharHorizontal);
      var mirrorLines = lines.toList();
      for (var i = 0; i < lines.length; i++) {
        mirrorLines[i] = _mapString(
            String.fromCharCodes(lines[i].codeUnits.reversed),
            _mirrorCharHorizontal);
      }

      _singleFurnishing(mirrorApplied, mirrorLines);
    }

    if (symmetry == Symmetry.mirrorVertical ||
        symmetry == Symmetry.mirrorBoth) {
      var mirrorApplied = _mapString(applied, _mirrorCharVertical);
      var mirrorLines = lines.toList();
      for (var i = 0; i < lines.length; i++) {
        mirrorLines[lines.length - i - 1] =
            _mapString(lines[i], _mirrorCharVertical);
      }

      _singleFurnishing(mirrorApplied, mirrorLines);
    }

    if (symmetry == Symmetry.mirrorBoth ||
        symmetry == Symmetry.rotate180 ||
        symmetry == Symmetry.rotate90) {
      var mirrorApplied = _mapString(applied, _mirrorCharBoth);

      var mirrorLines = lines.toList();
      for (var i = 0; i < lines.length; i++) {
        mirrorLines[lines.length - i - 1] = _mapString(
            String.fromCharCodes(lines[i].codeUnits.reversed), _mirrorCharBoth);
      }

      _singleFurnishing(mirrorApplied, mirrorLines);
    }

    if (symmetry == Symmetry.rotate90) {
      // Rotate 90°.
      var rotateApplied = _mapString(applied, _rotateChar90);

      var rotateLines = <String>[];
      for (var x = 0; x < lines[0].length; x++) {
        var line = "";
        for (var y = 0; y < lines.length; y++) {
          line += _rotateChar90(lines[y][x]);
        }
        rotateLines.add(line);
      }

      _singleFurnishing(rotateApplied, rotateLines);

      // Rotate 270° by mirroring the 90°.
      var mirrorApplied = _mapString(rotateApplied, _mirrorCharBoth);

      var mirrorLines = rotateLines.toList();
      for (var i = 0; i < rotateLines.length; i++) {
        mirrorLines[rotateLines.length - i - 1] = _mapString(
            String.fromCharCodes(rotateLines[i].codeUnits.reversed),
            _mirrorCharBoth);
      }

      _singleFurnishing(mirrorApplied, mirrorLines);
    }
  }

  static String _mapString(String input, String Function(String) map) {
    var buffer = new StringBuffer();
    for (var i = 0; i < input.length; i++) {
      buffer.write(map(input[i]));
    }
    return buffer.toString();
  }

  static String _mirrorCharBoth(String input) =>
      _mirrorCharHorizontal(_mirrorCharVertical(input));

  static String _mirrorCharHorizontal(String input) {
    for (var mirror in _mirrorHorizontal) {
      var index = mirror.indexOf(input);
      if (index != -1) return mirror[1 - index];
    }

    // Tile doesn't change.
    return input;
  }

  static String _mirrorCharVertical(String input) {
    for (var mirror in _mirrorVertical) {
      var index = mirror.indexOf(input);
      if (index != -1) return mirror[1 - index];
    }

    // Tile doesn't change.
    return input;
  }

  static String _rotateChar90(String input) {
    for (var rotate in _rotate) {
      var index = rotate.indexOf(input);
      if (index != -1) return rotate[(index + 1) % 4];
    }

    // Tile doesn't change.
    return input;
  }

  static void _singleFurnishing(String applied, List<String> lines) {
    var cells = new Array2D<Cell>(lines.first.length, lines.length);
    for (var y = 0; y < lines.length; y++) {
      for (var x = 0; x < lines.first.length; x++) {
        var char = lines[y][x];
        Cell cell;
        if (applied.contains(char)) {
          cell = _applyCells[char];
        } else {
          cell = _requireCells[char];
        }

        assert(cell != null);
        cells.set(x, y, cell);
      }
    }

    var furnishing = new Furnishing(cells);
    _furnishings.add(_furnishings.length.toString(), furnishing, 1, _frequency,
        "furnishing");
  }
}

class Furnishing {
  final Array2D<Cell> cells;

  Furnishing(this.cells);

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
  final TileType _require;

  Cell({TileType apply, Motility motility, TileType require})
      : _apply = apply,
        _motility = motility,
        _require = require;

  bool meetsRequirement(TileType tile) {
    if (_motility != null && !tile.canEnter(_motility)) return false;
    if (_require != null && tile != _require) return false;
    return true;
  }

  void apply(Dungeon dungeon, Vec pos) {
    if (_apply != null) dungeon.setTileAt(pos, _apply);
  }
}
