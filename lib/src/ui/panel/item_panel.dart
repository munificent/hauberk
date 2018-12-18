import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import '../item_view.dart';
import 'panel.dart';

class ItemPanel extends Panel {
  final Game _game;

  ItemPanel(this._game);

  int get equipmentTop => 0;

  int get inventoryTop => _game.hero.equipment.slots.length + 2;

  int get onGroundTop => _game.hero.equipment.slots.length + Option.inventoryCapacity + 4;

  bool get onGroundVisible => bounds.height > 50;

  void renderPanel(Terminal terminal) {
    var hero = _game.hero;
    _drawItems(
        terminal, equipmentTop, hero.equipment.slots.length, hero.equipment);

    _drawItems(
        terminal, inventoryTop, Option.inventoryCapacity, hero.inventory);

    // Don't show the on the ground panel if the height is too short for it.
    if (onGroundVisible) {
      var onGround = _game.stage.itemsAt(hero.pos);
      _drawItems(terminal, onGroundTop, 5, onGround);
    }

    // TODO: Show something useful down here. Maybe mini-map or monster info.
    var restTop = onGroundVisible ? onGroundTop + 7 : onGroundTop;
    Draw.box(terminal, 0, restTop, terminal.width, terminal.height - restTop);
  }

  void _drawItems(Terminal terminal, int y, int height, ItemCollection items) {
    Draw.frame(terminal, 0, y, terminal.width, height + 2);
    terminal.writeAt(2, y, " ${items.name} ", UIHue.text);

    var view = _ItemPanelItemView(items);
    view.render(terminal.rect(1, y + 1, terminal.width - 2, height));
  }
}

class _ItemPanelItemView extends ItemView {
  final ItemCollection items;

  _ItemPanelItemView(this.items);

  bool get showLetters => false;

  bool get canSelectAny => false;
}
