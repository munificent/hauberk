library hauberk.ui.game_screen;

import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'close_door_dialog.dart';
import 'game_over_screen.dart';
import 'forfeit_dialog.dart';
import 'item_dialog.dart';
import 'select_command_dialog.dart';
import 'target_dialog.dart';

class GameScreen extends Screen {
  final HeroSave _save;
  final Game     _game;
  List<Effect>   _effects = <Effect>[];
  bool           _logOnTop = false;

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

  GameScreen(this._save, this._game);

  bool handleInput(Keyboard keyboard) {
    var action;

    if (keyboard.shift && !keyboard.control && !keyboard.option) {
      switch (keyboard.lastPressed) {
      case KeyCode.F:
        ui.push(new ForfeitDialog(_game));
        break;

      case KeyCode.L:
        if (!_game.hero.rest()) {
          // Show the message.
          dirty();
        }
        break;

      case KeyCode.I:
        _game.hero.run(Direction.NW);
        break;

      case KeyCode.O:
        _game.hero.run(Direction.N);
        break;

      case KeyCode.P:
        _game.hero.run(Direction.NE);
        break;

      case KeyCode.K:
        _game.hero.run(Direction.W);
        break;

      case KeyCode.SEMICOLON:
        _game.hero.run(Direction.E);
        break;

      case KeyCode.COMMA:
        _game.hero.run(Direction.SW);
        break;

      case KeyCode.PERIOD:
        _game.hero.run(Direction.S);
        break;

      case KeyCode.SLASH:
        _game.hero.run(Direction.SE);
        break;
      }
    } else if (!keyboard.control && !keyboard.option) {
      switch (keyboard.lastPressed) {
      case KeyCode.Q:
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

      case KeyCode.C:
        closeDoor();
        break;

      case KeyCode.D:
        ui.push(new ItemDialog.drop(_game));
        break;

      case KeyCode.U:
        ui.push(new ItemDialog.use(_game));
        break;

      case KeyCode.G:
        action = new PickUpAction();
        break;

      case KeyCode.X:
        if (_game.hero.inventory.lastUnequipped == -1) {
          _game.log.error("You aren't holding an unequipped item to swap.");
          dirty();
        } else {
          action = new EquipAction(_game.hero.inventory.lastUnequipped, false);
        }
        break;

      case KeyCode.I: action = new WalkAction(Direction.NW); break;
      case KeyCode.O: action = new WalkAction(Direction.N); break;
      case KeyCode.P: action = new WalkAction(Direction.NE); break;
      case KeyCode.K: action = new WalkAction(Direction.W); break;
      case KeyCode.L: action = new WalkAction(Direction.NONE); break;
      case KeyCode.SEMICOLON: action = new WalkAction(Direction.E); break;
      case KeyCode.COMMA: action = new WalkAction(Direction.SW); break;
      case KeyCode.PERIOD: action = new WalkAction(Direction.S); break;
      case KeyCode.SLASH: action = new WalkAction(Direction.SE); break;

      case KeyCode.S:
        ui.push(new SelectCommandDialog(_game));
        break;
      }
    } else if (!keyboard.shift && keyboard.option && !keyboard.control) {
      switch (keyboard.lastPressed) {
      case KeyCode.I:
        fireAt(_game.hero.pos + Direction.NW);
        break;

      case KeyCode.O:
        fireAt(_game.hero.pos + Direction.N);
        break;

      case KeyCode.P:
        fireAt(_game.hero.pos + Direction.NE);
        break;

      case KeyCode.K:
        fireAt(_game.hero.pos + Direction.W);
        break;

      case KeyCode.L:
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

      case KeyCode.SEMICOLON:
        fireAt(_game.hero.pos + Direction.E);
        break;

      case KeyCode.COMMA:
        fireAt(_game.hero.pos + Direction.SW);
        break;

      case KeyCode.PERIOD:
        fireAt(_game.hero.pos + Direction.S);
        break;

      case KeyCode.SLASH:
        fireAt(_game.hero.pos + Direction.SE);
        break;
      }
    }

    if (action != null) {
      _game.hero.setNextAction(action);
    }

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

    for (final event in result.events) {
      switch (event.type) {
        case EventType.BOLT:
          _effects.add(new FrameEffect(event.value, '*',
              _getColorForElement(event.element)));
          break;

        case EventType.HIT:
          _effects.add(new HitEffect(event.actor));
          break;

        case EventType.DIE:
          _effects.add(new HitEffect(event.actor));
          // TODO: Make number of particles vary based on monster health.
          _spawnParticles(10, event.actor.pos, Color.RED);
          break;

        case EventType.HEAL:
          _effects.add(new HealEffect(event.actor.pos.x, event.actor.pos.y));
          break;

        case EventType.FEAR:
          _effects.add(new BlinkEffect(event.actor, Color.DARK_YELLOW));
          break;

        case EventType.COURAGE:
          _effects.add(new BlinkEffect(event.actor, Color.YELLOW));
          break;

        case EventType.DETECT:
          _effects.add(new DetectEffect(event.value));
          break;

        case EventType.TELEPORT:
          _effects.add(new TeleportEffect(event.value, event.actor.pos));
          break;
      }
    }

    if (result.needsRefresh) dirty();

    _effects = _effects.where((effect) => effect.update(_game)).toList();
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

    _drawStage(terminal, heroColor, visibleMonsters);
    _drawLog(terminal);
    _drawSidebar(terminal.rect(81, 0, 20, 40), heroColor, visibleMonsters);
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
    for (int y = 0; y < _game.stage.height; y++) {
      for (int x = 0; x < _game.stage.width; x++) {
        final tile = _game.stage.get(x, y);
        var glyph;
        if (tile.isExplored) {
          glyph = tile.type.appearance[tile.visible ? 0 : 1];
          if (tile.visible) glyph = dazzleGlyph(glyph);
          terminal.drawGlyph(x, y, glyph);
        }
      }
    }

    // Draw the items.
    for (final item in _game.stage.items) {
      if (!_game.stage[item.pos].isExplored) continue;
      var glyph = dazzleGlyph(item.appearance);
      terminal.drawGlyph(item.x, item.y, glyph);
    }

    // Draw the actors.
    for (final actor in _game.stage.actors) {
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

      terminal.drawGlyph(actor.x, actor.y, glyph);

      if (actor is Monster) visibleMonsters.add(actor);
    }

    // Draw the effects.
    var stageTerm = terminal.rect(0, 0, _game.stage.width, _game.stage.height);
    for (final effect in _effects) {
      effect.render(_game, stageTerm);
    }
  }

