import 'dart:math' as math;

import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'inspector.dart';

/// Renders a list of items in some UI context, including the surrounding frame.
abstract class ItemView {
  /// The ideal maximum width of an item list, including the frame.
  static int preferredWidth = 46;

  HeroSave get save;

  ItemCollection get items;

  bool get showLetters => true;

  bool get canSelectAny => true;

  bool get capitalize => false;

  bool get showPrices => false;

  Item? get inspectedItem => null;

  bool get inspectorOnRight => false;

  bool canSelect(Item item) => false;

  int? getPrice(Item item) => item.price;

  void render(
      Terminal terminal, int left, int top, int width, int itemSlotCount) {
    Draw.frame(terminal, left, top, width, itemSlotCount + 2,
        canSelectAny ? UIHue.selection : UIHue.disabled);
    terminal.writeAt(left + 2, top, " ${items.name} ",
        canSelectAny ? UIHue.selection : UIHue.text);

    var letters = capitalize
        ? "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        : "abcdefghijklmnopqrstuvwxyz";

    // Shift the stats over to make room for prices, if needed.
    var statRight = left + width - 1;

    if (showPrices) {
      for (var item in items) {
        var price = getPrice(item);
        if (price != null) {
          statRight =
              math.min(statRight, left + width - formatMoney(price).length - 3);
        }
      }
    }

    var slot = 0;
    var letter = 0;
    for (var item in items.slots) {
      var x = left + (showLetters ? 3 : 1);
      var y = top + slot + 1;

      // If there's no item in this equipment slot, show the slot name.
      if (item == null) {
        // If this is the second hand slot and the previous one has a
        // two-handed item in it, mark this one.
        if (slot > 0 &&
            items.slotTypes[slot] == "hand" &&
            items.slotTypes[slot - 1] == "hand" &&
            // TODO: Use "?.".
            items.slots.elementAt(slot - 1) != null &&
            items.slots.elementAt(slot - 1)!.type.isTwoHanded) {
          terminal.writeAt(x + 2, y, "↑ two-handed", UIHue.disabled);
        } else {
          terminal.writeAt(
              x + 2, y, "(${items.slotTypes[slot]})", UIHue.disabled);
        }
        letter++;
        slot++;
        continue;
      }

      var borderColor = darkCoolGray;
      var letterColor = UIHue.secondary;
      var textColor = UIHue.primary;
      var enabled = true;

      if (canSelectAny) {
        if (canSelect(item)) {
          borderColor = UIHue.secondary;
          letterColor = UIHue.selection;
          textColor = UIHue.primary;
        } else {
          borderColor = Color.black;
          letterColor = Color.black;
          textColor = UIHue.disabled;
          enabled = false;
        }
      }

      if (item == inspectedItem) {
        textColor = UIHue.selection;
      }

      if (showLetters) {
        terminal.writeAt(left + 1, y, " )", borderColor);
        terminal.writeAt(left + 1, y, letters[letter], letterColor);
      }

      letter++;

      if (enabled) {
        terminal.drawGlyph(x, y, item.appearance as Glyph);
      }

      var nameRight = left + width - 1;
      if (showPrices && getPrice(item) != null) {
        var price = formatMoney(getPrice(item)!);
        var priceLeft = left + width - 1 - price.length - 1;
        terminal.writeAt(priceLeft, y, "\$", enabled ? tan : UIHue.disabled);
        terminal.writeAt(
            priceLeft + 1, y, price, enabled ? gold : UIHue.disabled);

        nameRight = priceLeft;
      }

      void drawStat(int symbol, Object stat, Color light, Color dark) {
        var string = stat.toString();
        var statLeft = statRight - string.length - 1;
        terminal.drawChar(statLeft, y, symbol, enabled ? dark : UIHue.disabled);
        terminal.writeAt(
            statLeft + 1, y, string, enabled ? light : UIHue.disabled);

        nameRight = statLeft;
      }

      // TODO: Eventually need to handle equipment that gives both an armor and
      // attack bonus.
      if (item.attack != null) {
        var hit = item.attack!.createHit();
        drawStat(
            CharCode.feminineOrdinalIndicator, hit.damageString, carrot, brown);
      } else if (item.armor != 0) {
        drawStat(CharCode.latinSmallLetterAe, item.armor, peaGreen, sherwood);
      }

      var name = item.nounText;
      var nameWidth = nameRight - (x + 2);
      if (name.length > nameWidth) name = name.substring(0, nameWidth);
      terminal.writeAt(x + 2, y, name, textColor);

      // Draw the inspector for this item.
      if (item == inspectedItem) {
        var inspector = Inspector(save, item);
        if (inspectorOnRight) {
          if (left + width + Inspector.width > terminal.width) {
            // No room on the right so draw it below.
            terminal.writeAt(left + width - 1, y, "▼", UIHue.selection);
            inspector.draw(left + (width - Inspector.width) ~/ 2,
                top + itemSlotCount + 3, terminal);
          } else {
            terminal.writeAt(left + width - 1, y, "►", UIHue.selection);
            inspector.draw(left + width, y, terminal);
          }
        } else {
          terminal.writeAt(left, y, "◄", UIHue.selection);
          inspector.draw(left - Inspector.width, y, terminal);
        }
      }

      slot++;
    }
  }
}

// TODO: Move this elsewhere?
String formatMoney(int price) {
  var result = price.toString();
  if (price > 999999999) {
    result = result.substring(0, result.length - 9) +
        "," +
        result.substring(result.length - 9);
  }

  if (price > 999999) {
    result = result.substring(0, result.length - 6) +
        "," +
        result.substring(result.length - 6);
  }

  if (price > 999) {
    result = result.substring(0, result.length - 3) +
        "," +
        result.substring(result.length - 3);
  }

  return result;
}
