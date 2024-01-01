import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'hero_info_dialog.dart';
import 'input.dart';
import 'item_inspector.dart';
import 'item_view.dart';

class HeroItemLoreDialog extends HeroInfoDialog {
  static const _rowCount = 11;

  final List<ItemType> _items = [];
  _Sort _sort = _Sort.type;
  int _selection = 0;
  int _scroll = 0;

  HeroItemLoreDialog(super.content, super.hero) : super.base() {
    _listItems();
  }

  @override
  String get name => "Item Lore";

  @override
  String get extraHelp => "[↕] Scroll, [S] ${_sort.next.helpText}";

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (!shift && !alt && keyCode == KeyCode.s) {
      _sort = _sort.next;
      _listItems();
      dirty();
      return true;
    }

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _select(-1);
        return true;

      case Input.s:
        _select(1);
        return true;

      case Input.runN:
        _select(-(_rowCount - 1));
        return true;

      case Input.runS:
        _select(_rowCount - 1);
        return true;
    }

    return super.handleInput(input);
  }

  @override
  void render(Terminal terminal) {
    super.render(terminal);

    void writeLine(int y, Color color) {
      terminal.writeAt(
          2,
          y,
          "──────────────────────────────────────────────────── ───── ─────── "
          "───── ─────",
          color);
    }

    terminal.writeAt(2, 1, "Items", gold);
    terminal.writeAt(20, 1, "(${_sort.description})".padLeft(34), darkCoolGray);
    terminal.writeAt(55, 1, "Depth   Price Found  Used", coolGray);

    for (var i = 0; i < _rowCount; i++) {
      var y = i * 2 + 3;
      writeLine(y + 1, darkerCoolGray);

      var index = _scroll + i;
      if (index >= _items.length) continue;
      var item = _items[index];

      var fore = UIHue.text;
      if (index == _selection) {
        fore = UIHue.selection;
        terminal.writeAt(1, y, "►", fore);
      }

      var found = hero.lore.foundItems(item);
      if (found > 0) {
        terminal.drawGlyph(0, y, item.appearance as Glyph);
        terminal.writeAt(2, y, item.name, fore);

        terminal.writeAt(55, y, item.depth.toString().padLeft(5), fore);
        terminal.writeAt(61, y, formatMoney(item.price).padLeft(7), fore);
        terminal.writeAt(69, y, found.toString().padLeft(5), fore);

        if (item.use != null) {
          var used = hero.lore.usedItems(item);
          terminal.writeAt(75, y, used.toString().padLeft(5), fore);
        } else {
          terminal.writeAt(75, y, "--".padLeft(5), fore);
        }
      } else {
        terminal.writeAt(
            2, y, "(undiscovered ${_scroll + i + 1})", UIHue.disabled);
      }
    }

    writeLine(2, darkCoolGray);

    _showItem(terminal, _items[_selection]);
  }

  void _showItem(Terminal terminal, ItemType item) {
    var inspector = ItemInspector(hero, Item(item, 1), wide: true);
    inspector.drawWide(terminal.rect(0, terminal.height - 15, 80, 14));
  }

  void _select(int offset) {
    _selection = (_selection + offset).clamp(0, _items.length - 1);

    // Keep the selected row on screen.
    _scroll = _scroll.clamp(_selection - _rowCount + 1, _selection);
    dirty();
  }

  void _listItems() {
    // Try to keep the current item type selected, if there is one.
    ItemType? selectedItem;
    if (_items.isNotEmpty) {
      selectedItem = _items[_selection];
    }

    _items.clear();
    _items.addAll(content.items);

    int compareSort(ItemType a, ItemType b) =>
        a.sortIndex.compareTo(b.sortIndex);

    int compareDepth(ItemType a, ItemType b) => a.depth.compareTo(b.depth);

    int comparePrice(ItemType a, ItemType b) => a.price.compareTo(b.price);

    var comparisons = <int Function(ItemType, ItemType)>[];
    switch (_sort) {
      case _Sort.type:
        comparisons = [compareSort, compareDepth];

      case _Sort.name:
        // No other comparisons.
        break;

      case _Sort.depth:
        comparisons = [compareDepth];

      case _Sort.price:
        comparisons = [comparePrice];

      // TODO: Price. Damage for weapons, weight, heft, etc.
    }

    _items.sort((a, b) {
      for (var comparison in comparisons) {
        var compare = comparison(a, b);
        if (compare != 0) return compare;
      }

      // Otherwise, sort by name.
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    _selection = 0;
    if (selectedItem != null) {
      _selection = _items.indexOf(selectedItem);

      // TODO
//      // It may not be found since the unique page doesn't show all breeds.
//      if (_selection == -1) _selection = 0;
    }
    _select(0);
  }
}

class _Sort {
  /// The default order they are created in in the content.
  static const type = _Sort("ordered by type", "Sort by type");

  /// Sort by depth.
  static const depth = _Sort("ordered by depth", "Sort by depth");

  /// Sort alphabetically by name.
  static const name = _Sort("ordered by name", "Sort by name");

  /// Sort by price.
  static const price = _Sort("ordered by price", "Sort by price");

  static const all = [type, depth, name, price];

  final String description;
  final String helpText;

  const _Sort(this.description, this.helpText);

  _Sort get next => all[(all.indexOf(this) + 1) % all.length];
}