  void _drawLog(Terminal terminal) {
    // If the log is overlapping the hero, flip it to the other side. Use 0.4
    // and 0.6 here to avoid flipping too much if the hero is wandering around
    // near the middle.
    var hero = _game.hero;
    if (_logOnTop) {
      if (hero.y < terminal.height * 0.4) _logOnTop = false;
    } else {
      if (hero.y > terminal.height * 0.6) _logOnTop = true;
    }

    // Force the log to the bottom if a popup is open so it's still visible.
    if (!isTopScreen) _logOnTop = false;

    var y = _logOnTop ? 0 : terminal.height - _game.log.messages.length;

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

  Color _getColorForElement(Element element) {
    switch (element) {
      case Element.NONE: return Color.LIGHT_BROWN;
      case Element.AIR: return Color.LIGHT_AQUA;
      case Element.EARTH: return Color.BROWN;
      case Element.FIRE: return Color.RED;
      case Element.WATER: return Color.BLUE;
      case Element.ACID: return Color.GREEN;
      case Element.COLD: return Color.LIGHT_BLUE;
      case Element.LIGHTNING: return Color.YELLOW;
      case Element.POISON: return Color.DARK_GREEN;
      case Element.DARK: return Color.DARK_GRAY;
      case Element.LIGHT: return Color.LIGHT_YELLOW;
      case Element.SPIRIT: return Color.PURPLE;
    }

    throw "unreachable";
  }

  void _spawnParticles(int count, Vec pos, Color color) {
    for (var i = 0; i < count; i++) {
      _effects.add(new ParticleEffect(pos.x, pos.y, color));
    }
  }
}

abstract class Effect {
  bool update(Game game);
  void render(Game game, Terminal terminal);
}

class FrameEffect implements Effect {
  final Vec pos;
  final String char;
  final Color color;
  int life = 4;

  FrameEffect(this.pos, this.char, this.color);

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Game game, Terminal terminal) {
    terminal.writeAt(pos.x, pos.y, char, color);
  }
}

/// Blinks the background color for an actor a couple of times.
class BlinkEffect implements Effect {
  final Actor actor;
  final Color color;
  int life = 8 * 3;

