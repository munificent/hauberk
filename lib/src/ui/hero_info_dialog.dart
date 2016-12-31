import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';

class HeroInfoDialog extends Screen<Input> {
  final Hero _hero;

  bool get isTransparent => true;

  HeroInfoDialog(this._hero);

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    var window = terminal.rect(0, 0, 80, 32);
    window.clear();

    // TODO: Show strike bonuses.
    // TODO: If armor can modify attack, show that.
    window.writeAt(3, 2, "Equipment", Color.gray);
    window.writeAt(40, 2, "Dam   Elem   Def ┌──── Resistance ────┐", Color.gray);

    var i = 0;
    for (var element in Element.all.skip(1)) {
      var x = 57 + i * 2;
      window.writeAt(x, 3, elementAbbreviation(element),
          elementColor(element));
      i++;
    }

    var y = 4;
    for (var item in _hero.equipment) {
      window.drawGlyph(1, y, item.appearance);
      window.writeAt(3, y, item.nounText);

      if (item.attack != null) {
        var attack = item.attack;
        window.writeAt(40, y, attack.averageDamage.toStringAsFixed(2).padLeft(6),
            Color.orange);

        if (attack.element == Element.none) {
          window.writeAt(47, y, "--", Color.darkGray);
        } else {
          window.writeAt(47, y, elementAbbreviation(attack.element),
              elementColor(attack.element));
        }
      }

      if (item.armor != 0) {
        window.writeAt(53, y, item.armor.toString().padLeft(3));
      }

      var i = 0;
      for (var element in Element.all.skip(1)) {
        var x = 57 + i * 2;
        var resistance = item.resistance(element);
        var color = Color.darkGray;
        if (resistance > 1) {
          color = Color.lightGreen;
        } else if (resistance == 1) {
          color = Color.green;
        } else if (resistance == -1) {
          color = Color.red;
        } else if (resistance < -1) {
          color = Color.lightRed;
        }

        window.writeAt(x, y, item.resistance(element).toString().padLeft(2),
            color);
        i++;
      }

      y++;
    }

    var bar = new Glyph.fromCharCode(
        CharCode.boxDrawingsLightHorizontal, Color.darkGray);
    for (var x = 0; x < window.width; x++) {
      terminal.drawGlyph(x, window.height - 1, bar);
    }

    window.writeAt((window.width - 12) ~/ 2, window.height - 1,
        ' [Esc] Exit ', Color.gray);
  }

  // TODO: Unify these colors and abbreviations with how the game
  // screen shows resists, the colors used for ball attacks, etc.
  String elementAbbreviation(Element element) {
    return const {
      Element.none: "--",
      Element.air: "Ai",
      Element.earth: "Ea",
      Element.fire: "Fi",
      Element.water: "Wa",
      Element.acid: "Ac",
      Element.cold: "Co",
      Element.lightning: "Ln",
      Element.poison: "Po",
      Element.dark: "Da",
      Element.light: "Li",
      Element.spirit: "Sp"
    }[element];
  }

  Color elementColor(Element element) {
    return const {
      Element.none: Color.darkGray,
      Element.air: Color.lightAqua,
      Element.earth: Color.brown,
      Element.fire: Color.orange,
      Element.water: Color.blue,
      Element.acid: Color.darkYellow,
      Element.cold: Color.lightBlue,
      Element.lightning: Color.lightPurple,
      Element.poison: Color.green,
      Element.dark: Color.gray,
      Element.light: Color.white,
      Element.spirit: Color.purple
    }[element];
  }
}
