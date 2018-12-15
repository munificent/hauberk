import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';

class ItemPanel {
  final Hero _hero;

  ItemPanel(this._hero);

  void render(Terminal terminal) {
    Draw.frame(
        terminal, 0, 0, terminal.width, _hero.equipment.slots.length + 2);
    terminal.writeAt(2, 0, " Equipment ", UIHue.text);

    var equipmentView = ItemPanelItemView(_hero.equipment);
    equipmentView.render(
        terminal.rect(1, 1, terminal.width - 2, _hero.equipment.slots.length));

    var inventoryTop = _hero.equipment.slots.length + 2;

    Draw.frame(terminal, 0, inventoryTop, terminal.width,
        Option.inventoryCapacity + 2);
    terminal.writeAt(2, inventoryTop, " Inventory ", UIHue.text);

    var inventoryView = ItemPanelItemView(_hero.inventory);
    inventoryView.render(terminal.rect(
        1, inventoryTop + 1, terminal.width - 2, Option.inventoryCapacity));

    // TODO: Show something useful down here. Maybe mini-map or monster info.
    var restTop = inventoryTop + Option.inventoryCapacity + 2;
    Draw.box(terminal, 0, restTop, terminal.width, terminal.height - restTop);
  }
}

class ItemPanelItemView extends ItemView {
  final ItemCollection items;

  ItemPanelItemView(this.items);

  bool get showLetters => false;
}

// TODO: This is copy/pasted from item_view.dart. Unify.
abstract class ItemView {
  ItemCollection get items;

  bool get showLetters => true;

  void render(Terminal terminal) {
    // TODO:
    var capitals = false;
    capitals ??= false;
    var letters =
        capitals ? "ABCDEFGHIJKLMNOPQRSTUVWXYZ" : "abcdefghijklmnopqrstuvwxyz";

    // Shift the stats over to make room for prices, if needed.
    var statRight = terminal.width;
    // TODO
//    if (getPrice != null) {
//      for (var item in items) {
//        var price = getPrice(item);
//        if (price != null) {
//          statRight =
//              math.min(statRight, terminal.width - formatMoney(price).length - 2);
//        }
//      }
//    }

    var i = 0;
    var letter = 0;
    for (var item in items.slots) {
      var y = i;

      var x = showLetters ? 2 : 0;

      // If there's no item in this equipment slot, show the slot name.
      if (item == null) {
        // Null items should only appear in equipment.
        assert(items.slotTypes != null);

        terminal.writeAt(x + 2, y, "(${items.slotTypes[i]})", UIHue.helpText);
        letter++;
        i++;
        continue;
      }

      var borderColor = steelGray;
      var letterColor = UIHue.secondary;
      var textColor = UIHue.primary;
      var enabled = true;

      // TODO
//      var canSelectItem = canSelect != null ? canSelect(item) : null;
      var canSelectItem = null;
      if (canSelectItem == true) {
        borderColor = UIHue.secondary;
        letterColor = UIHue.selection;
        textColor = UIHue.primary;
      } else if (canSelectItem == false) {
        borderColor = Color.black;
        letterColor = Color.black;
        textColor = UIHue.disabled;
        enabled = false;
      }

      if (showLetters) {
        terminal.writeAt(0, y, " )", borderColor);
        terminal.writeAt(0, y, letters[letter], letterColor);
      }

      letter++;

      if (enabled) {
        terminal.drawGlyph(x, y, item.appearance as Glyph);
      }

      terminal.writeAt(x + 2, y, item.nounText, textColor);

      // TODO
//      if (getPrice != null && getPrice(item) != null) {
//        var price = formatMoney(getPrice(item));
//        terminal.writeAt(terminal.width - price.length - 1, y, price,
//            enabled ? gold : UIHue.disabled);
//        terminal.writeAt(terminal.width - price.length - 2, y, "\$",
//            enabled ? persimmon : UIHue.disabled);
//      }

      drawStat(int symbol, Object stat, Color light, Color dark) {
        var string = stat.toString();
        terminal.drawChar(statRight - string.length - 1, y, symbol,
            enabled ? dark : UIHue.disabled);
        terminal.writeAt(statRight - string.length, y, string,
            enabled ? light : UIHue.disabled);
      }

      // TODO: Eventually need to handle equipment that gives both an armor and
      // attack bonus.
      if (item.attack != null) {
        var hit = item.attack.createHit();
        drawStat(CharCode.feminineOrdinalIndicator, hit.damageString, carrot,
            garnet);
      } else if (item.armor != 0) {
        drawStat(CharCode.latinSmallLetterAe, item.armor, peaGreen, sherwood);
      }

      // TODO
//      if (item != null && item == inspected) {
//        terminal.drawChar(
//            2, y, CharCode.blackRightPointingPointer, UIHue.selection);
//        terminal.drawChar(terminal.width - 1, y,
//            CharCode.blackRightPointingPointer, UIHue.selection);
//      }

      // TODO: Show heft and weight.
      i++;
    }
  }
}
