import 'package:hauberk/src/ui/input.dart';
import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../../hues.dart';

class Table<T> {
  final List<Column> _columns;

  /// All rows that have been added.
  final List<Row<T>> _allRows = [];

  /// The rows that are visible given the current filter.
  final List<Row<T>> _shownRows = [];

  final List<RowOrder<T>> _orders;

  final List<RowFilter<T>> _filters;

  /// The size of the table the last time it was rendered.
  Vec _size = Vec.zero;

  /// The number of rows shown on screen.
  int _visibleRows = 0;

  /// How many rows down have been scrolled.
  int _scroll = 0;

  /// Index of the currently selected row.
  int _selectedRow = 0;

  /// Index of the current ordering.
  int _order = 0;

  /// Index of the current filter.
  int _filter = 0;

  /// The currently selected row.
  Row get selectedRow => _shownRows[_selectedRow];

  Table(
    this._columns, {
    List<RowOrder<T>> orders = const [],
    List<RowFilter<T>> filters = const [],
  }) : _orders = orders,
       _filters = filters;

  Map<String, String> get extraHelp => {
    "↕": "Scroll",
    if (_orders.isNotEmpty)
      "S": "Sort by ${_orders[(_order + 1) % _orders.length].description}",
    if (_filters.isNotEmpty)
      "F": "Show ${_filters[(_filter + 1) % _filters.length].description}",
  };

  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _select(-1);
        return true;

      case Input.s:
        _select(1);
        return true;

      case Input.runN:
        _select(-(_visibleRows - 1));
        return true;

      case Input.runS:
        _select(_visibleRows - 1);
        return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (alt) return false;

    switch (keyCode) {
      case KeyCode.s when !shift && _orders.isNotEmpty:
        _order = (_order + 1) % _orders.length;
        _orderAndFilter();
        return true;
      case KeyCode.s when shift && _orders.isNotEmpty:
        _order = (_order + _orders.length - 1) % _orders.length;
        _orderAndFilter();
        return true;

      case KeyCode.f when !shift && _filters.isNotEmpty:
        _filter = (_filter + 1) % _filters.length;
        _orderAndFilter();
        return true;
      case KeyCode.f when shift && _filters.isNotEmpty:
        _filter = (_filter + _filters.length - 1) % _filters.length;
        _orderAndFilter();
        return true;
      default:
        return false;
    }
  }

  void rebuild(Iterable<Row<T>> Function() build) {
    _preserveSelectedRow(() {
      _allRows.clear();
      _allRows.addAll(build());
      _orderAndFilter();
    });
  }

  void draw(Terminal terminal) {
    if (terminal.size != _size) _resize(terminal.size);

    // Draw the headers.
    for (var column in _columns) {
      terminal.writeAt(
        column._x + column.align.offset(column._calculatedWidth, column.label),
        0,
        column.label,
        coolGray,
      );
    }

    // Write the sort and filter.
    var parts = [
      if (_orders.isNotEmpty) "ordered by ${_orders[_order].description}",
      if (_filters.isNotEmpty) "show ${_filters[_filter].description}",
    ];
    var description = "(${parts.join(', ')})";
    terminal.writeAt(
      _columns.first._x + _columns.first._calculatedWidth - description.length,
      0,
      description,
      darkCoolGray,
    );

    // Header line.
    _drawLine(terminal, 1, darkCoolGray);

    // Draw the rows.
    for (var i = 0; i < _visibleRows; i++) {
      var y = i * 2 + 2;

      var rowIndex = _scroll + i;
      if (rowIndex >= _shownRows.length) continue;

      var row = _shownRows[rowIndex];

      if (row.glyph case var glyph?) {
        terminal.drawGlyph(0, y, glyph);
      }

      if (rowIndex == _selectedRow) {
        terminal.writeAt(1, y, "►", UIHue.selection);
      }

      assert(row.cells.length <= _columns.length);
      for (var j = 0; j < row.cells.length; j++) {
        row.cells[j].draw(
          terminal,
          _columns[j],
          y,
          selected: rowIndex == _selectedRow,
        );
      }

      _drawLine(terminal, y + 1, darkerCoolGray);
    }

    // Draw the scroll bar.
    var barHeight = _visibleRows * 2;
    if (_shownRows.length <= _visibleRows) {
      // No scroll thumb.
      for (var i = 0; i < barHeight; i++) {
        terminal.writeAt(terminal.width - 1, i + 2, "▌", darkerCoolGray);
      }
    } else {
      var thumbHeight = (barHeight * _visibleRows / _shownRows.length)
          .toInt()
          .clamp(1, barHeight);
      var thumbTop =
          ((barHeight - thumbHeight) *
                  _scroll /
                  (_shownRows.length - _visibleRows + 1))
              .toInt();
      var thumbBottom = thumbTop + thumbHeight;
      for (var i = 0; i < barHeight; i++) {
        var color = i < thumbTop || i > thumbBottom
            ? darkerCoolGray
            : darkCoolGray;
        terminal.writeAt(terminal.width - 1, i + 2, "▌", color);
      }
    }
  }

  void _resize(Vec tableSize) {
    // Calculate the width of the growable column if there is one.
    Column? growableColumn;
    var totalFixedWidth = 0;
    for (var column in _columns) {
      if (column.width == 0) {
        assert(growableColumn == null, "Only one growable column supported.");
        growableColumn = column;
      } else {
        column._calculatedWidth = column.width;
        totalFixedWidth += column.width;
      }
    }

    // Add a character of padding between each column.
    totalFixedWidth += _columns.length - 1;

    // Add two spaces for the glyph and arrow, and two for the scroll bar.
    totalFixedWidth += 4;

    // Give the growable column any remaining space.
    if (growableColumn != null) {
      growableColumn._calculatedWidth = tableSize.x - totalFixedWidth;
    }

    // Calculate the positions of each column.
    var x = 2;
    for (var i = 0; i < _columns.length; i++) {
      // Add a character of padding between each column.
      if (i > 0) x++;

      _columns[i]._x = x;
      x += _columns[i]._calculatedWidth;
    }

    _visibleRows = (tableSize.y - 2) ~/ 2;
    _size = tableSize;

    _keepInBounds();
  }

  void _orderAndFilter() {
    _preserveSelectedRow(() {
      _allRows.sort((rowA, rowB) {
        for (var comparison in _orders[_order].comparisons) {
          var order = comparison(rowA.data, rowB.data);
          if (order != 0) return order;
        }

        return 0;
      });

      _shownRows.clear();
      if (_filters.isNotEmpty) {
        _shownRows.addAll(
          _allRows.where((row) => _filters[_filter].where(row.data)),
        );
      } else {
        _shownRows.addAll(_allRows);
      }
    });
  }

  void _select(int offset) {
    _selectedRow = (_selectedRow + offset).clamp(0, _shownRows.length - 1);
    _keepInBounds();
  }

  /// Invokes [callback] which rebuilds or reorders the rows while trying to
  /// preserve the currently selected data item if possible.
  void _preserveSelectedRow(void Function() callback) {
    T? selectedData;
    if (_selectedRow < _shownRows.length) {
      selectedData = _shownRows[_selectedRow].data;
    }

    callback();

    // Try to keep the same row selected.
    _selectedRow = 0;
    if (_selectedRow < _shownRows.length) {
      for (var i = 0; i < _shownRows.length; i++) {
        if (_shownRows[i].data == selectedData) {
          _selectedRow = i;
          break;
        }
      }
    }

    _keepInBounds();
  }

  void _keepInBounds() {
    if (_shownRows.isNotEmpty && _visibleRows > 0) {
      // Make sure the row index is still valid.
      _selectedRow = _selectedRow.clamp(0, _shownRows.length - 1);

      // Keep the selected row on screen.
      _scroll = _scroll.clamp(_selectedRow - _visibleRows + 1, _selectedRow);

      // Keep the scrolled region in bounds.
      if (_shownRows.length > _visibleRows) {
        _scroll = _scroll.clamp(0, _shownRows.length - _visibleRows);
      } else {
        _scroll = 0;
      }
    } else {
      _selectedRow = 0;
      _scroll = 0;
    }
  }

  void _drawLine(Terminal terminal, int y, Color color) {
    var x = 2;
    for (var column in _columns) {
      terminal.writeAt(x, y, "─" * column._calculatedWidth, color);
      x += column._calculatedWidth + 1;
    }
  }
}

