library hauberk.ui.game_screen;

import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'close_door_dialog.dart';
import 'effect.dart';
import 'game_over_screen.dart';
import 'forfeit_dialog.dart';
import 'input.dart';
import 'item_dialog.dart';
import 'select_command_dialog.dart';
import 'target_dialog.dart';

class GameScreen extends Screen {
  final HeroSave _save;
  final Game     _game;
  List<Effect>   _effects = <Effect>[];

  /// The size of the [Stage] view area.
  final Vec viewSize = new Vec(80, 34);

  /// The portion of the [Stage] currently in view on screen.
  Rect _cameraBounds;
  Rect get cameraBounds => _cameraBounds;

  /// The currently targeted actor, if any.
  Actor get target {
    // Make sure the target is still valid.
    if (_target != null) {
      if (!_target.isAlive || !_target.isVisible) _target = null;
    }

    return _target;
  }

  set target(Actor value) {
    if (_target == value) return;
    _target = value;
    dirty();
  }
  Actor _target;

  /// The most recently performed command.
  Command _lastCommand;

  GameScreen(this._save, this._game) {
    _positionCamera();
  }

  bool handleInput(Input input) {
    var action;

    switch (input) {
      case Input.QUIT:
        if (_game.quest.isComplete) {
          _save.copyFrom(_game.hero);

          // Remember that this level was completed.
          var completed = _save.completedLevels[_game.area.name];
          if (completed == null || completed < _game.level + 1) {
            _save.completedLevels[_game.area.name] = _game.level + 1;
          }

          ui.pop(true);
        } else {
          _game.log.error('You have not completed your quest yet:');
          _game.quest.announce(_game.log);
          dirty();
        }
        break;

      case Input.FORFEIT: ui.push(new ForfeitDialog(_game)); break;
      case Input.SELECT_COMMAND: ui.push(new SelectCommandDialog(_game)); break;
      case Input.DROP: ui.push(new ItemDialog.drop(_game)); break;
      case Input.USE: ui.push(new ItemDialog.use(_game)); break;

      case Input.REST:
        if (!_game.hero.rest()) {
          // Show the message.
          dirty();
        }
        break;

      case Input.CLOSE_DOOR: closeDoor(); break;
      case Input.PICK_UP: action = new PickUpAction(); break;

      case Input.NW: action = new WalkAction(Direction.NW); break;
      case Input.N: action = new WalkAction(Direction.N); break;
      case Input.NE: action = new WalkAction(Direction.NE); break;
      case Input.W: action = new WalkAction(Direction.W); break;
      case Input.OK: action = new WalkAction(Direction.NONE); break;
      case Input.E: action = new WalkAction(Direction.E); break;
      case Input.SW: action = new WalkAction(Direction.SW); break;
      case Input.S: action = new WalkAction(Direction.S); break;
      case Input.SE: action = new WalkAction(Direction.SE); break;

      case Input.RUN_NW: _game.hero.run(Direction.NW); break;
      case Input.RUN_N: _game.hero.run(Direction.N); break;
      case Input.RUN_NE: _game.hero.run(Direction.NE); break;
      case Input.RUN_W: _game.hero.run(Direction.W); break;
      case Input.RUN_E: _game.hero.run(Direction.E); break;
      case Input.RUN_SW: _game.hero.run(Direction.SW); break;
      case Input.RUN_S: _game.hero.run(Direction.S); break;
      case Input.RUN_SE: _game.hero.run(Direction.SE); break;

      case Input.FIRE_NW: fireAt(_game.hero.pos + Direction.NW); break;
      case Input.FIRE_N: fireAt(_game.hero.pos + Direction.N); break;
      case Input.FIRE_NE: fireAt(_game.hero.pos + Direction.NE); break;
      case Input.FIRE_W: fireAt(_game.hero.pos + Direction.W); break;
      case Input.FIRE_E: fireAt(_game.hero.pos + Direction.E); break;
      case Input.FIRE_SW: fireAt(_game.hero.pos + Direction.SW); break;
      case Input.FIRE_S: fireAt(_game.hero.pos + Direction.S); break;
      case Input.FIRE_SE: fireAt(_game.hero.pos + Direction.SE); break;

      case Input.FIRE:
        if (_lastCommand == null) {
          // Haven't picked a command yet, so select one.
          ui.push(new SelectCommandDialog(_game));
        } else if (!_lastCommand.canUse(_game)) {
          // Show the message.
          dirty();
        } else if (_lastCommand.needsTarget) {
          // If we still have a visible target, use it.
          if (target != null && target.isAlive &&
              _game.stage[target.pos].visible) {
            fireAt(target.pos);
          } else {
            // No current target, so ask for one.
            ui.push(new TargetDialog(this, _game, _lastCommand));
          }
        } else {
          useLastSkill(null);
        }
        break;

      case Input.SWAP:
        if (_game.hero.inventory.lastUnequipped == -1) {
          _game.log.error("You aren't holding an unequipped item to swap.");
          dirty();
        } else {
          action = new EquipAction(_game.hero.inventory.lastUnequipped, false);
        }
        break;
    }

    if (action != null) _game.hero.setNextAction(action);

    return true;
  }

