import 'dart:math' as math;

import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import 'item_inspector.dart';

/// The ideal maximum width of an item list, including the frame.
const preferredItemListWidth = 46;

/// Renders a list of items in some UI context, including the surrounding frame.
void renderItems(
  Terminal terminal,
  ItemCollection items, {
  required int left,
  required int top,
  required int width,
  required int itemSlotCount,
  required HeroSave save,
  bool showLetters = true,
  bool canSelectAny = true,
  bool capitalize = false,
  bool showPrices = false,
  Item? inspectedItem,
  bool inspectorOnRight = false,
  bool Function(Item item) canSelect = _defaultCanSelect,
  int? Function(Item item) getPrice = _defaultGetPrice,
}) {
  Draw.frame(
    terminal,
    x: left,
    y: top,
    width: width,
    height: itemSlotCount + 2,
    color: canSelectAny ? UIHue.selection : UIHue.disabled,
    label: items.name,
    labelSelected: canSelectAny,
  );

  var letters = capitalize
      ? "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      : "abcdefghijklmnopqrstuvwxyz";

  // Shift the stats over to make room for prices, if needed.
  var statRight = left + width - 1;

  if (showPrices) {
    for (var item in items) {
      var price = getPrice(item);
      if (price != null) {
        statRight = math.min(statRight, left + width - price.fmt().length - 3);
      }
    }
  }

  var slot = 0;
  var letter = 0;
  for (var item in items.slots) {
    var x = left + (showLetters ? 3 : 1);
    var y = top + slot + 1;

    // If we run out of room, don't overflow. This can happen when looking at
    // items on the ground.
    if (slot >= itemSlotCount) {
      var more = items.length - itemSlotCount;
      terminal.writeAt(
        x + 1,
        top + itemSlotCount + 1,
        " $more more... ",
        canSelectAny ? UIHue.selection : UIHue.disabled,
      );
      break;
    }

    // If there's no item in this equipment slot, show the slot name.
    if (item == null) {
      // If this is the second hand slot and the previous one has a
      // two-handed item in it, mark this one.
      if (slot > 0 &&
          items.slotTypes[slot] == "hand" &&
          items.slotTypes[slot - 1] == "hand" &&
          (items.slots.elementAt(slot - 1)?.type.isTwoHanded ?? false)) {
        terminal.writeAt(x, y, "↑ (two-handed)", UIHue.disabled);
      } else {
        terminal.writeAt(
          x + 2,
          y,
          "(${items.slotTypes[slot]})",
          UIHue.disabled,
        );
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
      var price = getPrice(item)!.fmt();
      var priceLeft = left + width - 1 - price.length - 1;
      terminal.writeAt(priceLeft, y, "\$", enabled ? tan : UIHue.disabled);
      terminal.writeAt(
        priceLeft + 1,
        y,
        price,
        enabled ? gold : UIHue.disabled,
      );

      nameRight = priceLeft;
    }

    void drawStat(int symbol, Object stat, Color light, Color dark) {
      var string = stat.toString();
      var statLeft = statRight - string.length - 1;
      terminal.drawChar(statLeft, y, symbol, enabled ? dark : UIHue.disabled);
      terminal.writeAt(
        statLeft + 1,
        y,
        string,
        enabled ? light : UIHue.disabled,
      );

      nameRight = statLeft;
    }

    // TODO: Eventually need to handle equipment that gives both an armor and
    // attack bonus.
    if (item.attack != null) {
      var hit = item.attack!.createHit();
      drawStat(
        CharCode.feminineOrdinalIndicator,
        hit.damageString,
        carrot,
        brown,
      );
    } else if (item.armor != 0) {
      drawStat(CharCode.latinSmallLetterAe, item.armor, peaGreen, sherwood);
    }

    var name = Log.quantifyWithoutArticle(item.quantifiableName, item.count);
    var nameWidth = nameRight - (x + 2);
    if (name.length > nameWidth) name = name.substring(0, nameWidth);
    terminal.writeAt(x + 2, y, name, textColor);

    // Draw the inspector for this item.
    if (item == inspectedItem) {
      var inspector = ItemInspector(save, item);
      if (inspectorOnRight) {
        if (left + width + ItemInspector.width > terminal.width) {
          // No room on the right so draw it below.
          terminal.writeAt(left + width - 1, y, "▼", UIHue.selection);
          inspector.draw(
            left + (width - ItemInspector.width) ~/ 2,
            top + itemSlotCount + 3,
            terminal,
          );
        } else {
          terminal.writeAt(left + width - 1, y, "►", UIHue.selection);
          inspector.draw(left + width, y, terminal);
        }
      } else {
        terminal.writeAt(left, y, "◄", UIHue.selection);
        inspector.draw(left - ItemInspector.width, y, terminal);
      }
    }

    slot++;
  }
}

bool _defaultCanSelect(Item item) => false;

int? _defaultGetPrice(Item item) => item.price;
