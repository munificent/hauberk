import 'dart:math' as math;

import 'package:malison/malison.dart';

import '../content/elements.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';

/// Draws a collection of [items] on [terminal] at [left].
///
/// This is used both on the [ItemScreen] and in game for things like using
/// and dropping items.
///
/// Items can be drawn in one of three states:
///
/// * If [canSelect] is `null` or returns `null`, then item list is just being
///   viewed and no items in particular are highlighted.
/// * If [canSelect] returns `true`, the item is highlighted as being
///   selectable.
/// * If [canSelect] returns `false`, the item cannot be selected and is
///   grayed out.
void drawItems(Terminal terminal, int left, ItemCollection items,
    {bool canSelect(Item item),
    int getPrice(Item item),
    bool isDialog,
    bool capitals,
    Item inspected}) {
  isDialog ??= false;

  terminal = terminal.rect(left, 2, 46, terminal.height - 2);

  // Draw a box for the contents.
  var itemCount = items.slots.length;
  var boxHeight = isDialog ? math.max(itemCount, 1) + 3 : terminal.height - 1;
  Draw.frame(terminal, 0, 0, terminal.width, boxHeight);

  terminal.writeAt(1, 0, items.name, UIHue.text);

  if (items.slots.isEmpty) {
    terminal.writeAt(1, 2, items.location.emptyDescription, UIHue.disabled);
    return;
  }

  capitals ??= false;
  var letters =
      capitals ? "ABCDEFGHIJKLMNOPQRSTUVWXYZ" : "abcdefghijklmnopqrstuvwxyz";

  // Shift the stats over to make room for prices, if needed.
  var statRight = terminal.width - 1;
  if (getPrice != null) {
    for (var item in items) {
      var price = getPrice(item);
      if (price != null) {
        statRight =
            math.min(statRight, terminal.width - formatMoney(price).length - 3);
      }
    }
  }

  var i = 0;
  var letter = 0;
  for (var item in items.slots) {
    var y = i + 2;

    // If there's no item in this equipment slot, show the slot name.
    if (item == null) {
      // Null items should only appear in equipment.
      assert(items.slotTypes != null);

      terminal.writeAt(1, y, "    (${items.slotTypes[i]})", UIHue.helpText);
      letter++;
      i++;
      continue;
    }

    var borderColor = steelGray;
    var letterColor = UIHue.secondary;
    var textColor = UIHue.primary;
    var enabled = true;

    var canSelectItem = canSelect != null ? canSelect(item) : null;
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

    terminal.writeAt(1, y, " )", borderColor);
    terminal.writeAt(1, y, letters[letter], letterColor);
    letter++;

    if (enabled) {
      terminal.drawGlyph(3, y, item.appearance as Glyph);
    }

    terminal.writeAt(5, y, item.nounText, textColor);

    if (getPrice != null && getPrice(item) != null) {
      var price = formatMoney(getPrice(item));
      terminal.writeAt(terminal.width - price.length - 1, y, price,
          enabled ? gold : UIHue.disabled);
      terminal.writeAt(terminal.width - price.length - 2, y, "\$",
          enabled ? persimmon : UIHue.disabled);
    }

    drawStat(String symbol, Object stat, Color light, Color dark) {
      var string = stat.toString();
      terminal.writeAt(statRight - string.length - 1, y, symbol,
          enabled ? dark : UIHue.disabled);
      terminal.writeAt(statRight - string.length, y, string,
          enabled ? light : UIHue.disabled);
    }

    // TODO: Eventually need to handle equipment that gives both an armor and
    // attack bonus.
    if (item.attack != null) {
      var hit = item.attack.createHit();
      drawStat("»", hit.damageString, carrot, garnet);
    } else if (item.armor != 0) {
      drawStat("•", item.armor, peaGreen, sherwood);
    }

    if (item != null && item == inspected) {
      terminal.drawChar(
          2, y, CharCode.blackRightPointingPointer, UIHue.selection);
      terminal.drawChar(terminal.width - 1, y,
          CharCode.blackRightPointingPointer, UIHue.selection);
    }

    // TODO: Show heft and weight.
    i++;
  }
}

