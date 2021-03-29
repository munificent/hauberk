// @dart=2.11
import 'package:malison/malison.dart';

import '../../engine.dart';
import '../draw.dart';
import '../item_view.dart';
import 'panel.dart';

class ItemPanel extends Panel {
  final Game _game;

  ItemPanel(this._game);

  int get equipmentTop => 0;

  int get inventoryTop => _game.hero.equipment.slots.length + 2;

  int get onGroundTop =>
      _game.hero.equipment.slots.length + Option.inventoryCapacity + 4;

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

  void _drawItems(
      Terminal terminal, int y, int itemSlotCount, ItemCollection items) {
    var view = _ItemPanelItemView(_game, items);
    view.render(terminal, 0, y, terminal.width, itemSlotCount);
  }
}

class _ItemPanelItemView extends ItemView {
  final Game _game;
  final ItemCollection items;

  _ItemPanelItemView(this._game, this.items);

  HeroSave get save => _game.hero.save;

  bool get showLetters => false;

  bool get canSelectAny => false;
}