  BlinkEffect(this.actor, this.color);

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Game game, Terminal terminal) {
    if (!actor.isVisible) return;

    if ((life ~/ 8) % 2 == 0) {
      var glyph = actor.appearance;
      glyph = new Glyph.fromCharCode(glyph.char, glyph.fore, color);
      terminal.drawGlyph(actor.pos.x, actor.pos.y, glyph);
    }
  }
}

class HitEffect implements Effect {
  final int x;
  final int y;
  final int health;
  int frame = 0;

  static final NUM_FRAMES = 15;

  HitEffect(Actor actor)
  : x = actor.x,
    y = actor.y,
    health = 10 * actor.health.current ~/ actor.health.max;

  bool update(Game game) {
    return frame++ < NUM_FRAMES;
  }

  void render(Game game, Terminal terminal) {
    var back;
    switch (frame ~/ 5) {
      case 0: back = Color.RED;      break;
      case 1: back = Color.DARK_RED; break;
      case 2: back = Color.BLACK;    break;
    }
    terminal.writeAt(x, y, ' 123456789'[health], Color.BLACK, back);
  }
}

class ParticleEffect implements Effect {
  num x;
  num y;
  num h;
  num v;
  int life;
  final Color color;

  ParticleEffect(this.x, this.y, this.color) {
    final theta = rng.range(628) / 100;
    final radius = rng.range(30, 40) / 100;

    h = math.cos(theta) * radius;
    v = math.sin(theta) * radius;
    life = rng.range(7, 15);
  }

  bool update(Game game) {
    x += h;
    y += v;

    final pos = new Vec(x.toInt(), y.toInt());
    if (!game.stage.bounds.contains(pos)) return false;
    if (!game.stage[pos].isPassable) return false;

    return life-- > 0;
  }

  void render(Game game, Terminal terminal) {
    terminal.writeAt(x.toInt(), y.toInt(), '*', color);
  }
}

class HealEffect implements Effect {
  int x;
  int y;
  int frame = 0;

  HealEffect(this.x, this.y);

  bool update(Game game) {
    return frame++ < 24;
  }

  void render(Game game, Terminal terminal) {
    if (!game.stage.get(x, y).visible) return;

    var back;
    switch ((frame ~/ 4) % 4) {
      case 0: back = Color.BLACK;       break;
      case 1: back = Color.DARK_AQUA;   break;
      case 2: back = Color.AQUA;        break;
      case 3: back = Color.LIGHT_AQUA;  break;
    }

    terminal.writeAt(x - 1, y, '-', back);
    terminal.writeAt(x + 1, y, '-', back);
    terminal.writeAt(x, y - 1, '|', back);
    terminal.writeAt(x, y + 1, '|', back);
  }
}

class DetectEffect implements Effect {
  final Vec pos;
  int life = 30;

  DetectEffect(this.pos);

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Game game, Terminal terminal) {
    var radius = life ~/ 4;
    var glyph = new Glyph("*", Color.LIGHT_GOLD);

    var bounds = new Rect(pos.x - radius, pos.y - radius,
        radius * 2 + 1, radius * 2 + 1);
    bounds = Rect.intersect(bounds, new Rect(0, 0,
        terminal.width, terminal.height));

    for (var pixel in bounds) {
      var relative = pos - pixel;
      if (relative < radius && relative > radius - 2) {
        terminal.drawGlyph(pixel.x, pixel.y, glyph);
      }
    }
  }
}

class TeleportEffect implements Effect {
  final Vec to;
  final Iterator<Vec> los;
  int tick = 0;

  TeleportEffect(Vec from, Vec to)
    : to = to,
      los = new Los(from, to).iterator;

  bool update(Game game) {
    if (los.current == to) return false;
    los.moveNext();
    return true;
  }

  void render(Game game, Terminal terminal) {
    if (!game.stage[los.current].visible) return;

    var color = rng.item([Color.WHITE, Color.AQUA, Color.BLUE]);

    terminal.drawGlyph(los.current.x - 1, los.current.y, new Glyph('-', color));
    terminal.drawGlyph(los.current.x + 1, los.current.y, new Glyph('-', color));
    terminal.drawGlyph(los.current.x, los.current.y - 1, new Glyph('|', color));
    terminal.drawGlyph(los.current.x, los.current.y + 1, new Glyph('|', color));
    terminal.drawGlyph(los.current.x, los.current.y, new Glyph('*', color));
  }
}