enum Align {
  left,
  center,
  right;

  /// How much horizontal offset to apply to align [text] within [width].
  int offset(int width, String text) => switch (this) {
    Align.left => 0,
    Align.center => (width - text.length) ~/ 2,
    Align.right => width - text.length,
  };
}

class Column {
  final String label;

  final Align align;

  /// How many characters wide this column should be or 0 if it should grow to
  /// fit the available space.
  final int width;

  /// The starting horizontal position of the column.
  int _x = 0;

  /// The current width of the column for a given table size.
  ///
  /// This is [width] unless [width] is zero in which case it's calculated from
  /// the remaining space.
  int _calculatedWidth = 0;

  Column(this.label, {this.width = 0, this.align = Align.left});
}

class Row<T> {
  final Glyph? glyph;
  final T data;
  final List<Cell> cells;

  Row(this.data, this.cells, {this.glyph});
}

class Cell {
  final String text;
  final Color? color;

  Cell(this.text, {this.color});

  void draw(Terminal terminal, Column column, int y, {required bool selected}) {
    terminal.writeAt(
      column._x + column.align.offset(column._calculatedWidth, text),
      y,
      text,
      color ?? (selected ? UIHue.selection : UIHue.text),
    );
  }
}

class RowOrder<T> {
  final String description;

  /// The way rows should be ordered.
  ///
  /// Each comparison is tried in order and the first non-zero one determines
  /// the ordering.
  final List<int Function(T a, T b)> comparisons;

  const RowOrder(this.description, this.comparisons);
}

class RowFilter<T> {
  final String description;

  final bool Function(T data) where;

  RowFilter(this.description, {required this.where});
}
