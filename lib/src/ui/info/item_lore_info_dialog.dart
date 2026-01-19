import 'package:malison/malison.dart';

import '../../engine.dart';
import '../input.dart';
import '../item/item_inspector.dart';
import '../widget/table.dart';
import 'info_dialog.dart';

class ItemLoreInfoDialog extends InfoDialog {
  static int _compareSortIndex(ItemType a, ItemType b) =>
      a.sortIndex.compareTo(b.sortIndex);

  static int _compareDepth(ItemType a, ItemType b) =>
      a.depth.compareTo(b.depth);

  static int _comparePrice(ItemType a, ItemType b) =>
      a.price.compareTo(b.price);

  static int _compareName(ItemType a, ItemType b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  late final Table<ItemType> _table = Table(
    columns: [
      Column("Name"),
      Column("Depth", width: 5, align: Align.right),
      Column("Price", width: 7, align: Align.right),
      Column("Found", width: 5, align: Align.right),
      Column("Used", width: 5, align: Align.right),
    ],
    orders: [
      RowOrder("type", [_compareSortIndex, _compareDepth, _compareName]),
      RowOrder("name", [_compareName]),
      RowOrder("depth", [_compareDepth, _compareName]),
      RowOrder("price", [_comparePrice, _compareName]),
      // TODO: Damage for weapons, weight, heft, etc.
    ],
    filters: [
      RowFilter("all", where: (item) => true),
      RowFilter("discovered", where: (item) => hero.lore.foundItems(item) > 0),
    ],
  );

  ItemLoreInfoDialog(super.content, super.hero) : super.base() {
    _buildRows();
  }

  @override
  String get name => "Item Lore";

  @override
  Map<String, String> get extraHelp => _table.extraHelp;

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (_table.keyDown(keyCode, shift: shift, alt: alt)) {
      dirty();
      return true;
    }

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

  @override
  bool handleInput(Input input) {
    if (_table.handleInput(input)) {
      dirty();
      return true;
    }

    return super.handleInput(input);
  }

  @override
  void drawInfo(Terminal terminal) {
    _table.draw(terminal.rect(0, 1, terminal.width, terminal.height - 16));

    var item = _table.selectedRow.data;
    if (hero.lore.foundItems(item) > 0) {
      var inspector = ItemInspector(hero, Item(item, 1), wide: true);
      inspector.drawWide(
        terminal.rect(0, terminal.height - 15, terminal.width, 14),
      );
    }
  }

  void _buildRows() {
    var items = content.items.toList();

    _table.rebuild(() sync* {
      for (var index = 0; index < items.length; index++) {
        var item = items[index];
        var found = hero.lore.foundItems(item);
        if (found > 0) {
          yield Row(item, glyph: item.appearance as Glyph, [
            Cell(item.name),
            Cell(item.depth.fmt(w: 5)),
            Cell(item.price.fmt(w: 7)),
            if (item.isArtifact) Cell("Yes") else Cell(found.fmt(w: 5)),
            if (item.use != null)
              Cell(hero.lore.usedItems(item).fmt(w: 5))
            else
              Cell("--", enabled: false),
          ]);
        } else {
          yield Row(item, [
            Cell("(undiscovered ${index + 1})", enabled: false),
          ]);
        }
      }
    });
  }
}
