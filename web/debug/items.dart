import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content/item/items.dart';
import 'package:hauberk/src/engine.dart';

final _scaleBySelect = html.querySelector("select") as html.SelectElement;

void main() {
  Items.initialize();

  _scaleBySelect.onChange.listen((_) {
    _makeTable();
  });

  _makeTable();
}

num _itemScale(ItemType item) {
  switch (_scaleBySelect.value) {
    case "none":
      return 1.0;
    case "depth":
      return item.depth;
    case "price":
      return item.price;
    case "heft":
      return item.heft;
    case "weight":
      return item.weight;
    default:
      throw "Unknown select value '${_scaleBySelect.value}'.";
  }
}

void _makeTable() {
  var table =
      Table<ItemType>("table", (a, b) => a.sortIndex.compareTo(b.sortIndex));
  table.column("Item");
  table.column("Depth");
  table.column("Stack");
  table.column("Price");
  table.column("Equip.");
  table.column("Weapon");
  table.column("Damage");
  table.column("Armor", defaultValue: 0);
  table.column("Weight", defaultValue: 0);
  table.column("Heft", defaultValue: 0);
  table.column("Toss");
  table.column("Use");

  for (var item in Items.types.all) {
    var scale = _itemScale(item);
    var cells = <Object>[];

    scaleValue(num value) {
      if (value == null) return null;
      if (scale == 0) return null;
      return value / scale;
    }

    var glyph = item.appearance as Glyph;
    cells.add('''
<code class="term"><span style="color: ${glyph.fore.cssColor}">${String.fromCharCodes([
      glyph.char
    ])}</span></code>&nbsp;${item.name}
    ''');

    cells.add(scaleValue(item.depth));
    cells.add(item.maxStack);
    cells.add(scaleValue(item.price));
    cells.add(item.equipSlot);
    cells.add(item.weaponType);
    cells.add(scaleValue(item.attack?.damage));
    cells.add(scaleValue(item.armor));
    cells.add(scaleValue(item.weight));
    cells.add(scaleValue(item.heft));

    if (item.toss == null) {
      cells.add(null);
    } else {
      var toss = item.toss.attack.toString();
      if (item.toss.use != null) {
        toss += ' ${item.toss.use(Vec.zero).runtimeType} ';
      }

      if (item.toss.breakage != 0) {
        toss += ' ${item.toss.breakage}%';
      }

      cells.add(toss);
    }

    if (item.use == null) {
      cells.add(null);
    } else {
      cells.add(item.use.description);
    }

    table.row(item, cells);
  }

  table.render();
}

class Table<T> {
  static final _validator = html.NodeValidatorBuilder.common()
    ..allowInlineStyles();

  final String _selector;
  final int Function(T a, T b) _defaultSort;
  final List<Column<T>> _columns = [];
  final List<Row<T>> _rows = [];

  final List<int> _sortOrders = [];

  Table(this._selector, this._defaultSort);

  void column(String name,
      {Object defaultValue, String Function(T, Object) render}) {
    _columns.add(Column(name, defaultValue, render));
  }

  void row(T value, List<Object> cells) {
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
          text = column.renderCell(row._value, cell);
        } else if (cell is num) {
          if (cell.toInt() == cell) {
            text = cell.toString();
          } else {
            text = cell.toStringAsFixed(2);
          }
        } else if (cell != null) {
          text = cell.toString();
        }

        tableCell.setInnerHtml(text, validator: _validator);
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
    print("sort orders: ${_sortOrders.join(' ')}");

    _rows.sort((rowA, rowB) {
      for (var i = _sortOrders.length - 1; i >= 0; i--) {
        var columnIndex = _sortOrders[i];
        var column = columnIndex.abs() - 1;
        var cellA = rowA._cells[column];
        var cellB = rowB._cells[column];

        var comparison = 0;
        if (cellA == null && cellB == null) {
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

//    for (var columnIndex in _sortOrders) {
//      _rows.sort((rowA, rowB) {
//        var column = columnIndex.abs() - 1;
//        var cellA = rowA._cells[column];
//        var cellB = rowB._cells[column];
//
//        var comparison = 0;
//        if (cellA == null && cellB == null) {
//          // Do nothing.
//        } else if (cellA == null) {
//          comparison = 1;
//        } else if (cellB == null) {
//          comparison = -1;
//        } else if (cellA is num && cellB is num) {
//          comparison = cellA.compareTo(cellB);
//        } else if (cellA is String && cellB is String) {
//          comparison = cellA.compareTo(cellB);
//        }
//
//        if (columnIndex < 0) comparison = -comparison;
//        return comparison;
//      });
//    }
  }
}

class Column<T> {
  final String name;
  final Object defaultValue;
  final String Function(T, Object) renderCell;

  Column(this.name, this.defaultValue, this.renderCell);
}

class Row<T> {
  final T _value;
  final List<Object> _cells;

  Row(this._value, this._cells);
}
