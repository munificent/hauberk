import 'package:malison/malison.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../content/elements.dart';
import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';

// TODO: Split this into multiple panels and/or give it a better name.
class SidebarPanel {
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

  void render(
      Terminal terminal, Color heroColor, List<Monster> visibleMonsters) {
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);

    var game = _gameScreen.game;
    var hero = game.hero;
    terminal.writeAt(2, 0, " ${hero.save.name} ", UIHue.text);
    terminal.writeAt(
        1, 2, "${hero.save.race.name} ${hero.save.heroClass.name}", UIHue.text);

    _drawStat(
        terminal, 4, 'Health', hero.health, brickRed, hero.maxHealth, maroon);
    terminal.writeAt(1, 5, 'Food', UIHue.helpText);
    Draw.meter(terminal, 10, 5, 10, hero.stomach, Option.heroMaxStomach,
        persimmon, garnet);

    _drawStat(terminal, 6, 'Level', hero.level, cerulean);
    if (hero.level < Hero.maxLevel) {
      var levelPercent = 100 *
          (hero.experience - experienceLevelCost(hero.level)) ~/
          (experienceLevelCost(hero.level + 1) -
              experienceLevelCost(hero.level));
      terminal.writeAt(15, 6, '$levelPercent%', ultramarine);
    }

    var x = 1;
    drawStat(StatBase stat) {
      terminal.writeAt(x, 8, stat.name.substring(0, 3), UIHue.helpText);
      terminal.writeAt(x, 9, stat.value.toString().padLeft(3), UIHue.text);
      x += 4;
    }

    drawStat(hero.strength);
    drawStat(hero.agility);
    drawStat(hero.fortitude);
    drawStat(hero.intellect);
    drawStat(hero.will);

    terminal.writeAt(1, 11, 'Focus', UIHue.helpText);

    Draw.meter(terminal, 10, 11, 10, hero.focus, hero.intellect.maxFocus,
        cerulean, ultramarine);

    _drawStat(terminal, 13, 'Armor',
        '${(100 - getArmorMultiplier(hero.armor) * 100).toInt()}% ', peaGreen);
    // TODO: Show the weapon and stats better.
    var hit = hero.createMeleeHit(null);
    _drawStat(terminal, 14, 'Weapon', hit.damageString, turquoise);

    // Draw the nearby monsters.
    terminal.writeAt(1, 16, '@', heroColor);
    terminal.writeAt(3, 16, hero.save.name, UIHue.text);
    _drawHealthBar(terminal, 17, hero);

    visibleMonsters.sort((a, b) {
      var aDistance = (a.pos - hero.pos).lengthSquared;
      var bDistance = (b.pos - hero.pos).lengthSquared;
      return aDistance.compareTo(bDistance);
    });

    for (var i = 0; i < 10; i++) {
      var y = 18 + i * 2;
      if (i < visibleMonsters.length) {
        var monster = visibleMonsters[i];

        var glyph = monster.appearance as Glyph;
        if (_gameScreen.currentTargetActor == monster) {
          glyph = Glyph.fromCharCode(glyph.char, glyph.back, glyph.fore);
        }

        terminal.drawGlyph(1, y, glyph);
        terminal.writeAt(
            3,
            y,
            monster.breed.name,
            (_gameScreen.currentTargetActor == monster)
                ? UIHue.selection
                : UIHue.text);

        _drawHealthBar(terminal, y + 1, monster);
      }
    }
  }

  /// Draws a labeled numeric stat.
  void _drawStat(
      Terminal terminal, int y, String label, value, Color valueColor,
      [max, Color maxColor]) {
    terminal.writeAt(1, y, label, UIHue.helpText);
    var valueString = value.toString();
    terminal.writeAt(11, y, valueString, valueColor);

    if (max != null) {
      terminal.writeAt(11 + valueString.length, y, ' / $max', maxColor);
    }
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

    if (actor.cold.isActive) drawCondition("C", cornflower);
    switch (actor.haste.intensity) {
      case 1:
        drawCondition("S", persimmon);
        break;
      case 2:
        drawCondition("S", gold);
        break;
      case 3:
        drawCondition("S", buttermilk);
        break;
    }

    if (actor.blindness.isActive) drawCondition("B", steelGray);
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

    Draw.meter(
        terminal, 10, y, 10, actor.health, actor.maxHealth, brickRed, maroon);
  }
}