  void closeDoor() {
    // See how many adjacent open doors there are.
    final doors = [];
    for (final direction in Direction.ALL) {
      final pos = _game.hero.pos + direction;
      if (_game.stage[pos].type.closesTo != null) {
        doors.add(pos);
      }
    }

    if (doors.length == 0) {
      _game.log.error('You are not next to an open door.');
      dirty();
    } else if (doors.length == 1) {
      _game.hero.setNextAction(new CloseDoorAction(doors[0]));
    } else {
      ui.push(new CloseDoorDialog(_game));
    }
  }

  void fireAt(Vec pos) {
    if (_lastCommand == null || !_lastCommand.needsTarget) return;

    if (!_lastCommand.canUse(_game)) {
      // Refresh the log.
      dirty();
      return;
    }

    // If we aren't firing at the current target, see if there is a monster
    // in that direction that we can target. (In other words, if you fire in
    // a raw direction, target the monster in that direction for subsequent
    // shots).
    if (target == null || target.pos != pos) {
      for (var step in new Los(_game.hero.pos, pos)) {
        // Stop if we hit a wall.
        if (!_game.stage[step].isTransparent) break;

        // See if there is an actor there.
        final actor = _game.stage.actorAt(step);
        if (actor != null) {
          target = actor;
          break;
        }
      }
    }

    useLastSkill(target.pos);
  }

  void useLastSkill(Vec target) {
    _game.hero.setNextAction(_lastCommand.getUseAction(_game, target));
  }

  void activate(Screen popped, result) {
    if (popped is ForfeitDialog && result) {
      // Forfeiting, so exit.
      ui.pop(false);
    } else if (popped is SelectCommandDialog && result is Command) {
      _lastCommand = result;

      if (!result.canUse(_game)) {
        // Refresh the log.
        dirty();
      } else if (result.needsTarget) {
        ui.push(new TargetDialog(this, _game, result));
      } else {
        useLastSkill(null);
      }
    } else if (popped is TargetDialog && result) {
      fireAt(target.pos);
    }
  }

  void update() {
    if (_effects.length > 0) dirty();

    var result = _game.update();

    // See if the hero died.
    if (!_game.hero.isAlive) {
      ui.goTo(new GameOverScreen());
      return;
    }

    if (_game.hero.dazzle.isActive) dirty();

    for (final event in result.events) addEffects(_effects, event);

    if (result.needsRefresh) dirty();

    _effects = _effects.where((effect) => effect.update(_game)).toList();
    _positionCamera();
  }

  void render(Terminal terminal) {
    terminal.clear();

    var bar = new Glyph.fromCharCode(
        CharCode.BOX_DRAWINGS_LIGHT_VERTICAL, Color.DARK_GRAY);
    for (var y = 0; y < terminal.height; y++) {
      terminal.drawGlyph(80, y, bar);
    }

    var hero = _game.hero;
    var heroColor = Color.WHITE;
    if (hero.health.current < hero.health.max / 4) {
      heroColor = Color.RED;
    } else if (hero.poison.isActive) {
      heroColor = Color.GREEN;
    } else if (hero.cold.isActive) {
      heroColor = Color.LIGHT_BLUE;
    } else if (hero.health.current < hero.health.max / 2) {
      heroColor = Color.LIGHT_RED;
    } else {
      heroColor = Color.WHITE;
    }

    var visibleMonsters = [];

    _drawStage(terminal.rect(0, 0, viewSize.x, viewSize.y), heroColor,
        visibleMonsters);
    _drawLog(terminal.rect(0, 34, 80, 6));
    _drawSidebar(terminal.rect(81, 0, 20, 40), heroColor, visibleMonsters);
  }

