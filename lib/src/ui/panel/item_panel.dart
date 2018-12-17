import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import '../item_view.dart';

class ItemPanel {
  final Hero _hero;

  ItemPanel(this._hero);

  void render(Terminal terminal) {
    Draw.frame(
        terminal, 0, 0, terminal.width, _hero.equipment.slots.length + 2);
    terminal.writeAt(2, 0, " Equipment ", UIHue.text);

    var equipmentView = _ItemPanelItemView(_hero.equipment);
    equipmentView.render(
        terminal.rect(1, 1, terminal.width - 2, _hero.equipment.slots.length));

    var inventoryTop = _hero.equipment.slots.length + 2;

    Draw.frame(terminal, 0, inventoryTop, terminal.width,
        Option.inventoryCapacity + 2);
    terminal.writeAt(2, inventoryTop, " Inventory ", UIHue.text);

    var inventoryView = _ItemPanelItemView(_hero.inventory);
    inventoryView.render(terminal.rect(
        1, inventoryTop + 1, terminal.width - 2, Option.inventoryCapacity));

    // TODO: Show something useful down here. Maybe mini-map or monster info.
    var restTop = inventoryTop + Option.inventoryCapacity + 2;
    Draw.box(terminal, 0, restTop, terminal.width, terminal.height - restTop);
  }
}

class _ItemPanelItemView extends ItemView {
  final ItemCollection items;

  _ItemPanelItemView(this.items);

  bool get showLetters => false;
  bool get canSelectAny => false;
}
