import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';
import 'popup.dart';

class ExitPopup extends Popup {
  /// The state of the hero before entering the dungeon.
  final HeroSave _previous;

  final Game _game;
  final List<_AnimatedValue> _values = [];

  @override
  int get width => 38;
  @override
  int get height => 19;

  @override
  Map<String, String> get helpKeys => {"OK": "Return to town"};

  ExitPopup(this._previous, this._game) {
    var hero = _game.hero;

    var y = 5;

    void add(String label, Color color, int change, {int? total}) {
      _values.add(_AnimatedValue(y++, label, change, color, total: total));
    }

    add("Gold", gold, hero.gold - _previous.gold);
    // TODO: Would be good to show experience earned without taking into account
    // any that they spent while in the dungeon.
    add("Experience", peaGreen, hero.experience - _previous.experience);

    y++;
    // TODO: Not really useful anymore now that players control this directly.
    add("Strength", blue, hero.strength.value - _previous.strength.value);
    add("Agility", blue, hero.agility.value - _previous.agility.value);
    add("Vitality", blue, hero.vitality.value - _previous.vitality.value);
    add("Intellect", blue, hero.intellect.value - _previous.intellect.value);
    add("Will", blue, hero.will.value - _previous.will.value);

    y += 3;
    var slain = hero.lore.allSlain - _previous.lore.allSlain;
    var remainingMonsters = _game.stage.actors
        .where((actor) => actor is! Hero)
        .length;
    add("Monsters", red, slain, total: slain + remainingMonsters);
  }

  @override
  bool get isTransparent => true;

  @override
  bool handleInput(Input input) {
    if (input != Input.ok) return false;

    // Remember that this depth was reached.
    _game.hero.save.maxDepth = math.max(_previous.maxDepth, _game.depth);

    ui.pop();
    return true;
  }

  @override
  void update() {
    for (var value in _values) {
      if (value.update()) dirty();
    }
  }

  @override
  void renderPopup(Terminal terminal) {
    terminal.writeAt(1, 1, "You survived depth ${_game.depth}!", UIHue.text);

    terminal.writeAt(1, 3, "You gained:", UIHue.text);
    terminal.writeAt(1, 15, "You slayed:", UIHue.text);

    for (var value in _values) {
      terminal.writeAt(
        5,
        value.y,
        "................................",
        UIHue.disabled,
      );
      terminal.writeAt(
        5,
        value.y,
        "${value.name}:",
        value.value == 0 ? UIHue.disabled : UIHue.primary,
      );

      var number = value.current.toString();
      if (value.total != null) {
        var total = value.total.toString();
        terminal.writeAt(
          terminal.width - 1 - total.length,
          value.y,
          total,
          value.color,
        );
        terminal.writeAt(
          terminal.width - 1 - total.length - 3,
          value.y,
          " / ",
          value.color,
        );
        terminal.writeAt(
          terminal.width - 4 - total.length - number.length,
          value.y,
          number,
          value.color,
        );
      } else {
        terminal.writeAt(
          terminal.width - 1 - number.length,
          value.y,
          number,
          value.value == 0 ? UIHue.disabled : value.color,
        );
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
  final int? total;

  int current = 0;

  _AnimatedValue(this.y, this.name, this.value, this.color, {this.total});

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