void drawInspector(Terminal terminal, Hero hero, Item item) {
  terminal = terminal.rect(46, 0, 34, 20);

  Draw.frame(terminal, 0, 0, terminal.width, terminal.height);

  terminal.drawGlyph(1, 0, item.appearance as Glyph);
  terminal.writeAt(3, 0, item.nounText, UIHue.primary);

  var y = 2;

  writeSection(String label) {
    // Put a blank line between sections.
    if (y != 2) y++;
    terminal.writeAt(1, y, "$label:", UIHue.selection);
    y++;
  }

  writeLabel(String label) {
    terminal.writeAt(1, y, "$label:", UIHue.text);
  }

  // TODO: Mostly copied from hero_equipment_dialog. Unify.
  writeScale(int x, int y, double scale) {
    var string = scale.toStringAsFixed(1);

    var xColor = UIHue.disabled;
    var numberColor = UIHue.disabled;
    if (scale > 1.0) {
      xColor = sherwood;
      numberColor = peaGreen;
    } else if (scale < 1.0) {
      xColor = maroon;
      numberColor = brickRed;
    }

    terminal.writeAt(x, y, "x", xColor);
    terminal.writeAt(x + 1, y, string, numberColor);
  }

  // TODO: Mostly copied from hero_equipment_dialog. Unify.
  writeBonus(int x, int y, int bonus) {
    var string = bonus.abs().toString();

    if (bonus > 0) {
      terminal.writeAt(x + 2 - string.length, y, "+", sherwood);
      terminal.writeAt(x + 3 - string.length, y, string, peaGreen);
    } else if (bonus < 0) {
      terminal.writeAt(x + 2 - string.length, y, "-", maroon);
      terminal.writeAt(x + 3 - string.length, y, string, brickRed);
    } else {
      terminal.writeAt(x + 2 - string.length, y, "+", UIHue.disabled);
      terminal.writeAt(x + 3 - string.length, y, string, UIHue.disabled);
    }
  }

  writeStat(String label, Object value) {
    if (value == null) return;

    writeLabel(label);
    terminal.writeAt(12, y, value.toString(), UIHue.primary);
    y++;
  }

  // TODO: Handle armor that gives attack bonuses even though the item
  // itself has no attack.
  if (item.attack != null) {
    writeSection("Attack");

    writeLabel("Damage");
    if (item.element != Element.none) {
      terminal.writeAt(
          9, y, item.element.abbreviation, elementColor(item.element));
    }

    terminal.writeAt(12, y, item.attack.damage.toString(), UIHue.text);
    writeScale(16, y, item.damageScale);
    writeBonus(20, y, item.damageBonus);
    terminal.writeAt(25, y, "=", UIHue.secondary);

    var damage = item.attack.damage * item.damageScale + item.damageBonus;
    terminal.writeAt(27, y, damage.toStringAsFixed(2).padLeft(6), carrot);
    y++;

    if (item.strikeBonus != 0) {
      writeLabel("Strike");
      writeBonus(12, y, item.strikeBonus);
      y++;
    }

    if (item.attack.isRanged) {
      writeStat("Range", item.attack.range);
    }

    // TODO: Temp hack. The ItemScreen doesn't have access to a Hero so passes
    // in null. We should hoist the hero state that is needed in and out of
    // game up to HeroSave and pass that in instead of Hero.
    if (hero != null) {
      writeLabel("Heft");
      var strongEnough = hero.strength.value >= item.heft;
      var color = strongEnough ? UIHue.primary : brickRed;
      terminal.writeAt(12, y, item.heft.toString(), color);
      writeScale(16, y, hero.strength.heftScale(item.heft));
      y++;
    }
  }

  if (item.armor != 0) {
    writeSection("Defense");
    writeLabel("Armor");
    terminal.writeAt(12, y, item.baseArmor.toString(), UIHue.text);
    writeBonus(16, y, item.armorModifier);
    terminal.writeAt(25, y, "=", UIHue.secondary);

    var armor = item.armor.toString().padLeft(6);
    terminal.writeAt(27, y, armor, peaGreen);
    y++;

    writeStat("Weight", item.weight);
    // TODO: Encumbrance.
  }

  // TODO: Show spells for spellbooks.

  writeSection("Resistances");
  var x = 1;
  for (var element in Elements.all) {
    if (element == Element.none) continue;
    var resistance = item.resistance(element);
    writeBonus(x - 1, y, resistance);
    terminal.writeAt(x, y + 1, element.abbreviation,
        resistance == 0 ? UIHue.disabled : elementColor(element));
    x += 3;
  }
  y += 2;

  // TODO: Show the stats from each affix.

  var description = <String>[];

  // TODO: General description.
  // TODO: Equip slot.
  // TODO: Use.

  writeSection("Description");
  if (item.toss != null) {
    var toss = item.toss;

    var element = "";
    if (toss.attack.element != Element.none) {
      element = " ${toss.attack.element.name}";
    }

    description.add("It can be thrown for ${toss.attack.damage}$element"
        " damage up to range ${toss.attack.range}.");

    if (toss.breakage != 0) {
      description
          .add("It has a ${toss.breakage}% chance of breaking when thrown.");
    }

    // TODO: Describe toss use.
  }

  if (item.emanationLevel > 0) {
    description.add("It emanates ${item.emanationLevel} light.");
  }

  for (var element in item.type.destroyChance.keys) {
    description.add("It can be destroyed by ${element.name.toLowerCase()}.");
  }

  for (var line in Log.wordWrap(terminal.width - 2, description.join(" "))) {
    terminal.writeAt(1, y, line, UIHue.text);
    y++;
  }

  // TODO: Max stack size?
}

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
