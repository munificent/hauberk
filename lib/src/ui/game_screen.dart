library hauberk.ui.game_screen;

import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'close_door_dialog.dart';
import 'direction_dialog.dart';
import 'effect.dart';
import 'game_over_screen.dart';
import 'forfeit_dialog.dart';
import 'input.dart';
import 'item_dialog.dart';
import 'select_command_dialog.dart';
import 'target_dialog.dart';

class GameScreen extends Screen {
  final Game game;

  final HeroSave _save;
  List<Effect> _effects = <Effect>[];

  /// The size of the [Stage] view area.
  final viewSize = new Vec(80, 34);

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

  GameScreen(this._save, this.game) {
    _positionCamera();
  }

  bool handleInput(Input input) {
    var action;

    switch (input) {
      case Input.QUIT:
        if (game.quest.isComplete) {
          _save.copyFrom(game.hero);

          // Remember that this level was completed.
          var completed = _save.completedLevels[game.area.name];
          if (completed == null || completed < game.level + 1) {
            _save.completedLevels[game.area.name] = game.level + 1;
          }

          ui.pop(true);
        } else {
          game.log.error('You have not completed your quest yet:');
          game.quest.announce(game.log);
          dirty();
        }
        break;

      case Input.FORFEIT: ui.push(new ForfeitDialog(game)); break;
      case Input.SELECT_COMMAND: ui.push(new SelectCommandDialog(game)); break;
      case Input.DROP: ui.push(new ItemDialog.drop(this)); break;
      case Input.USE: ui.push(new ItemDialog.use(this)); break;
      case Input.TOSS: ui.push(new ItemDialog.toss(this)); break;

      case Input.REST:
        if (!game.hero.rest()) {
          // Show the message.
          dirty();
        }
        break;

      case Input.CLOSE_DOOR: closeDoor(); break;
      case Input.PICK_UP: pickUp(); break;

      case Input.NW: action = new WalkAction(Direction.NW); break;
      case Input.N: action = new WalkAction(Direction.N); break;
      case Input.NE: action = new WalkAction(Direction.NE); break;
      case Input.W: action = new WalkAction(Direction.W); break;
      case Input.OK: action = new WalkAction(Direction.NONE); break;
      case Input.E: action = new WalkAction(Direction.E); break;
      case Input.SW: action = new WalkAction(Direction.SW); break;
      case Input.S: action = new WalkAction(Direction.S); break;
      case Input.SE: action = new WalkAction(Direction.SE); break;

      case Input.RUN_NW: game.hero.run(Direction.NW); break;
      case Input.RUN_N: game.hero.run(Direction.N); break;
      case Input.RUN_NE: game.hero.run(Direction.NE); break;
      case Input.RUN_W: game.hero.run(Direction.W); break;
      case Input.RUN_E: game.hero.run(Direction.E); break;
      case Input.RUN_SW: game.hero.run(Direction.SW); break;
      case Input.RUN_S: game.hero.run(Direction.S); break;
      case Input.RUN_SE: game.hero.run(Direction.SE); break;

      case Input.FIRE_NW: _fireTowards(Direction.NW); break;
      case Input.FIRE_N: _fireTowards(Direction.N); break;
      case Input.FIRE_NE: _fireTowards(Direction.NE); break;
      case Input.FIRE_W: _fireTowards(Direction.W); break;
      case Input.FIRE_E: _fireTowards(Direction.E); break;
      case Input.FIRE_SW: _fireTowards(Direction.SW); break;
      case Input.FIRE_S: _fireTowards(Direction.S); break;
      case Input.FIRE_SE: _fireTowards(Direction.SE); break;

      case Input.FIRE:
        // TODO: When there is more than one usable command, bring up the
        // SelectCommandDialog. Until then, just pick the first valid one.
        var command = game.hero.heroClass.commands
            .firstWhere((command) => command.canUse(game), orElse: () => null);
        if (command is TargetCommand) {
          // If we still have a visible target, use it.
          if (target != null && target.isAlive &&
              game.stage[target.pos].visible) {
            _fireAtTarget();
          } else {
            // No current target, so ask for one.
            ui.push(new TargetDialog(this, command.getRange(game),
                (_) => _fireAtTarget()));
          }
        } else if (command is DirectionCommand) {
          ui.push(new DirectionDialog(this, game));
        } else {
          game.log.error("You don't have any commands you can perform.");
          dirty();
        }
        break;

      case Input.SWAP:
        if (game.hero.inventory.lastUnequipped == -1) {
          game.log.error("You aren't holding an unequipped item to swap.");
          dirty();
        } else {
          action = new EquipAction(ItemLocation.INVENTORY,
              game.hero.inventory.lastUnequipped);
        }
        break;
    }

    if (action != null) game.hero.setNextAction(action);

    return true;
  }

