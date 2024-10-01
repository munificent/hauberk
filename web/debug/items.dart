import 'dart:html' as html;

import 'package:hauberk/src/content/item/items.dart';
import 'package:hauberk/src/debug/table.dart';
import 'package:hauberk/src/engine.dart';
import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

final _scaleBySelect = html.querySelector("select") as html.SelectElement;

void main() {
  Items.initialize();

  _scaleBySelect.onChange.listen((_) {
    _makeTable();
  });

  _makeTable();
}

num _itemScale(ItemType item) {
  return switch (_scaleBySelect.value) {
    "none" => 1.0,
    "depth" => item.depth,
    "price" => item.price,
    "heft" => item.heft,
    "weight" => item.weight,
    _ => throw ArgumentError("Unknown select value '${_scaleBySelect.value}'."),
  };
}

void _makeTable() {
  var table =
      Table<ItemType>("table", (a, b) => a.sortIndex.compareTo(b.sortIndex));
  table.column("Item", compare: (a, b) => a.name.compareTo(b.name));
  table.column("Depth", right: true);
  table.column("Stack", right: true);
  table.column("Price", right: true);
  table.column("Equip.");
  table.column("Weapon");
  table.column("Damage", right: true);
  table.column("Armor", right: true, defaultValue: 0);
  table.column("Weight", right: true, defaultValue: 0);
  table.column("Heft", right: true, defaultValue: 0);
  table.column("Toss");
  table.column("Use");

  for (var item in Items.types.all) {
    var scale = _itemScale(item);
    var cells = <Object?>[];

    num? scaleValue(num? value) {
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
      var toss = item.toss!.attack.toString();
      if (item.toss!.use != null) {
        toss += ' ${item.toss!.use!(Vec.zero).runtimeType} ';
      }

      if (item.toss!.breakage != 0) {
        toss += ' ${item.toss!.breakage}%';
      }

      cells.add(toss);
    }

    if (item.use == null) {
      cells.add(null);
    } else {
      cells.add(item.use!.description);
    }

    table.row(item, cells);
  }

  table.render();
}
