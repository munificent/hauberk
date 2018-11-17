import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

class ExitScreen extends Screen<Input> {
  final HeroSave _save;
  final Game _game;
  final List<_AnimatedValue> _values = [];

  ExitScreen(this._save, this._game) {
    var hero = _game.hero;

    _values.add(_AnimatedValue(6, "Gold", hero.gold - _save.gold, gold));
    _values.add(_AnimatedValue(
        7, "Experience", hero.experience - _save.experience, peaGreen));
    _values
        .add(_AnimatedValue(8, "Levels", hero.level - _save.level, turquoise));

    _values.add(_AnimatedValue(
        10, "Strength", hero.strength.value - _save.strength.value, cerulean));
    _values.add(_AnimatedValue(
        11, "Agility", hero.agility.value - _save.agility.value, cerulean));
    _values.add(_AnimatedValue(12, "Fortitude",
        hero.fortitude.value - _save.fortitude.value, cerulean));
    _values.add(_AnimatedValue(13, "Intellect",
        hero.intellect.value - _save.intellect.value, cerulean));
    _values.add(_AnimatedValue(
        14, "Will", hero.will.value - _save.will.value, cerulean));

    var slain = hero.lore.allSlain - _save.lore.allSlain;
    var remainingMonsters =
        _game.stage.actors.where((actor) => actor is! Hero).length;
    _values.add(_AnimatedValue(18, "Monsters", slain, brickRed,
        total: slain + remainingMonsters));
  }

  bool get isTransparent => true;

  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        _done();
        return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.enter:
        _done();
        return true;
    }

    return false;
  }

  void _done() {
    _save.takeFrom(_game.hero);

    // Remember that this depth was reached.
    _save.maxDepth = math.max(_save.maxDepth, _game.depth);

    // Update shops.
    // TODO: Take how long the hero was in the dungeon into account.
    _save.shops.forEach((shop, inventory) {
      shop.update(inventory);
    });

    ui.pop();
  }

  void update() {
    for (var value in _values) {
      if (value.update()) dirty();
    }
  }

  void render(Terminal terminal) {
    terminal = terminal.rect(10, 5, 40, 30);
    terminal.clear();

    Draw.doubleBox(terminal, 0, 0, terminal.width, terminal.height, gold);

    terminal.writeAt(2, 2, "You survived depth ${_game.depth}!", UIHue.text);

    terminal.writeAt(2, 4, "You gained:", UIHue.text);
    terminal.writeAt(2, 16, "You slayed:", UIHue.text);

    for (var value in _values) {
      terminal.writeAt(
          6, value.y, "................................", UIHue.disabled);
      terminal.writeAt(6, value.y, "${value.name}:",
          value.value == 0 ? UIHue.disabled : UIHue.primary);

      var number = value.current.toString();
      if (value.total != null) {
        var total = value.total.toString();
        terminal.writeAt(
            terminal.width - 2 - total.length, value.y, total, value.color);
        terminal.writeAt(
            terminal.width - 2 - total.length - 3, value.y, " / ", value.color);
        terminal.writeAt(terminal.width - 5 - total.length - number.length,
            value.y, number, value.color);
      } else {
        terminal.writeAt(terminal.width - 2 - number.length, value.y, number,
            value.value == 0 ? UIHue.disabled : value.color);
      }
    }

    // TODO: Skills.
    // TODO: Items?
    // TODO: Show how much of stage was explored.
    // TODO: Slain uniques.
    // TODO: Achievements?

    var help = " [Enter] Return to town ";
    terminal.writeAt(
        (terminal.width - help.length) ~/ 2, terminal.height - 1, help, gold);
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
    if (current == value) return false;

    if (value > 200) {
      current += rng.round(value / 200);
      if (current > value) current = value;
    } else {
      current++;
    }

    return true;
  }
}