  void closeDoor() {
    // See how many adjacent open doors there are.
    final doors = [];
    for (final direction in Direction.ALL) {
      final pos = game.hero.pos + direction;
      if (game.stage[pos].type.closesTo != null) {
        doors.add(pos);
      }
    }

    if (doors.length == 0) {
      game.log.error('You are not next to an open door.');
      dirty();
    } else if (doors.length == 1) {
      game.hero.setNextAction(new CloseDoorAction(doors[0]));
    } else {
      ui.push(new CloseDoorDialog(game));
    }
  }

  void pickUp() {
    final items = game.stage.itemsAt(game.hero.pos);

    if (items.length > 1) {
      // Show item dialog if there are multiple things to pick up.
      ui.push(new ItemDialog.pickUp(this));
    } else {
      // Otherwise attempt to pick up any available item.
      game.hero.setNextAction(new PickUpAction(items.length - 1));
    }
  }

  void _fireAtTarget() {
    // TODO: When there is more than one usable command, bring up the
    // SelectCommandDialog. Until then, just pick the first valid one.
    var command = game.hero.heroClass.commands
        .firstWhere((command) => command.canUse(game), orElse: () => null);

    // Should only get here from using a targeted command.
    assert(command is TargetCommand);
    assert(target != null);

    game.hero.setNextAction(command.getTargetAction(game, target.pos));
  }

  void _fireTowards(Direction dir) {
    // TODO: When there is more than one usable command, bring up the
    // SelectCommandDialog. Until then, just pick the first valid one.
    var command = game.hero.heroClass.commands
        .firstWhere((command) => command.canUse(game), orElse: () => null);

    if (command == null) {
      game.log.error("You don't have any commands you can perform.");
      dirty();
      return;
    }

    if (command is DirectionCommand) {
      game.hero.setNextAction(command.getDirectionAction(game, dir));
      return;
    }

    if (command is TargetCommand) {
      var pos = game.hero.pos + dir;

      // Target the monster that is in the fired direction.
      for (var step in new Los(game.hero.pos, pos)) {
        // Stop if we hit a wall.
        if (!game.stage[step].isTransparent) break;

        // See if there is an actor there.
        final actor = game.stage.actorAt(step);
        if (actor != null) {
          target = actor;
          break;
        }
      }

      game.hero.setNextAction(command.getTargetAction(game, pos));
      return;
    }
  }

  void activate(Screen popped, result) {
    if (popped is ForfeitDialog && result) {
      // Forfeiting, so exit.
      ui.pop(false);
    } else if (popped is SelectCommandDialog && result is Command) {
      if (!result.canUse(game)) {
        // Refresh the log.
        dirty();
      } else if (result is TargetCommand) {
        ui.push(new TargetDialog(this, result.getRange(game),
            (_) => _fireAtTarget()));
      } else if (result is DirectionCommand) {
        ui.push(new DirectionDialog(this, game));
      }
    } else if (popped is DirectionDialog && result != Direction.NONE) {
      _fireTowards(result);
    }
  }

  void update() {
    if (_effects.length > 0) dirty();

    var result = game.update();

    // See if the hero died.
    if (!game.hero.isAlive) {
      ui.goTo(new GameOverScreen(game.log));
      return;
    }

    if (game.hero.dazzle.isActive) dirty();

    for (final event in result.events) addEffects(_effects, event);

    if (result.needsRefresh) dirty();

    _effects = _effects.where((effect) => effect.update(game)).toList();
    _positionCamera();
  }

