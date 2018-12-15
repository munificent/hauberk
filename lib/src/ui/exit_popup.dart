import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';
import 'popup.dart';

class ExitPopup extends Popup {
  final HeroSave _save;
  final Game _game;
  final List<_AnimatedValue> _values = [];

  int get width => 38;
  int get height => 19;

  Map<String, String> get helpKeys => {"OK": "Return to town"};

  ExitPopup(this._save, this._game) {
    var hero = _game.hero;

    _values.add(_AnimatedValue(5, "Gold", hero.gold - _save.gold, gold));
    _values.add(_AnimatedValue(
        6, "Experience", hero.experience - _save.experience, peaGreen));
    _values
        .add(_AnimatedValue(7, "Levels", hero.level - _save.level, turquoise));

    _values.add(_AnimatedValue(
        9, "Strength", hero.strength.value - _save.strength.value, cerulean));
    _values.add(_AnimatedValue(
        10, "Agility", hero.agility.value - _save.agility.value, cerulean));
    _values.add(_AnimatedValue(11, "Fortitude",
        hero.fortitude.value - _save.fortitude.value, cerulean));
    _values.add(_AnimatedValue(12, "Intellect",
        hero.intellect.value - _save.intellect.value, cerulean));
    _values.add(_AnimatedValue(
        13, "Will", hero.will.value - _save.will.value, cerulean));

    var slain = hero.lore.allSlain - _save.lore.allSlain;
    var remainingMonsters =
        _game.stage.actors.where((actor) => actor is! Hero).length;
    _values.add(_AnimatedValue(17, "Monsters", slain, brickRed,
        total: slain + remainingMonsters));
  }

  bool get isTransparent => true;

  bool handleInput(Input input) {
    if (input != Input.ok) return false;

    // Remember that this depth was reached.
    _game.hero.save.maxDepth = math.max(_save.maxDepth, _game.depth);

    // Update shops.
    _game.hero.save.shops.forEach((shop, inventory) {
      shop.update(inventory);
    });

    ui.pop();
    return true;
  }

  void update() {
    for (var value in _values) {
      if (value.update()) dirty();
    }
  }

  void renderPopup(Terminal terminal) {
    terminal.writeAt(1, 1, "You survived depth ${_game.depth}!", UIHue.text);

    terminal.writeAt(1, 3, "You gained:", UIHue.text);
    terminal.writeAt(1, 15, "You slayed:", UIHue.text);

    for (var value in _values) {
      terminal.writeAt(
          5, value.y, "................................", UIHue.disabled);
      terminal.writeAt(5, value.y, "${value.name}:",
          value.value == 0 ? UIHue.disabled : UIHue.primary);

      var number = value.current.toString();
      if (value.total != null) {
        var total = value.total.toString();
        terminal.writeAt(
            terminal.width - 1 - total.length, value.y, total, value.color);
        terminal.writeAt(
            terminal.width - 1 - total.length - 3, value.y, " / ", value.color);
        terminal.writeAt(terminal.width - 4 - total.length - number.length,
            value.y, number, value.color);
      } else {
        terminal.writeAt(terminal.width - 1 - number.length, value.y, number,
            value.value == 0 ? UIHue.disabled : value.color);
      }
    }

    // TODO: Skills.
    // TODO: Items?
    // TODO: Show how much of stage was explored.
    // TODO: Slain uniques.
    // TODO: Achievements?
  }
}

class _AnimatedValue {
  final int y;
  final String name;
  final int value;
  final Color color;
  final int total;

  int current;

  _AnimatedValue(this.y, this.name, this.value, this.color, {this.total})
      : current = 0;

  bool update() {
    if (current >= value) return false;

    if (value > 200) {
      current += rng.round(value / 200);
      if (current > value) current = value;
    } else {
      current++;
    }

    return true;
  }
}
