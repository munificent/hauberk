import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';

/// Unlike a regular [Dungeon], a Maze has walls of "zero" thickness. Used as
/// an intermediate data structure for building Dungeons. The outer walls of
/// the Maze can be opened.
class Maze {
  final Array2D<_Cell> _cells;

  Rect get bounds => Rect(0, 0, _cells.width - 1, _cells.height - 1);

  /// Initializes a new solid (i.e. all cells closed) maze.
  Maze(int width, int height)
      : _cells =
            Array2D<_Cell>.generated(width + 1, height + 1, () => _Cell()) {
    // Pad by one for the outer bottom and right walls.
  }

  /// Implementation of the "growing tree" algorithm from here:
  /// http://www.astrolog.org/labyrnth/algrithm.htm.
  void generate() {
    final cells = <Vec>[];

    // Start with a random cell.
    final pos = rng.vecInRect(bounds);

    open(pos);
    cells.add(pos);

    while (cells.length > 0) {
      // Weighting how the index is chosen here will affect the way the
      // maze looks.
      //final index = (rng.TriangleInt(0, cells.length - 1)).abs();
      final index = cells.length - 1;
      final cell = cells[index];

      // See which adjacent cells are open.
      final unmadeCells = <Direction>[];

      if (canCarve(cell, Direction.n)) unmadeCells.add(Direction.n);
      if (canCarve(cell, Direction.s)) unmadeCells.add(Direction.s);
      if (canCarve(cell, Direction.e)) unmadeCells.add(Direction.e);
      if (canCarve(cell, Direction.w)) unmadeCells.add(Direction.w);

      if (unmadeCells.length > 0) {
        final direction = rng.item(unmadeCells);

        carve(cell, direction);
        cells.add(cell + direction);
      } else {
        // No adjacent uncarved cells.
        cells.removeAt(index);
      }
    }
  }

  /*
  void AddLoops(int chance) {
    if (chance > 0) {
      for (var cell in new Rect(0, 0, bounds.width - 1, bounds.height - 1)) {
        if (rng.oneIn(chance)) {
          if (isOpen(cell) && isOpen(cell + Direction.e)) {
            carve(cell, Direction.e);
          }
        }

        if (rng.OneIn(chance)) {
          if (isOpen(cell) && isOpen(cell + Direction.s)) {
            carve(cell, Direction.s);
          }
        }
      }
    }
  }

  void Sparsify(int sparseSteps) {
    for (int i = 0; i < sparseSteps; i++) {
      for (var cell in bounds) {
        // If it dead-ends.
        if (getNumExits(cell) == 1) {
          // Fill in the dead end.
          fill(cell);
        }
      }
    }
  }
  */

  bool isOpen(Vec pos) {
    return _cells[pos].isOpen;
  }

  /// Gets whether or not an opening can be carved from the given starting
  /// [Cell] at [pos] to the adjacent Cell facing [direction]. Returns `true`
  /// if the starting Cell is in bounds and the destination Cell is filled
  /// (or out of bounds).</returns>
  bool canCarve(Vec pos, Direction direction) {
    // Must start in bounds.
    if (!bounds.contains(pos)) return false;

    // Must end in bounds.
    if (!bounds.contains(pos + direction)) return false;

    // Destination must not be open.
    return !_cells[pos + direction].isOpen;
  }

  /// Gets the number of open walls surrounding the [Cell] at [pos].
  int getNumExits(Vec pos) {
    var exits = 0;

    if (_cells[pos].isLeftWallOpen) exits++;
    if (_cells[pos].isTopWallOpen) exits++;
    if (_cells[pos.offsetX(1)].isLeftWallOpen) exits++;
    if (_cells[pos.offsetY(1)].isTopWallOpen) exits++;

    return exits;
  }

  /// Opens the Cell at [pos]. Does not open any surrounding walls.
  void open(Vec pos) {
    _cells[pos].isOpen = true;
  }

  /// Fills the [Cell] at [pos]. Closes any surrounding walls.
  void fill(Vec pos) {
    _cells[pos].isOpen = false;
    _cells[pos].isLeftWallOpen = false;
    _cells[pos].isTopWallOpen = false;
    _cells[pos.offsetX(1)].isLeftWallOpen = false;
    _cells[pos.offsetY(1)].isTopWallOpen = false;
  }

  /// Carves a passage from [pos] to the adjacent [Cell] facing [direction].
  /// Opens the destination Cell (if in bounds) and opens the wall between it
  /// and the starting Cell.
  void carve(Vec pos, Direction direction) {
    // Open the destination.
    if (bounds.contains(pos + direction)) {
      _cells[pos + direction].isOpen = true;
    }

    // Cut the wall.
    switch (direction) {
      case Direction.n:
        _cells[pos].isTopWallOpen = true;
        break;
      case Direction.s:
        _cells[pos + direction].isTopWallOpen = true;
        break;
      case Direction.w:
        _cells[pos].isLeftWallOpen = true;
        break;
      case Direction.e:
        _cells[pos + direction].isLeftWallOpen = true;
        break;
      default:
        assert(false);
    }
  }

  void draw(Stage stage) {
    void carve(Vec pos) {
      stage[pos].type = Tiles.floor;
    }

    for (final pos in _cells.bounds) {
      // Open the cell.
      if (_cells[pos].isOpen) carve((pos * 2) + 1);

      // Open the left wall.
      if (_cells[pos].isLeftWallOpen) carve((pos * 2) + Vec(0, 1));

      // Open the top wall.
      if (_cells[pos].isTopWallOpen) carve((pos * 2) + Vec(1, 0));
    }
  }
}

class _Cell {
  bool isOpen = false;
  bool isLeftWallOpen = false;
  bool isTopWallOpen = false;
}