  void render(Terminal terminal) {
    terminal.clear();

    var bar = new Glyph.fromCharCode(
        CharCode.boxDrawingsLightVertical, Color.darkGray);
    for (var y = 0; y < terminal.height; y++) {
      terminal.drawGlyph(80, y, bar);
    }

    var hero = game.hero;
    var heroColor = Color.white;
    if (hero.health.current < hero.health.max / 4) {
      heroColor = Color.red;
    } else if (hero.poison.isActive) {
      heroColor = Color.green;
    } else if (hero.cold.isActive) {
      heroColor = Color.lightBlue;
    } else if (hero.health.current < hero.health.max / 2) {
      heroColor = Color.lightRed;
    } else {
      heroColor = Color.white;
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
    // Handle the stage being smaller than the view.
    var rangeWidth = math.max(0, game.stage.width - viewSize.x);
    var rangeHeight = math.max(0, game.stage.height - viewSize.y);

    var cameraRange = new Rect(0, 0, rangeWidth,  rangeHeight);

    var camera = game.hero.pos - viewSize ~/ 2;
    camera = cameraRange.clamp(camera);
    _cameraBounds = new Rect(camera.x, camera.y,
        math.min(viewSize.x, game.stage.width),
        math.min(viewSize.y, game.stage.height));
  }

  void _drawStage(Terminal terminal, Color heroColor,
      List<Actor> visibleMonsters) {
    var hero = game.hero;

    dazzleGlyph(Glyph glyph) {
      if (!hero.dazzle.isActive) return glyph;

      var chance = 10 + math.min(80, hero.dazzle.duration * 10);
      if (rng.range(100) > chance) return glyph;

      var colors = [Color.aqua, Color.blue, Color.purple, Color.red,
          Color.orange, Color.gold, Color.yellow, Color.green];
      var char = (rng.range(100) > chance) ? glyph.char : CharCode.asterisk;
      return new Glyph.fromCharCode(char, rng.item(colors));
    }

    // Draw the tiles.
    for (var pos in _cameraBounds) {
      var tile = game.stage[pos];
      var glyph;
      if (tile.isExplored) {
        glyph = tile.type.appearance[tile.visible ? 0 : 1];
        if (tile.visible) glyph = dazzleGlyph(glyph);
        drawStageGlyph(terminal, pos.x, pos.y, glyph);
      }
    }

    // Draw the items.
    for (var item in game.stage.items) {
      if (!game.stage[item.pos].isExplored) continue;
      var glyph = dazzleGlyph(item.appearance);
      drawStageGlyph(terminal, item.x, item.y, glyph);
    }

    // Draw the actors.
    for (var actor in game.stage.actors) {
      if (!game.stage[actor.pos].visible) continue;

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
      effect.render(game, (x, y, glyph) {
        drawStageGlyph(terminal, x, y, glyph);
      });
    }
  }

  void _drawLog(Terminal terminal) {
    var y = 0;

    for (final message in game.log.messages) {
      var color;
      switch (message.type) {
        case LogType.MESSAGE: color = Color.white; break;
        case LogType.ERROR: color = Color.red; break;
        case LogType.QUEST: color = Color.purple; break;
        case LogType.GAIN: color = Color.gold; break;
        case LogType.HELP: color = Color.green; break;
      }

      terminal.writeAt(0, y, message.text, color);
      if (message.count > 1) {
        terminal.writeAt(message.text.length, y, ' (x${message.count})',
            Color.gray);
      }
      y++;
    }
  }

  void _drawSidebar(Terminal terminal, Color heroColor,
      List<Actor> visibleMonsters) {
    var hero = game.hero;
    _drawStat(terminal, 0, 'Health', hero.health.current, Color.red,
        hero.health.max, Color.darkRed);
    terminal.writeAt(0, 1, 'Food', Color.gray);
    terminal.writeAt(7, 1, hero.food.ceil().toString(), Color.orange);

    _drawStat(terminal, 2, 'Level', hero.level, Color.aqua);
    var levelPercent = 100 * hero.experience ~/
        (calculateLevelCost(hero.level + 1) -
        calculateLevelCost(hero.level));
    terminal.writeAt(16, 2, '$levelPercent%', Color.darkAqua);
    _drawStat(terminal, 3, 'Gold', hero.gold, Color.gold);
    _drawStat(terminal, 4, 'Armor',
        '${(100 - getArmorMultiplier(hero.armor) * 100).toInt()}% ',
        Color.green);
    // TODO: Show the weapon and stats better.
    _drawStat(terminal, 5, 'Weapon', hero.getAttack(null), Color.yellow);

    terminal.writeAt(0, 7, hero.heroClass.name);
    if (hero.heroClass is Warrior) _drawWarriorStats(terminal, hero);

    // Draw the nearby monsters.
    terminal.writeAt(0, 16, '@', heroColor);
    terminal.writeAt(2, 16, _save.name);
    _drawHealthBar(terminal, 17, hero);

    visibleMonsters.sort((a, b) {
      var aDistance = (a.pos - game.hero.pos).lengthSquared;
      var bDistance = (b.pos - game.hero.pos).lengthSquared;
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
            (target == monster) ? Color.yellow : Color.white);

        _drawHealthBar(terminal, y + 1, monster);
      }
    }

    // Draw the unseen items.
    terminal.writeAt(0, 38, "Unfound items:", Color.gray);
    var unseen = game.stage.items.where(
        (item) => !game.stage[item.pos].isExplored).toList();
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
    terminal.writeAt(0, y, label, Color.gray);
    var valueString = value.toString();
    terminal.writeAt(7, y, valueString, valueColor);

    if (max != null) {
      terminal.writeAt(7 + valueString.length, y, ' / $max', maxColor);
    }
  }

