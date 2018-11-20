import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';
import 'item_view.dart';
import 'hero_info_dialog.dart';

class HeroItemLoreDialog extends HeroInfoDialog {
  static const _rowCount = 11;

  final List<ItemType> _items = [];
  _Sort _sort = _Sort.type;
  int _selection = 0;
  int _scroll = 0;

  HeroItemLoreDialog(Content content, HeroSave hero)
      : super.base(content, hero) {
    _listItems();
  }

  String get name => "Item Lore";

  String get extraHelp => "[↕] Scroll, [S] ${_sort.next.helpText}";

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (!shift && !alt && keyCode == KeyCode.s) {
      _sort = _sort.next;
      _listItems();
      dirty();
      return true;
    }

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

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

  void render(Terminal terminal) {
    super.render(terminal);

    writeLine(int y, Color color) {
      terminal.writeAt(
          2,
          y,
          "──────────────────────────────────────────────────── ───── ─────── "
          "───── ─────",
          color);
    }

    terminal.writeAt(2, 1, "Items", gold);
    terminal.writeAt(20, 1, "(${_sort.description})".padLeft(34), steelGray);
    terminal.writeAt(55, 1, "Depth   Price Found  Used", slate);

    for (var i = 0; i < _rowCount; i++) {
      var y = i * 2 + 3;
      writeLine(y + 1, midnight);

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

    writeLine(2, steelGray);

    _showItem(terminal, _items[_selection]);
  }

  void _showItem(Terminal terminal, ItemType item) {
    terminal = terminal.rect(0, terminal.height - 15, terminal.width, 14);

    Draw.frame(terminal, 0, 1, 80, terminal.height - 1);
    terminal.writeAt(1, 0, "┌─┐", steelGray);
    terminal.writeAt(1, 1, "╡ ╞", steelGray);
    terminal.writeAt(1, 2, "└─┘", steelGray);

    // TODO: Get working.
    var found = hero.lore.foundItems(item);
    if (found == 0) {
      terminal.writeAt(
          1, 3, "You have not found this item yet.", UIHue.disabled);
      return;
    }

    terminal.drawGlyph(2, 1, item.appearance as Glyph);
    terminal.writeAt(4, 1, item.name, UIHue.selection);

    // TODO: Show item details. Can we reuse the code from item_view.dart?
  }

  void _select(int offset) {
    _selection = (_selection + offset).clamp(0, _items.length - 1);

    // Keep the selected row on screen.
    _scroll = _scroll.clamp(_selection - _rowCount + 1, _selection);
    dirty();
  }

  void _listItems() {
    // Try to keep the current item type selected, if there is one.
    ItemType selectedItem;
    if (_items.isNotEmpty) {
      selectedItem = _items[_selection];
    }

    _items.clear();
    _items.addAll(content.items);

    compareSort(ItemType a, ItemType b) => a.sortIndex.compareTo(b.sortIndex);

    compareDepth(ItemType a, ItemType b) => a.depth.compareTo(b.depth);

    comparePrice(ItemType a, ItemType b) => a.price.compareTo(b.price);

    var comparisons = <int Function(ItemType, ItemType)>[];
    switch (_sort) {
      case _Sort.type:
        comparisons = [compareSort, compareDepth];
        break;

      case _Sort.name:
        // No other comparisons.
        break;

      case _Sort.depth:
        comparisons = [compareDepth];
        break;

      case _Sort.price:
        comparisons = [comparePrice];
        break;

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
  static const type =
      _Sort("ordered by type", "Sort by type");

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
