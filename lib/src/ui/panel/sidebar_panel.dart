import 'package:malison/malison.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../../content/elements.dart';
import '../../debug.dart';
import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import '../game_screen.dart';
import '../item/item_renderer.dart';
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
    Elements.spirit: "S",
  };

  final GameScreen _gameScreen;

  SidebarPanel(this._gameScreen);

  @override
  void renderPanel(Terminal terminal) {
    var game = _gameScreen.game;
    var hero = game.hero;

    Draw.frame(terminal, label: hero.save.name);

    terminal.writeAt(
      1,
      2,
      "${hero.save.race.name} ${hero.save.heroClass.name}",
      UIHue.primary,
    );

    _drawStats(hero, terminal, 4);

    // TODO: Decide on a consistent set of colors for attributes and use them
    // consistently through the UI.
    _drawHealth(hero, terminal, 7);
    _drawExperience(hero, terminal, 8);
    _drawGold(hero, terminal, 9);

    _drawArmor(hero, terminal, 10);
    _drawDefense(hero, terminal, 11);
    _drawWeapons(hero, terminal, 12);

    _drawFood(hero, terminal, 15);
    _drawFocus(hero, terminal, 16);
    _drawFury(hero, terminal, 17);

    // Draw the nearby monsters.
    terminal.writeAt(1, 19, "@", _gameScreen.heroColor);
    terminal.writeAt(3, 19, hero.save.name, UIHue.text);
    _drawHealthBar(terminal, 20, hero);

    var visibleMonsters = _gameScreen.stagePanel.visibleMonsters;
    visibleMonsters.sort((a, b) {
      var aDistance = (a.pos - hero.pos).lengthSquared;
      var bDistance = (b.pos - hero.pos).lengthSquared;
      return aDistance.compareTo(bDistance);
    });

    for (var i = 0; i < 10 && i < visibleMonsters.length; i++) {
      var y = 21 + i * 2;
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
            : UIHue.text,
      );

      _drawHealthBar(terminal, y + 1, monster);
    }
  }

  void _drawStats(Hero hero, Terminal terminal, int y) {
    var x = 1;
    void drawStat(StatBase stat) {
      terminal.writeAt(x, y, stat.name.substring(0, 3), UIHue.helpText);
      terminal.writeAt(
        x,
        y + 1,
        stat.value.toString().padLeft(2),
        UIHue.primary,
      );
      x += (terminal.width - 4) ~/ 3;
    }

    drawStat(hero.strength);
    drawStat(hero.agility);
    drawStat(hero.vitality);
    drawStat(hero.intellect);
  }

  void _drawHealth(Hero hero, Terminal terminal, int y) {
    _drawStat(terminal, y, "Health", hero.health, red, hero.maxHealth, maroon);
  }

  void _drawExperience(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Exp", UIHue.helpText);

    var experienceString = hero.experience.toString();
    terminal.writeAt(
      terminal.width - experienceString.length - 1,
      y,
      experienceString,
      lightAqua,
    );
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
        terminal.width - hitString.length - 1,
        y + i,
        hitString,
        carrot,
      );
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
        terminal.writeAt(x, y, _resistLetters[element]!, elementColor(element));
        x++;
      }
    }

    var armor = " ${(100 - getArmorMultiplier(hero.armor) * 100).toInt()}%";
    _drawStat(terminal, y, "Armor", armor, peaGreen);
  }

  void _drawFood(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Food", UIHue.helpText);
    Draw.thinMeter(
      terminal,
      10,
      y,
      terminal.width - 11,
      hero.stomach,
      Option.heroMaxStomach,
      tan,
      brown,
    );
  }

  void _drawFocus(Hero hero, Terminal terminal, int y) {
    // TODO: Show bar once these are tuned.
    // terminal.writeAt(1, y, 'Focus', UIHue.helpText);
    // Draw.thinMeter(terminal, 10, y, terminal.width - 11, hero.focus,
    //     hero.intellect.maxFocus, blue, darkBlue);
    _drawStat(
      terminal,
      y,
      'Focus',
      hero.focus,
      blue,
      hero.intellect.maxFocus,
      darkBlue,
    );
  }

  void _drawFury(Hero hero, Terminal terminal, int y) {
    // If the hero can't have any fury, gray it out.
    terminal.writeAt(
      1,
      y,
      'Fury',
      hero.strength.maxFury == 0 ? UIHue.disabled : UIHue.helpText,
    );

    terminal.writeAt(
      terminal.width - 3,
      y,
      hero.fury.toString().padLeft(2),
      persimmon,
    );

    if (hero.fury > 0) {
      var scale = "${hero.strength.furyScale(hero.fury).toStringAsFixed(1)}x";
      terminal.writeAt(
        10,
        y,
        scale.padLeft(4),
        hero.fury == hero.strength.maxFury ? carrot : persimmon,
      );
    }
  }

  /// Draws a labeled numeric stat.
  void _drawStat(
    Terminal terminal,
    int y,
    String label,
    Object value,
    Color valueColor, [
    int? max,
    Color? maxColor,
  ]) {
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

    void drawCondition(String char, Color fore, [Color? back]) {
      // Don't overlap other stuff.
      if (x > 8) return;

      terminal.writeAt(x, y, char, fore, back);
      x++;
    }

    if (actor is Monster && actor.isAfraid) {
      drawCondition("!", sandal);
    }

    if (actor is Monster && actor.isAsleep) {
      drawCondition("z", darkBlue);
    }

    if (actor.poison.isActive) {
      switch (actor.poison.intensity) {
        case 1:
          drawCondition("P", sherwood);
        case 2:
          drawCondition("P", peaGreen);
        default:
          drawCondition("P", mint);
      }
    }

    if (actor.cold.isActive) drawCondition("C", lightBlue);
    switch (actor.haste.intensity) {
      case 1:
        drawCondition("S", tan);
      case 2:
        drawCondition("S", gold);
      case 3:
        drawCondition("S", buttermilk);
    }

    if (actor.blindness.isActive) drawCondition("B", darkCoolGray);
    if (actor.dazzle.isActive) drawCondition("D", lilac);
    if (actor.perception.isActive) drawCondition("V", ash);

    for (var element in Elements.all) {
      if (actor.resistanceCondition(element).isActive) {
        drawCondition(
          _resistLetters[element]!,
          Color.black,
          elementColor(element),
        );
      }
    }

    if (Debug.showMonsterAlertness && actor is Monster) {
      var alertness = (actor.alertness * 100).toInt().toString().padLeft(3);
      terminal.writeAt(2, y, alertness, ash);
    }

    Draw.meter(
      terminal,
      10,
      y,
      terminal.width - 11,
      actor.health,
      actor.maxHealth,
      red,
      maroon,
    );
  }
}
