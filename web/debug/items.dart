import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content/item/items.dart';

main() {
  Items.initialize();
  var items = Items.types.all.toList();

  items.sort((a, b) {
    if (a.depth == null && b.depth == null) {
      return a.sortIndex.compareTo(b.sortIndex);
    }

    if (a.depth == null) return -1;
    if (b.depth == null) return 1;

    return a.depth.compareTo(b.depth);
  });

  var table = Table();
  table.column("Item");
  table.column("Depth");
  table.column("Stack");
  table.column("Price");
  table.column("Equip.");
  table.column("Weapon");
  table.column("Attack");
  table.column("Armor", defaultValue: 0);
  table.column("Weight", defaultValue: 0);
  table.column("Heft", defaultValue: 0);
  table.column("Toss");
  table.column("Use");

  for (var item in items) {
    var cells = <Object>[];

    var glyph = item.appearance as Glyph;
    cells.add('''
<code class="term"><span style="color: ${glyph.fore.cssColor}">${String.fromCharCodes([
      glyph.char
    ])}</span></code>&nbsp;${item.name}
    ''');

    cells.add(item.depth);
    cells.add(item.maxStack);
    cells.add(item.price);
    cells.add(item.equipSlot);
    cells.add(item.weaponType);
    cells.add(item.attack);
    cells.add(item.armor);
    cells.add(item.weight);
    cells.add(item.heft);

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

    table.row(cells);
  }

  table.render("table");
}

class Table {
  final List<Column> _columns = [];
  final List<Row> _rows = [];

  void column(String name, {Object defaultValue}) {
    _columns.add(Column(name, defaultValue));
  }

  void row(List<Object> cells) {
    _rows.add(Row(cells));
  }

  render(String selector) {
    var buffer = StringBuffer();

    buffer.write('<thead>\n<tr>');

    for (var column in _columns) {
      buffer.write('<td>');
      buffer.write(column.name);
      buffer.writeln('</td>');
    }

    buffer.write('</tr>\n</thead>\n<tbody>');

    for (var row in _rows) {
      buffer.write('<tr>');
      for (var cell in row._cells) {
        buffer.write('<td>');
        if (cell == null) {
          buffer.write('&mdash;');
        } else {
          buffer.write(cell);
        }
        buffer.write('</td>');
      }
      buffer.write('</tr>');
    }

    buffer.write('</tbody>');

    var validator = html.NodeValidatorBuilder.common();
    validator.allowInlineStyles();

    html
        .querySelector(selector)
        .setInnerHtml(buffer.toString(), validator: validator);
  }
}

class Column {
  final String name;
  final Object defaultValue;

  Column(this.name, this.defaultValue);
}

class Row {
  final List<Object> _cells;

  Row(this._cells);
}
