import 'dart:math' as math;

import 'package:malison/malison.dart';

import '../content/elements.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';

abstract class ItemView {
  ItemCollection get items;

  bool get showLetters => true;

  bool get canSelectAny => true;

  bool get capitalize => false;

  bool get showPrices => false;

  Item get inspectedItem => null;

  bool canSelect(Item item) => false;

  int getPrice(Item item) => item.price;

  int itemY(Item item) {
    var y = 0;
    for (var thisItem in items) {
      if (thisItem == item) return y;
      y++;
    }

    return -1;
  }

  void render(Terminal terminal) {
    var letters = capitalize
        ? "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        : "abcdefghijklmnopqrstuvwxyz";

    // Shift the stats over to make room for prices, if needed.
    var statRight = terminal.width;
    if (showPrices) {
      for (var item in items) {
        var price = getPrice(item);
        if (price != null) {
          statRight = math.min(
              statRight, terminal.width - formatMoney(price).length - 2);
        }
      }
    }

    var i = 0;
    var letter = 0;
    for (var item in items.slots) {
      var y = i;

      var x = showLetters ? 2 : 0;

      // If there's no item in this equipment slot, show the slot name.
      if (item == null) {
        // Null items should only appear in equipment.
        assert(items.slotTypes != null);

        // If this is the second hand slot and the previous one has a
        // two-handed item in it, mark this one.
        if (i > 0 &&
            items.slotTypes[i] == "hand" &&
            items.slotTypes[i - 1] == "hand" &&
            items.slots.elementAt(i - 1) != null &&
            items.slots.elementAt(i - 1).type.isTwoHanded) {
          terminal.writeAt(x + 2, y, "↑ two-handed", UIHue.disabled);
        } else {
          terminal.writeAt(x + 2, y, "(${items.slotTypes[i]})", UIHue.disabled);
        }
        letter++;
        i++;
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
        terminal.writeAt(0, y, " )", borderColor);
        terminal.writeAt(0, y, letters[letter], letterColor);
      }

      letter++;

      if (enabled) {
        terminal.drawGlyph(x, y, item.appearance as Glyph);
      }

      terminal.writeAt(x + 2, y, item.nounText, textColor);

      if (showPrices && getPrice(item) != 0) {
        var price = formatMoney(getPrice(item));
        terminal.writeAt(terminal.width - price.length, y, price,
            enabled ? gold : UIHue.disabled);
        terminal.writeAt(terminal.width - price.length - 1, y, "\$",
            enabled ? tan : UIHue.disabled);
      }

      void drawStat(int symbol, Object stat, Color light, Color dark) {
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
        drawStat(
            CharCode.feminineOrdinalIndicator, hit.damageString, carrot, brown);
      } else if (item.armor != 0) {
        drawStat(CharCode.latinSmallLetterAe, item.armor, peaGreen, sherwood);
      }

      // TODO: Show heft and weight.
      i++;
    }
  }
}

void drawInspector(Terminal terminal, HeroSave hero, Item item) {
  Draw.frame(terminal, 0, 0, terminal.width, terminal.height);

  terminal.drawGlyph(1, 0, item.appearance as Glyph);
  terminal.writeAt(3, 0, item.nounText, UIHue.primary);

  var y = 2;

  void writeSection(String label) {
    // Put a blank line between sections.
    if (y != 2) y++;
    terminal.writeAt(1, y, "$label:", UIHue.selection);
    y++;
  }

  void writeLabel(String label) {
    terminal.writeAt(1, y, "$label:", UIHue.text);
  }

  // TODO: Mostly copied from hero_equipment_dialog. Unify.
  void writeScale(int x, int y, double scale) {
    var string = scale.toStringAsFixed(1);

    var xColor = UIHue.disabled;
    var numberColor = UIHue.disabled;
    if (scale > 1.0) {
      xColor = sherwood;
      numberColor = peaGreen;
    } else if (scale < 1.0) {
      xColor = maroon;
      numberColor = red;
    }

    terminal.writeAt(x, y, "x", xColor);
    terminal.writeAt(x + 1, y, string, numberColor);
  }

  // TODO: Mostly copied from hero_equipment_dialog. Unify.
  void writeBonus(int x, int y, int bonus) {
    var string = bonus.abs().toString();

    if (bonus > 0) {
      terminal.writeAt(x + 2 - string.length, y, "+", sherwood);
      terminal.writeAt(x + 3 - string.length, y, string, peaGreen);
    } else if (bonus < 0) {
      terminal.writeAt(x + 2 - string.length, y, "-", maroon);
      terminal.writeAt(x + 3 - string.length, y, string, red);
    } else {
      terminal.writeAt(x + 2 - string.length, y, "+", UIHue.disabled);
      terminal.writeAt(x + 3 - string.length, y, string, UIHue.disabled);
    }
  }

  void writeStat(String label, Object value) {
    if (value == null) return;

    writeLabel(label);
    terminal.writeAt(12, y, value.toString(), UIHue.primary);
    y++;
  }

  void writeText(String text) {
    for (var line in Log.wordWrap(terminal.width - 2, text)) {
      terminal.writeAt(1, y, line, UIHue.text);
      y++;
    }
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

    writeLabel("Heft");
    var strongEnough = hero.strength.value >= item.heft;
    var color = strongEnough ? UIHue.primary : red;
    terminal.writeAt(12, y, item.heft.toString(), color);
    writeScale(16, y, hero.strength.heftScale(item.heft));
    // TODO: Show heft when dual-wielding somehow?
    y++;
  }

  if (item.armor != 0 || item.defense != null) {
    writeSection("Defense");

    if (item.defense != null) {
      writeStat("Dodge", item.defense.amount);
    }

    if (item.armor != 0) {
      writeLabel("Armor");
      terminal.writeAt(12, y, item.baseArmor.toString(), UIHue.text);
      writeBonus(16, y, item.armorModifier);
      terminal.writeAt(25, y, "=", UIHue.secondary);

      var armor = item.armor.toString().padLeft(6);
      terminal.writeAt(27, y, armor, peaGreen);
      y++;
    }

    writeStat("Weight", item.weight);
    // TODO: Encumbrance.
  }

  // TODO: Show spells for spellbooks.

  if (item.canEquip) {
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
  }

  if (item.canUse) {
    writeSection("Use");
    writeText(item.type.use.description);
  }

  writeSection("Description");

  var description = <String>[];
  // TODO: General description.
  // TODO: Equip slot.
  for (var stat in Stat.all) {
    var bonus = 0;
    if (item.prefix != null) bonus += item.prefix.statBonus(stat);
    if (item.suffix != null) bonus += item.suffix.statBonus(stat);

    if (bonus < 0) {
      description.add("It lowers your ${stat.name} by ${-bonus}.");
    } else if (bonus > 0) {
      description.add("It raises your ${stat.name} by $bonus.");
    }
  }

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

  writeText(description.join(" "));

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
