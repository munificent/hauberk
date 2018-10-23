import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'decor.dart';
import 'furnishing.dart';

enum Symmetry {
  none,
  mirrorHorizontal,
  mirrorVertical,
  mirrorBoth,
  rotate90,
  rotate180,
}

double _categoryFrequency;
double _furnishingFrequency;
String _themes;
Map<String, Cell> _categoryCells;

final Map<String, Cell> _applyCells = {
  "i": Cell(apply: Tiles.candle, require: Tiles.tableCenter),
  "I": Cell(apply: Tiles.wallTorch, require: Tiles.wall),
  "l": Cell(apply: Tiles.wallTorch, motility: Motility.walk),
  "P": Cell(apply: Tiles.statue, motility: Motility.walk),
  "≈": Cell(apply: Tiles.water, motility: Motility.walk),
  "%": Cell(apply: Tiles.closedBarrel, motility: Motility.walk),
  "&": Cell(apply: Tiles.closedChest, motility: Motility.walk),
  "*": Cell(apply: Tiles.tallGrass, require: Tiles.grass),
  "=": Cell(apply: Tiles.bridge, require: Tiles.water),
  "≡": Cell(apply: Tiles.bridge, motility: Motility.walk),
  "•": Cell(apply: Tiles.steppingStone, require: Tiles.water)
};

final Map<String, Cell> _requireCells = {
  "?": Cell(),
  ".": Cell(motility: Motility.walk),
  "#": Cell(requireAny: [Tiles.wall, Tiles.rock]),
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

void category({String themes, double frequency, Map<String, Cell> cells}) {
  _themes = themes;
  _categoryFrequency = frequency;
  _categoryCells = cells;
}

void furnishing({double frequency, Symmetry symmetry, String template}) {
  _furnishingFrequency = frequency;
  symmetry ??= Symmetry.none;

  var lines = template.split("\n").map((line) => line.trim()).toList();
  _singleFurnishing(lines);

  if (symmetry == Symmetry.mirrorHorizontal ||
      symmetry == Symmetry.mirrorBoth) {
    var mirrorLines = lines.toList();
    for (var i = 0; i < lines.length; i++) {
      mirrorLines[i] = _mapString(
          String.fromCharCodes(lines[i].codeUnits.reversed),
          _mirrorCharHorizontal);
    }

    _singleFurnishing(mirrorLines);
  }

  if (symmetry == Symmetry.mirrorVertical || symmetry == Symmetry.mirrorBoth) {
    var mirrorLines = lines.toList();
    for (var i = 0; i < lines.length; i++) {
      mirrorLines[lines.length - i - 1] =
          _mapString(lines[i], _mirrorCharVertical);
    }

    _singleFurnishing(mirrorLines);
  }

  if (symmetry == Symmetry.mirrorBoth ||
      symmetry == Symmetry.rotate180 ||
      symmetry == Symmetry.rotate90) {
    var mirrorLines = lines.toList();
    for (var i = 0; i < lines.length; i++) {
      mirrorLines[lines.length - i - 1] = _mapString(
          String.fromCharCodes(lines[i].codeUnits.reversed), _mirrorCharBoth);
    }

    _singleFurnishing(mirrorLines);
  }

  if (symmetry == Symmetry.rotate90) {
    // Rotate 90°.
    var rotateLines = <String>[];
    for (var x = 0; x < lines[0].length; x++) {
      var line = "";
      for (var y = 0; y < lines.length; y++) {
        line += _rotateChar90(lines[y][x]);
      }
      rotateLines.add(line);
    }

    _singleFurnishing(rotateLines);

    // Rotate 270° by mirroring the 90°.
    var mirrorLines = rotateLines.toList();
    for (var i = 0; i < rotateLines.length; i++) {
      mirrorLines[rotateLines.length - i - 1] = _mapString(
          String.fromCharCodes(rotateLines[i].codeUnits.reversed),
          _mirrorCharBoth);
    }

    _singleFurnishing(mirrorLines);
  }
}

Cell applyOpen(TileType type) => Cell(apply: type, motility: Motility.walk);

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

void _singleFurnishing(List<String> lines) {
  var cells = Array2D<Cell>(lines.first.length, lines.length);
  for (var y = 0; y < lines.length; y++) {
    for (var x = 0; x < lines.first.length; x++) {
      var char = lines[y][x];
      Cell cell;
      if (_categoryCells != null && _categoryCells.containsKey(char)) {
        cell = _categoryCells[char];
      } else if (_applyCells.containsKey(char)) {
        cell = _applyCells[char];
      } else {
        cell = _requireCells[char];
      }

      assert(cell != null);
      cells.set(x, y, cell);
    }
  }

  var furnishing = Furnishing(cells);
  Decor.all.addUnnamed(furnishing, 1,
      _categoryFrequency ?? _furnishingFrequency ?? 1.0, _themes);
}
