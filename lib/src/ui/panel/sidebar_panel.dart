import 'package:malison/malison.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../../content/elements.dart';
import '../../debug.dart';
import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import '../game_screen.dart';
import '../item_view.dart';
import 'panel.dart';

// TODO: Split this into multiple panels and/or give it a better name.
// TODO: There's room at the bottom of the panel for something else. Maybe a
// mini-map?
class SidebarPanel extends Panel {
  static final _resistLetters = {
    Elements.air: "A",
    Elements.earth: "E",
    Elements.fire: "F",
    Elements.water: "W",
    Elements.acid: "A",
    Elements.cold: "C",
    Elements.lightning: "L",
    Elements.poison: "P",
    Elements.dark: "D",
    Elements.light: "L",
    Elements.spirit: "S"
  };

  final GameScreen _gameScreen;

  SidebarPanel(this._gameScreen);

  void renderPanel(Terminal terminal) {
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);

    var game = _gameScreen.game;
    var hero = game.hero;
    terminal.writeAt(2, 0, " ${hero.save.name} ", UIHue.text);
    terminal.writeAt(1, 2, "${hero.save.race.name} ${hero.save.heroClass.name}",
        UIHue.primary);

    _drawStats(hero, terminal, 4);

    // TODO: Decide on a consistent set of colors for attributes and use them
    // consistently through the UI.
    _drawHealth(hero, terminal, 7);
    _drawLevel(hero, terminal, 8);
    _drawGold(hero, terminal, 9);

    _drawArmor(hero, terminal, 10);
    _drawDefense(hero, terminal, 11);
    _drawWeapons(hero, terminal, 12);

    _drawFood(hero, terminal, 15);
    _drawFocus(hero, terminal, 16);

    // Draw the nearby monsters.
    terminal.writeAt(1, 18, "@", _gameScreen.heroColor);
    terminal.writeAt(3, 18, hero.save.name, UIHue.text);
    _drawHealthBar(terminal, 19, hero);

    var visibleMonsters = _gameScreen.stagePanel.visibleMonsters;
    visibleMonsters.sort((a, b) {
      var aDistance = (a.pos - hero.pos).lengthSquared;
      var bDistance = (b.pos - hero.pos).lengthSquared;
      return aDistance.compareTo(bDistance);
    });