  static final _resistConditions = {
    Element.AIR: ["A", Color.black, Color.lightAqua],
    Element.EARTH: ["E", Color.black, Color.brown],
    Element.FIRE: ["F", Color.black, Color.orange],
    Element.WATER: ["W", Color.black, Color.blue],
    Element.ACID: ["A", Color.black, Color.darkYellow],
    Element.COLD: ["C", Color.black, Color.lightBlue],
    Element.LIGHTNING: ["L", Color.black, Color.lightPurple],
    Element.POISON: ["P", Color.black, Color.green],
    Element.DARK: ["D", Color.black, Color.orange],
    Element.LIGHT: ["L", Color.black, Color.orange],
    Element.SPIRIT: ["S", Color.black, Color.orange]
  };

  /// Draws a health bar for [actor].
  void _drawHealthBar(Terminal terminal, int y, Actor actor) {
    // Show conditions.
    var conditions = [];

    if (actor is Monster && actor.isAfraid) {
      conditions.add(["!", Color.yellow]);
    }

    if (actor.poison.isActive) {
      switch (actor.poison.intensity) {
        case 1: conditions.add(["P", Color.darkGreen]); break;
        case 2: conditions.add(["P", Color.green]); break;
        default: conditions.add(["P", Color.lightGreen]); break;
      }
    }

    if (actor.cold.isActive) conditions.add(["C", Color.lightBlue]);
    switch (actor.haste.intensity) {
      case 1: conditions.add(["S", Color.darkGold]); break;
      case 2: conditions.add(["S", Color.gold]); break;
      case 3: conditions.add(["S", Color.lightGold]); break;
    }

    if (actor.dazzle.isActive) conditions.add(["D", Color.lightPurple]);

    for (var element in Element.ALL) {
      if (actor.resistances[element].isActive) {
        conditions.add(_resistConditions[element]);
      }
    }

    var x = 2;
    for (var condition in conditions.take(6)) {
      if (condition.length == 3) {
        terminal.writeAt(x, y, condition[0], condition[1], condition[2]);
      } else {
        terminal.writeAt(x, y, condition[0], condition[1]);
      }
      x++;
    }

    _drawMeter(terminal, y, actor.health.current, actor.health.max,
        Color.red, Color.darkRed);
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
        char = CharCode.fullBlock;
      } else if (x < (barWidth + 1) ~/ 2) {
        char = CharCode.leftHalfBlock;
      } else {
        char = CharCode.space;
      }
      terminal.drawGlyph(9 + x, y, new Glyph.fromCharCode(char, fore, back));
    }
  }

  void _drawWarriorStats(Terminal terminal, Hero hero) {
    var warrior = hero.heroClass as Warrior;

    terminal.writeAt(0, 8, "Fury", Color.gray);
    _drawMeter(terminal, 8, hero.charge, 100, Color.orange, Color.darkOrange);

    var y = 9;

    draw(String name, TrainedStat stat) {
      // Hide stats until the hero has made progress on them.
      if (stat.level == 0 && stat.percentUntilNext == 0) return;

      terminal.writeAt(0, y, name, Color.gray);
      terminal.writeAt(13, y, stat.level.toString());
      terminal.writeAt(16, y, "${stat.percentUntilNext}%", Color.darkGray);
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
