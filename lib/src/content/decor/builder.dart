import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'decor.dart';

enum Symmetry {
  none,
  mirrorHorizontal,
  mirrorVertical,
  mirrorBoth,
  rotate90,
  rotate180,
}

double _frequency = 1.0;
String _themes;

final Map<String, Cell> _applyCells = {
  "┌": Cell(apply: Tiles.tableTopLeft, motility: Motility.walk),
  "─": Cell(apply: Tiles.tableTop, motility: Motility.walk),
  "┐": Cell(apply: Tiles.tableTopRight, motility: Motility.walk),
  "-": Cell(apply: Tiles.tableCenter, motility: Motility.walk),
  "│": Cell(apply: Tiles.tableSide, motility: Motility.walk),
  "╘": Cell(apply: Tiles.tableBottomLeft, motility: Motility.walk),
  "═": Cell(apply: Tiles.tableBottom, motility: Motility.walk),
  "╛": Cell(apply: Tiles.tableBottomRight, motility: Motility.walk),
  "╞": Cell(apply: Tiles.tableLegLeft, motility: Motility.walk),
  "╤": Cell(apply: Tiles.tableLeg, motility: Motility.walk),
  "╡": Cell(apply: Tiles.tableLegRight, motility: Motility.walk),
  "π": Cell(apply: Tiles.chair, motility: Motility.walk),
  "i": Cell(apply: Tiles.candle, require: Tiles.tableCenter),
  "I": Cell(apply: Tiles.wallTorch, require: Tiles.wall),
  "l": Cell(apply: Tiles.wallTorch, motility: Motility.walk),
  "P": Cell(apply: Tiles.statue, motility: Motility.walk),
  "≈": Cell(apply: Tiles.water, motility: Motility.walk),
  "%": Cell(apply: Tiles.closedBarrel, motility: Motility.walk),
  "&": Cell(apply: Tiles.closedChest, motility: Motility.walk),
  "*": Cell(apply: Tiles.tallGrass, require: Tiles.grass),
  "=": Cell(apply: Tiles.bridge, require: Tiles.water),
  "•": Cell(apply: Tiles.steppingStone, require: Tiles.water),
};

final Map<String, Cell> _requireCells = {
  "?": Cell(),
  ".": Cell(motility: Motility.walk),
  "#": Cell(require: Tiles.wall),
  "┌": Cell(require: Tiles.tableTopLeft),
  "─": Cell(require: Tiles.tableTop),
  "┐": Cell(require: Tiles.tableTopRight),
  "-": Cell(require: Tiles.tableCenter),
  "│": Cell(require: Tiles.tableSide),
  "╘": Cell(require: Tiles.tableBottomLeft),
  "═": Cell(require: Tiles.tableBottom),
  "╛": Cell(require: Tiles.tableBottomRight),
  "╞": Cell(require: Tiles.tableLegLeft),
  "╤": Cell(require: Tiles.tableLeg),
  "╡": Cell(require: Tiles.tableLegRight),
  "π": Cell(require: Tiles.chair),
  "≈": Cell(require: Tiles.water),
  "'": Cell(requireAny: [Tiles.grass, Tiles.tallGrass]),
  "•": Cell(require: Tiles.steppingStone),
  "o": Cell(require: Tiles.steppingStone),
};

final _mirrorHorizontal = [
  "┌┐",
  "╛╘",
  "╞╡",
];

final _mirrorVertical = [
  "┌╘",
  "┐╛",
  "─═",
];

final _rotate = [
  "┌┐╛╘",
  "─│═│",
];

void category(double frequency, {String themes}) {
  _frequency = frequency;
  _themes = themes;
  Decor.all.defineTags(_themes);
}

void furnishing(Symmetry symmetry, String applied, String template) {
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

  if (symmetry == Symmetry.mirrorVertical || symmetry == Symmetry.mirrorBoth) {
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

String _mapString(String input, String Function(String) map) {
  var buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    buffer.write(map(input[i]));
  }
  return buffer.toString();
}

String _mirrorCharBoth(String input) =>
    _mirrorCharHorizontal(_mirrorCharVertical(input));

String _mirrorCharHorizontal(String input) {
  for (var mirror in _mirrorHorizontal) {
    var index = mirror.indexOf(input);
    if (index != -1) return mirror[1 - index];
  }

  // Tile doesn't change.
  return input;
}

String _mirrorCharVertical(String input) {
  for (var mirror in _mirrorVertical) {
    var index = mirror.indexOf(input);
    if (index != -1) return mirror[1 - index];
  }

  // Tile doesn't change.
  return input;
}

String _rotateChar90(String input) {
  for (var rotate in _rotate) {
    var index = rotate.indexOf(input);
    if (index != -1) return rotate[(index + 1) % 4];
  }

  // Tile doesn't change.
  return input;
}

void _singleFurnishing(String applied, List<String> lines) {
  var cells = Array2D<Cell>(lines.first.length, lines.length);
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

  var furnishing = Decor(cells);
  Decor.all.addUnnamed(furnishing, 1, _frequency, _themes);
}