    for (var i = 0; i < 10 && i < visibleMonsters.length; i++) {
      var y = 20 + i * 2;
      if (y >= terminal.height - 2) break;

      var monster = visibleMonsters[i];

      var glyph = monster.appearance as Glyph;
      if (_gameScreen.currentTargetActor == monster) {
        glyph = Glyph.fromCharCode(glyph.char, glyph.back, glyph.fore);
      }

      var name = monster.breed.name;
      if (name.length > terminal.width - 4) {
        name = name.substring(0, terminal.width - 4);
      }

      terminal.drawGlyph(1, y, glyph);
      terminal.writeAt(
          3,
          y,
          name,
          (_gameScreen.currentTargetActor == monster)
              ? UIHue.selection
              : UIHue.text);

      _drawHealthBar(terminal, y + 1, monster);
    }
  }

  void _drawStats(Hero hero, Terminal terminal, int y) {
    var x = 1;
    drawStat(StatBase stat) {
      terminal.writeAt(x, y, stat.name.substring(0, 3), UIHue.helpText);
      terminal.writeAt(
          x, y + 1, stat.value.toString().padLeft(3), UIHue.primary);
      x += (terminal.width - 4) ~/ 4;
    }

    drawStat(hero.strength);
    drawStat(hero.agility);
    drawStat(hero.fortitude);
    drawStat(hero.intellect);
    drawStat(hero.will);
  }

  void _drawHealth(Hero hero, Terminal terminal, int y) {
    _drawStat(terminal, y, "Health", hero.health, red, hero.maxHealth, maroon);
  }

  void _drawLevel(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Level", UIHue.helpText);

    var levelString = hero.level.toString();
    terminal.writeAt(
        terminal.width - levelString.length - 1, y, levelString, lightAqua);

    if (hero.level < Hero.maxLevel) {
      var levelPercent = 100 *
          (hero.experience - experienceLevelCost(hero.level)) ~/
          (experienceLevelCost(hero.level + 1) -
              experienceLevelCost(hero.level));
      Draw.thinMeter(terminal, 10, y, terminal.width - 14, levelPercent, 100,
          lightAqua, aqua);
    }
  }

  void _drawGold(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Gold", UIHue.helpText);
    var heroGold = formatMoney(hero.gold);
    terminal.writeAt(terminal.width - 1 - heroGold.length, y, heroGold, gold);
  }

  void _drawWeapons(Hero hero, Terminal terminal, int y) {
    var hits = hero.createMeleeHits(null).toList();

    var label = hits.length == 2 ? "Weapons" : "Weapon";
    terminal.writeAt(1, y, label, UIHue.helpText);

    for (var i = 0; i < hits.length; i++) {
      var hitString = hits[i].damageString;
      // TODO: Show element and other bonuses.
      terminal.writeAt(
          terminal.width - hitString.length - 1, y + i, hitString, carrot);
    }
  }

  void _drawDefense(Hero hero, Terminal terminal, int y) {
    var total = 0;
    for (var defense in hero.defenses) {
      total += defense.amount;
    }

    _drawStat(terminal, y, "Dodge", "$total%", aqua);
  }

  void _drawArmor(Hero hero, Terminal terminal, int y) {
    // Show equipment resistances.
    var x = 10;
    for (var element in Elements.all) {
      if (hero.resistance(element) > 0) {
        terminal.writeAt(x, y, _resistLetters[element], elementColor(element));
        x++;
      }
    }

    var armor = " ${(100 - getArmorMultiplier(hero.armor) * 100).toInt()}%";
    _drawStat(terminal, y, "Armor", armor, peaGreen);
  }

  void _drawFood(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Food", UIHue.helpText);
    Draw.thinMeter(terminal, 10, y, terminal.width - 11, hero.stomach,
        Option.heroMaxStomach, tan, brown);
  }

  void _drawFocus(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, 'Focus', UIHue.helpText);

    Draw.thinMeter(terminal, 10, y, terminal.width - 11, hero.focus,
        hero.intellect.maxFocus, blue, darkBlue);
  }

  /// Draws a labeled numeric stat.
  void _drawStat(
      Terminal terminal, int y, String label, value, Color valueColor,
      [int max, Color maxColor]) {
    terminal.writeAt(1, y, label, UIHue.helpText);

    var x = terminal.width - 1;
    if (max != null) {
      var maxString = max.toString();
      x -= maxString.length;
      terminal.writeAt(x, y, maxString, maxColor);

      x -= 3;
      terminal.writeAt(x, y, " / ", maxColor);
    }

    var valueString = value.toString();
    x -= valueString.length;
    terminal.writeAt(x, y, valueString, valueColor);
  }

  /// Draws a health bar for [actor].
  void _drawHealthBar(Terminal terminal, int y, Actor actor) {
    // Show conditions.
    var x = 3;

    drawCondition(String char, Color fore, [Color back]) {
      // Don't overlap other stuff.
      if (x > 8) return;

      terminal.writeAt(x, y, char, fore, back);
      x++;
    }

    if (actor is Monster && actor.isAfraid) {
      drawCondition("!", sandal);
    }

    if (actor.poison.isActive) {
      switch (actor.poison.intensity) {
        case 1:
          drawCondition("P", sherwood);
          break;
        case 2:
          drawCondition("P", peaGreen);
          break;
        default:
          drawCondition("P", mint);
          break;
      }
    }

    if (actor.cold.isActive) drawCondition("C", lightBlue);
    switch (actor.haste.intensity) {
      case 1:
        drawCondition("S", tan);
        break;
      case 2:
        drawCondition("S", gold);
        break;
      case 3:
        drawCondition("S", buttermilk);
        break;
    }

    if (actor.blindness.isActive) drawCondition("B", darkCoolGray);
    if (actor.dazzle.isActive) drawCondition("D", lilac);

    for (var element in Elements.all) {
      if (actor.resistances[element].isActive) {
        drawCondition(
            _resistLetters[element], Color.black, elementColor(element));
      }
    }

    if (Debug.showMonsterAlertness && actor is Monster) {
      var alertness = (actor.alertness * 100).toInt().toString().padLeft(3);
      terminal.writeAt(2, y, alertness, ash);
    }

    Draw.meter(terminal, 10, y, terminal.width - 11, actor.health,
        actor.maxHealth, red, maroon);
  }
}
