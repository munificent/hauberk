import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import '../item_view.dart';
import 'panel.dart';

class ItemPanel extends Panel {
  final Game _game;

  ItemPanel(this._game);

  void renderPanel(Terminal terminal) {
    var hero = _game.hero;
    var y =
        _drawItems(terminal, 0, hero.equipment.slots.length, hero.equipment);

    y = _drawItems(terminal, y, Option.inventoryCapacity, hero.inventory);

    // TODO: Don't show this panel if the height is too short for it.
    var onGround = _game.stage.itemsAt(hero.pos);
    y = _drawItems(terminal, y, 5, onGround);

    // TODO: Show something useful down here. Maybe mini-map or monster info.
    Draw.box(terminal, 0, y, terminal.width, terminal.height - y);
  }

  int _drawItems(Terminal terminal, int y, int height, ItemCollection items) {
    Draw.frame(terminal, 0, y, terminal.width, height + 2);
    terminal.writeAt(2, y, " ${items.name} ", UIHue.text);

    var view = _ItemPanelItemView(items);
    view.render(terminal.rect(1, y + 1, terminal.width - 2, height));

    return y + height + 2;
  }
}

class _ItemPanelItemView extends ItemView {
  final ItemCollection items;

  _ItemPanelItemView(this.items);

  bool get showLetters => false;

  bool get canSelectAny => false;
}