  /// Draws [Glyph] at [x], [y] in [Stage] coordinates onto the current view.
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    terminal.drawGlyph(x - _cameraBounds.x, y - _cameraBounds.y, glyph);
  }

  /// Determines which portion of the [Stage] should be in view based on the
  /// position of the [Hero].
  void _positionCamera() {
        var camera = _game.hero.pos - viewSize ~/ 2;
    var cameraRange = new Rect(0, 0,
        _game.stage.width - viewSize.x,
        _game.stage.height - viewSize.y);

    camera = cameraRange.clamp(camera);
    _cameraBounds = new Rect.posAndSize(camera, viewSize);
  }

  void _drawStage(Terminal terminal, Color heroColor,
      List<Actor> visibleMonsters) {
    var hero = _game.hero;

    dazzleGlyph(Glyph glyph) {
      if (!hero.dazzle.isActive) return glyph;

      var chance = 10 + math.min(80, hero.dazzle.duration * 10);
      if (rng.range(100) > chance) return glyph;

      var colors = [Color.AQUA, Color.BLUE, Color.PURPLE, Color.RED,
          Color.ORANGE, Color.GOLD, Color.YELLOW, Color.GREEN];
      var char = (rng.range(100) > chance) ? glyph.char : CharCode.ASTERISK;
      return new Glyph.fromCharCode(char, rng.item(colors));
    }

    // Draw the tiles.
    for (var pos in _cameraBounds) {
      var tile = _game.stage[pos];
      var glyph;
      if (tile.isExplored) {
        glyph = tile.type.appearance[tile.visible ? 0 : 1];
        if (tile.visible) glyph = dazzleGlyph(glyph);
        drawStageGlyph(terminal, pos.x, pos.y, glyph);
      }
    }

    // Draw the items.
    for (var item in _game.stage.items) {
      if (!_game.stage[item.pos].isExplored) continue;
      var glyph = dazzleGlyph(item.appearance);
      drawStageGlyph(terminal, item.x, item.y, glyph);
    }

    // Draw the actors.
    for (var actor in _game.stage.actors) {
      if (!_game.stage[actor.pos].visible) continue;

      var glyph = actor.appearance;
      if (glyph is! Glyph) {
        glyph = new Glyph('@', heroColor);
      }

      // If the actor is being targeted, invert its colors.
      if (target == actor) {
        glyph = new Glyph.fromCharCode(glyph.char, glyph.back, glyph.fore);
      }

      if (actor is! Hero) glyph = dazzleGlyph(glyph);

      drawStageGlyph(terminal, actor.x, actor.y, glyph);

      if (actor is Monster) visibleMonsters.add(actor);
    }

    // Draw the effects.
    for (var effect in _effects) {
      effect.render(_game, (x, y, glyph) {
        drawStageGlyph(terminal, x, y, glyph);
      });
    }
  }

  void _drawLog(Terminal terminal) {
    var y = 0;

    for (final message in _game.log.messages) {
      var color;
      switch (message.type) {
        case LogType.MESSAGE: color = Color.WHITE; break;
        case LogType.ERROR: color = Color.RED; break;
        case LogType.QUEST: color = Color.PURPLE; break;
        case LogType.GAIN: color = Color.GOLD; break;
        case LogType.HELP: color = Color.GREEN; break;
      }

      terminal.writeAt(0, y, message.text, color);
      if (message.count > 1) {
        terminal.writeAt(message.text.length, y, ' (x${message.count})',
            Color.GRAY);
      }
      y++;
    }
  }

  void _drawSidebar(Terminal terminal, Color heroColor,
      List<Actor> visibleMonsters) {
    var hero = _game.hero;
    _drawStat(terminal, 0, 'Health', hero.health.current, Color.RED,
        hero.health.max, Color.DARK_RED);
    terminal.writeAt(0, 1, 'Food', Color.GRAY);
    terminal.writeAt(7, 1, hero.food.ceil().toString(), Color.ORANGE);

    _drawStat(terminal, 2, 'Level', hero.level, Color.AQUA);
    var levelPercent = 100 * hero.experience ~/
        (calculateLevelCost(hero.level + 1) -
        calculateLevelCost(hero.level));
    terminal.writeAt(16, 2, '$levelPercent%', Color.DARK_AQUA);
    _drawStat(terminal, 3, 'Armor',
        '${(100 - getArmorMultiplier(hero.armor) * 100).toInt()}% ',
        Color.GREEN);
    // TODO: Show the weapon and stats better.
    _drawStat(terminal, 4, 'Weapon', hero.getAttack(null), Color.YELLOW);

    terminal.writeAt(0, 6, hero.heroClass.name);
    if (hero.heroClass is Warrior) _drawWarriorStats(terminal, hero);

    // Draw the nearby monsters.
    terminal.writeAt(0, 16, '@', heroColor);
    terminal.writeAt(2, 16, _save.name);
    _drawHealthBar(terminal, 17, hero);

    visibleMonsters.sort((a, b) {
      var aDistance = (a.pos - _game.hero.pos).lengthSquared;
      var bDistance = (b.pos - _game.hero.pos).lengthSquared;
      return aDistance.compareTo(bDistance);
    });

    for (var i = 0; i < 10; i++) {
      var y = 18 + i * 2;
      if (i < visibleMonsters.length) {
        var monster = visibleMonsters[i];

        var glyph = monster.appearance;
        if (target == monster) {
          glyph = new Glyph.fromCharCode(glyph.char, glyph.back, glyph.fore);
        }

        terminal.drawGlyph(0, y, glyph);
        terminal.writeAt(2, y, monster.breed.name,
            (target == monster) ? Color.YELLOW : Color.WHITE);

        _drawHealthBar(terminal, y + 1, monster);
      }
    }

    // Draw the unseen items.
    terminal.writeAt(0, 38, "Unfound items:", Color.GRAY);
    var unseen = _game.stage.items.where(
        (item) => !_game.stage[item.pos].isExplored).toList();
    unseen.sort();
    // Show the "best" ones first.
    var x = 0;
    var lastGlyph;
    for (var item in unseen.reversed) {
      if (item.appearance != lastGlyph) {
        terminal.drawGlyph(x, 39, item.appearance);
        x++;
        if (x >= terminal.width) break;
        lastGlyph = item.appearance;
      }
    }
  }

  /// Draws a labeled numeric stat.
  void _drawStat(Terminal terminal, int y, String label, value,
      Color valueColor, [max, Color maxColor]) {
    terminal.writeAt(0, y, label, Color.GRAY);
    var valueString = value.toString();
    terminal.writeAt(7, y, valueString, valueColor);

    if (max != null) {
      terminal.writeAt(7 + valueString.length, y, ' / $max', maxColor);
    }
  }

  /// Draws a health bar for [actor].
  void _drawHealthBar(Terminal terminal, int y, Actor actor) {
    // Show conditions.
    var conditions = [];

    if (actor is Monster && actor.isAfraid) {
      conditions.add(["F", Color.YELLOW]);
    }

    if (actor.poison.isActive) {
      switch (actor.poison.intensity) {
        case 1: conditions.add(["P", Color.DARK_GREEN]); break;
        case 2: conditions.add(["P", Color.GREEN]); break;
        default: conditions.add(["P", Color.LIGHT_GREEN]); break;
      }
    }

    if (actor.cold.isActive) conditions.add(["C", Color.LIGHT_BLUE]);
    switch (actor.haste.intensity) {
      case 1: conditions.add(["S", Color.DARK_GOLD]); break;
      case 2: conditions.add(["S", Color.GOLD]); break;
      case 3: conditions.add(["S", Color.LIGHT_GOLD]); break;
    }

    if (actor.dazzle.isActive) conditions.add(["D", Color.LIGHT_PURPLE]);

    var x = 2;
    for (var condition in conditions.take(6)) {
      terminal.writeAt(x, y, condition[0], condition[1]);
      x++;
    }

    _drawMeter(terminal, y, actor.health.current, actor.health.max,
        Color.RED, Color.DARK_RED);
  }

  /// Draws a progress bar to reflect [value]'s range between `0` and [max].
  /// Has a couple of special tweaks: the bar will only be empty if [value] is
  /// exactly `0`, otherwise it will at least show a sliver. Likewise, the bar
  /// will only be full if [value] is exactly [max], otherwise at least one
  /// half unit will be missing.
  void _drawMeter(Terminal terminal, int y, int value, int max,
                 Color fore, Color back) {
    var barWidth;
    if (value == max) {
      barWidth = 20;
    } else if (max <= 1) {
      // Corner case: if max is one, avoid dividing by zero.
      barWidth = 0;
    } else {
      barWidth = (19 * value / (max - 1)).ceil().toInt();
    }

    for (var x = 0; x < 10; x++) {
      var char;
      if (x < barWidth ~/ 2) {
        char = CharCode.SOLID;
      } else if (x < (barWidth + 1) ~/ 2) {
        char = CharCode.HALF_LEFT;
      } else {
        char = CharCode.SPACE;
      }
      terminal.drawGlyph(9 + x, y, new Glyph.fromCharCode(char, fore, back));
    }
  }

  void _drawWarriorStats(Terminal terminal, Hero hero) {
    var warrior = hero.heroClass as Warrior;
    var y = 7;

    draw(String name, TrainedStat stat) {
      // Hide stats until the hero has made progress on them.
      if (stat.level == 0 && stat.percentUntilNext == 0) return;

      terminal.writeAt(0, y, name, Color.GRAY);
      terminal.writeAt(13, y, stat.level.toString());
      terminal.writeAt(16, y, "${stat.percentUntilNext}%", Color.DARK_GRAY);
      y++;
    }

    var weapon = hero.equipment.weapon;
    if (weapon == null) {
      draw("Fighting", warrior.fighting);
    } else {
      draw("Combat", warrior.combat);
      var mastery = warrior.masteries[weapon.type.category];
      if (mastery != null) {
        // Capitalize it.
        var category = weapon.type.category;
        category = category.substring(0, 1).toUpperCase() +
            category.substring(1);
        draw("$category Master", mastery);
      }
    }
    draw("Toughness", warrior.toughness);
  }
}
