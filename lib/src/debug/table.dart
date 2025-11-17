import 'dart:html' as html;

/// Generates an HTML table with sortable columns.
class Table<T> {
  static final _validator = html.NodeValidatorBuilder.common()
    ..allowInlineStyles();

  final String _selector;
  final int Function(T a, T b) _defaultSort;
  final List<Column<T>> _columns = [];
  final List<Row<T>> _rows = [];

  final List<int> _sortOrders = [];

  Table(this._selector, this._defaultSort);

  void column(
    String name, {
    bool right = false,
    Object? defaultValue,
    String Function(T, Object?)? render,
    int Function(T, T)? compare,
  }) {
    _columns.add(
      Column(name, defaultValue, render, compare, alignRight: right),
    );
  }

  void row(T value, List<Object?> cells) {
    _rows.add(Row(value, cells));
  }

  void render() {
    _sortRows();

    var table = html.querySelector(_selector) as html.TableElement;
    table.children.clear();

    var thead = table.createTHead();
    var headRow = thead.addRow();

    for (var i = 0; i < _columns.length; i++) {
      var cell = headRow.addCell();

      var text = _columns[i].name;
      if (_sortOrders.isNotEmpty) {
        if (_sortOrders.last == i + 1) {
          text += "&nbsp;▴";
        } else if (_sortOrders.last == -(i + 1)) {
          text += "&nbsp;▾";
        } else if (_sortOrders.contains(i + 1)) {
          text += "&nbsp;▵";
        } else if (_sortOrders.contains(-(i + 1))) {
          text += "&nbsp;▿";
        }
      }

      cell.setInnerHtml(text, validator: _validator);
      cell.style.cursor = 'pointer';
      if (_columns[i].alignRight) cell.style.textAlign = 'right';

      cell.onClick.listen((_) {
        _sortBy(i + 1);
      });
    }

    var tbody = table.createTBody();

    for (var row in _rows) {
      var tableRow = tbody.addRow();

      for (var i = 0; i < row._cells.length; i++) {
        var column = _columns[i];
        var cell = row._cells[i];
        var tableCell = tableRow.addCell();

        var text = '&mdash;';
        if (cell == null) {
        } else if (column.renderCell != null) {
          text = column.renderCell!(row._value, cell);
        } else if (cell is num) {
          if (cell.toInt() == cell) {
            text = cell.toString();
          } else {
            text = cell.toStringAsFixed(2);
          }
        } else {
          text = cell.toString();
        }

        tableCell.setInnerHtml(text, validator: _validator);
        if (column.alignRight) tableCell.style.textAlign = 'right';
      }
    }
  }

  void _sortBy(int columnIndex) {
    if (_sortOrders.isNotEmpty && _sortOrders.contains(columnIndex)) {
      // Ascending -> descending.
      _sortOrders.remove(columnIndex);
      _sortOrders.add(-columnIndex);
    } else if (_sortOrders.isNotEmpty && _sortOrders.contains(-columnIndex)) {
      // Clicked the same column, so toggle descending to unsorted.
      _sortOrders.remove(-columnIndex);
    } else {
      _sortOrders.add(columnIndex);
    }

    render();
  }

  void _sortRows() {
    _rows.sort((rowA, rowB) {
      for (var i = _sortOrders.length - 1; i >= 0; i--) {
        var columnIndex = _sortOrders[i];
        var column = columnIndex.abs() - 1;
        var cellA = rowA._cells[column];
        var cellB = rowB._cells[column];

        var comparison = 0;

        var compareCells = _columns[column].compareCells;
        if (compareCells != null) {
          comparison = compareCells(rowA._value, rowB._value);
        } else if (cellA == null && cellB == null) {
          // Do nothing.
        } else if (cellA == null) {
          comparison = 1;
        } else if (cellB == null) {
          comparison = -1;
        } else if (cellA is num && cellB is num) {
          comparison = cellA.compareTo(cellB);
        } else if (cellA is String && cellB is String) {
          comparison = cellA.compareTo(cellB);
        }

        if (columnIndex < 0) comparison = -comparison;
        if (comparison != 0) return comparison;
      }

      return _defaultSort(rowA._value, rowB._value);
    });
  }
}

class Column<T> {
  final String name;
  final Object? defaultValue;
  final String Function(T, Object?)? renderCell;
  final int Function(T, T)? compareCells;
  final bool alignRight;

  Column(
    this.name,
    this.defaultValue,
    this.renderCell,
    this.compareCells, {
    required this.alignRight,
  });
}

class Row<T> {
  final T _value;
  final List<Object?> _cells;

  Row(this._value, this._cells);
}
