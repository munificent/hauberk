library dngn.ui.game_screen;

import 'dart:math' as math;

import '../engine.dart';
import '../util.dart';
import 'close_door_dialog.dart';
import 'game_over_screen.dart';
import 'forfeit_dialog.dart';
import 'inventory_dialog.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'select_skill_dialog.dart';
import 'target_dialog.dart';
import 'terminal.dart';

class GameScreen extends Screen {
  final HeroSave save;
  final Game     game;
  List<Effect>   effects;
  bool           logOnTop = false;

  /// The currently targeted actor, if any.
  // TODO(bob): Need to handle target moving out of visibility. Should not
  // forget target: if the monster becomes visible again, it should remain
  // targeted. But if the user opens the target dialog or does "target last"
  // while the target is invisible, it should treat it as not being targeted.
  Actor target;

  /// The most recently used skill.
  Skill lastSkill;

  GameScreen(this.save, this.game)
  : effects = <Effect>[];

  bool handleInput(Keyboard keyboard) {
    var action;

    if (keyboard.shift && !keyboard.control && !keyboard.option) {
      switch (keyboard.lastPressed) {
      case KeyCode.F:
        ui.push(new ForfeitDialog(game));
        break;

      case KeyCode.L:
        game.hero.rest();
        break;

      case KeyCode.I:
        game.hero.run(Direction.NW);
        break;

      case KeyCode.O:
        game.hero.run(Direction.N);
        break;

      case KeyCode.P:
        game.hero.run(Direction.NE);
        break;

      case KeyCode.K:
        game.hero.run(Direction.W);
        break;

      case KeyCode.SEMICOLON:
        game.hero.run(Direction.E);
        break;

      case KeyCode.COMMA:
        game.hero.run(Direction.SW);
        break;

      case KeyCode.PERIOD:
        game.hero.run(Direction.S);
        break;

      case KeyCode.SLASH:
        game.hero.run(Direction.SE);
        break;
      }
    } else if (!keyboard.control && !keyboard.option) {
      switch (keyboard.lastPressed) {
      case KeyCode.Q:
        if (game.quest.isComplete) {
          save.copyFrom(game.hero);

          // Remember that this level was completed.
          var completed = save.completedLevels[game.area.name];
          if (completed == null || completed < game.level + 1) {
            save.completedLevels[game.area.name] = game.level + 1;
          }

          ui.pop(true);
        } else {
          game.log.error('You have not completed your quest yet:');
          game.quest.announce(game.log);
          dirty();
        }
        break;

      case KeyCode.C:
        closeDoor();
        break;

      case KeyCode.D:
        ui.push(new InventoryDialog(game, InventoryMode.DROP));
        break;

      case KeyCode.U:
        ui.push(new InventoryDialog(game, InventoryMode.USE));
        break;

      case KeyCode.G:
        action = new PickUpAction();
        break;

      case KeyCode.I:
        action = new WalkAction(Direction.NW);
        break;

      case KeyCode.O:
        action = new WalkAction(Direction.N);
        break;

      case KeyCode.P:
        action = new WalkAction(Direction.NE);
        break;

      case KeyCode.K:
        action = new WalkAction(Direction.W);
        break;

      case KeyCode.L:
        action = new WalkAction(Direction.NONE);
        break;

      case KeyCode.SEMICOLON:
        action = new WalkAction(Direction.E);
        break;

      case KeyCode.COMMA:
        action = new WalkAction(Direction.SW);
        break;

      case KeyCode.PERIOD:
        action = new WalkAction(Direction.S);
        break;

      case KeyCode.SLASH:
        action = new WalkAction(Direction.SE);
        break;

      case KeyCode.S:
        ui.push(new SelectSkillDialog(game));
        break;
      }
    } else if (!keyboard.shift && keyboard.option && !keyboard.control) {
      switch (keyboard.lastPressed) {
      case KeyCode.I:
        fireAt(game.hero.pos + Direction.NW);
        break;

      case KeyCode.O:
        fireAt(game.hero.pos + Direction.N);
        break;

      case KeyCode.P:
        fireAt(game.hero.pos + Direction.NE);
        break;

      case KeyCode.K:
        fireAt(game.hero.pos + Direction.W);
        break;

      case KeyCode.L:
        if (lastSkill == null) {
          // Haven't picked a skill yet, so select one.
          ui.push(new SelectSkillDialog(game));
        } else if (!lastSkill.canUse(game.hero.skills[lastSkill], game)) {
          // Show the message.
          dirty();
        } else if (lastSkill.needsTarget) {
          // If we still have a visible target, use it.
          if (target != null && target.isAlive &&
              game.stage[target.pos].visible) {
            fireAt(target.pos);
          } else {
            // No current target, so ask for one.
            ui.push(new TargetDialog(this, game));
          }
        } else {
          useLastSkill(null);
        }
        break;

      case KeyCode.SEMICOLON:
        fireAt(game.hero.pos + Direction.E);
        break;

      case KeyCode.COMMA:
        fireAt(game.hero.pos + Direction.SW);
        break;

      case KeyCode.PERIOD:
        fireAt(game.hero.pos + Direction.S);
        break;

      case KeyCode.SLASH:
        fireAt(game.hero.pos + Direction.SE);
        break;
      }
    }

    if (action != null) {
      game.hero.setNextAction(action);
    }

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

  void fireAt(Vec pos) {
    if (lastSkill == null || !lastSkill.needsTarget) return;

    if (!lastSkill.canUse(game.hero.skills[lastSkill], game)) {
      // Refresh the log.
      dirty();
      return;
    }

    // If we aren't firing at the current target, see if there is a monster
    // in that direction that we can target. (In other words, if you fire in
    // a raw direction, target the monster in that direction for subsequent
    // shots).
    if (target == null || target.pos != pos) {
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
    }

    useLastSkill(target.pos);
  }

  void useLastSkill(Vec target) {
    game.hero.setNextAction(
        lastSkill.getUseAction(game.hero.skills[lastSkill], game, target));
  }

  void activate(Screen popped, result) {
    if (popped is ForfeitDialog && result) {
      // Forfeiting, so exit.
      ui.pop(false);
    } else if (popped is SelectSkillDialog && result is Skill) {
      lastSkill = result;

      if (!result.canUse(game.hero.skills[result], game)) {
        // Refresh the log.
        dirty();
      } else if (result.needsTarget) {
        ui.push(new TargetDialog(this, game));
      } else {
        useLastSkill(null);
      }
    } else if (popped is TargetDialog && result) {
      fireAt(target.pos);
    }
  }

  void update() {
    if (effects.length > 0) dirty();

    var result = game.update();

    // See if the hero died.
    if (!game.hero.isAlive) {
      // TODO(bob): Should it save the game here?
      ui.goTo(new GameOverScreen());
      return;
    }

    for (final event in result.events) {
      // TODO(bob): Handle other event types.
      switch (event.type) {
        case EventType.BOLT:
          effects.add(new FrameEffect(event.value, '*',
              getColorForElement(event.element)));
          break;

        case EventType.HIT:
          effects.add(new HitEffect(event.actor));
          break;

        case EventType.KILL:
          effects.add(new HitEffect(event.actor));
          // TODO(bob): Make number of particles vary based on monster health.
          _spawnParticles(10, event.actor.pos, Color.RED);
          break;

        case EventType.HEAL:
          effects.add(new HealEffect(event.actor.pos.x, event.actor.pos.y));
          break;
      }
    }

    if (result.needsRefresh) dirty();

    effects = effects.where((effect) => effect.update(game)).toList();
  }

  void render(Terminal terminal) {
    final black = new Glyph(' ');

    // TODO(bob): Hack. Clear out the help text from the previous screen.
    terminal.rect(0, terminal.height - 1, terminal.width, 1).clear();

    // Draw the stage.
    for (int y = 0; y < game.stage.height; y++) {
      for (int x = 0; x < game.stage.width; x++) {
        final tile = game.stage.get(x, y);
        var glyph;
        if (tile.isExplored) {
          glyph = tile.type.appearance[tile.visible ? 0 : 1];
        } else {
          glyph = black;
        }

        /*
        glyph = debugScent(x, y, tile, glyph);
        */

        terminal.drawGlyph(x, y, glyph);
      }
    }

    // TODO(bob): Temp. Test A*.
    /*
    terminal.writeAt(40, 20, '!', Color.AQUA);
    final aStar = AStar.findPath(game.level, game.hero.pos, new Vec(40, 20), 15);
    if (aStar != null) {
      for (final pos in aStar.closed) {
        terminal.writeAt(pos.x, pos.y, '-', Color.RED);
      }
      for (final path in aStar.open) {
        terminal.writeAt(path.pos.x, path.pos.y, '?', Color.BLUE);
      }

      var path = aStar.path;
      while (path != null) {
        terminal.writeAt(path.pos.x, path.pos.y, '@', Color.ORANGE);
        path = path.parent;
      }
    }

    final d = AStar.findDirection(game.level, game.hero.pos, new Vec(40, 20), 15);
    final p = game.hero.pos + d;
    terminal.writeAt(p.x, p.y, '0', Color.YELLOW);
    */

    // Draw the items.
    var unexploredItem = new Glyph('?', Color.BLACK, Color.DARK_BLUE);
    for (final item in game.stage.items) {
      if (game.stage[item.pos].isExplored) {
        terminal.drawGlyph(item.x, item.y, item.appearance);
      } else {
        terminal.drawGlyph(item.x, item.y, unexploredItem);
      }
    }

    var visibleMonsters = [];

    // Draw the actors.
    for (final actor in game.stage.actors) {
      if (!game.stage[actor.pos].visible) continue;
      final appearance = actor.appearance;
      var glyph = (appearance is Glyph) ? appearance : new Glyph('@', Color.WHITE);

      if (target == actor) {
        glyph = new Glyph.fromCharCode(glyph.char, glyph.back, glyph.fore);
      }

      terminal.drawGlyph(actor.x, actor.y, glyph);

      if (actor is Monster) visibleMonsters.add(actor);
    }

    // Draw the effects.
    for (final effect in effects) {
      effect.render(terminal);
    }

    // Draw the log.
    var hero = game.hero;

    // If the log is overlapping the hero, flip it to the other side. Use 0.4
    // and 0.6 here to avoid flipping too much if the hero is wandering around
    // near the middle.
    if (logOnTop) {
      if (hero.y < terminal.height * 0.4) logOnTop = false;
    } else {
      if (hero.y > terminal.height * 0.6) logOnTop = true;
    }

    // Force the log to the bottom if a popup is open so it's still visible.
    if (!isTopScreen) logOnTop = false;

    var y = logOnTop ? 0 : terminal.height - game.log.messages.length;

    for (final message in game.log.messages) {
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

    var bar = new Glyph.fromCharCode(
        CharCode.BOX_DRAWINGS_LIGHT_VERTICAL, Color.DARK_GRAY);
    for (var y = 0; y < terminal.height; y++) {
      terminal.drawGlyph(81, y, bar);
    }

    drawStat(terminal, 0, 'Health', hero.health.current, Color.RED,
        hero.health.max, Color.DARK_RED);

    terminal.writeAt(82, 1, 'Focus', Color.GRAY);
    drawMeter(terminal, 1, hero.focus, Option.FOCUS_MAX,
        Color.BLUE, Color.DARK_BLUE);

    drawStat(terminal, 3, 'Level', hero.level, Color.AQUA);
    // TODO(bob): Handle hero at max level.
    drawStat(terminal, 4, 'Exp', hero.experience, Color.AQUA,
        calculateLevelCost(hero.level + 1), Color.DARK_AQUA);
    drawStat(terminal, 5, 'Armor',
        '${(100 - getArmorMultiplier(hero.armor) * 100).toInt()}% ',
        Color.GREEN);
    drawStat(terminal, 6, 'Weapon', hero.getAttack(null).damage, Color.YELLOW);

    // Show conditions.
    terminal.writeAt(82,  8, "                    ");
    switch (hero.haste.intensity) {
      case -2: terminal.writeAt(82,  8, "Para", Color.DARK_GREEN); break;
      case -1: terminal.writeAt(82,  8, "Slow", Color.DARK_GREEN); break;
      case 1: terminal.writeAt(82,  8, "Quik", Color.GREEN); break;
      case 2: terminal.writeAt(82,  8, "Alac", Color.GREEN); break;
      case 3: terminal.writeAt(82,  8, "Sped", Color.GREEN); break;
    }

    terminal.writeAt(82, 18, '@ hero', Color.WHITE);
    drawHealthBar(terminal, 19, hero);

    // Draw the nearby monsters.
    visibleMonsters.sort((a, b) {
      var aDistance = (a.pos - game.hero.pos).lengthSquared;
      var bDistance = (b.pos - game.hero.pos).lengthSquared;
      return aDistance.compareTo(bDistance);
    });

    for (var i = 0; i < 10; i++) {
      var y = 20 + i * 2;
      terminal.writeAt(82, y, '                   ');
      terminal.writeAt(82, y + 1, '                   ');

      if (i < visibleMonsters.length) {
        var monster = visibleMonsters[i];

        var glyph = monster.appearance;
        if (target == monster) {
          glyph = new Glyph.fromCharCode(glyph.char, glyph.back, glyph.fore);
        }

        terminal.drawGlyph(82, y, glyph);
        terminal.writeAt(84, y, monster.breed.name,
            (target == monster) ? Color.YELLOW : Color.WHITE);

        drawHealthBar(terminal, y + 1, monster);
      }
    }
  }

  void drawStat(Terminal terminal, int y, String label, value,
      Color valueColor, [max, Color maxColor]) {
    terminal.writeAt(82, y, label, Color.GRAY);
    var valueString = value.toString();
    terminal.writeAt(89, y, "             ");
    terminal.writeAt(89, y, valueString, valueColor);

    if (max != null) {
      terminal.writeAt(89 + valueString.length, y, ' / $max', maxColor);
    }
  }

  void drawHealthBar(Terminal terminal, int y, Actor actor) {
    drawMeter(terminal, y, actor.health.current, actor.health.max,
        Color.RED, Color.DARK_RED);
  }

  /// Draws a progress bar to reflect [value]'s range between `0` and [max].
  /// Has a couple of special tweaks: the bar will only be empty if [value] is
  /// exactly `0`, otherwise it will at least show a sliver. Likewise, the bar
  /// will only be full if [value] is exactly [max], otherwise at least one
  /// half unit will be missing.
  void drawMeter(Terminal terminal, int y, int value, int max,
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
      terminal.drawGlyph(90 + x, y, new Glyph.fromCharCode(char, fore, back));
    }
  }

  void targetActor(Actor actor) {
    if (actor != target) {
      target = actor;
      dirty();
    }
  }

  Color getColorForElement(Element element) {
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
      effects.add(new ParticleEffect(pos.x, pos.y, color));
    }
  }
}

abstract class Effect {
  bool update(Game game);
  void render(Terminal terminal);
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

  void render(Terminal terminal) {
    terminal.writeAt(pos.x, pos.y, char, color);
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
    health = 9 * actor.health.current ~/ actor.health.max;

  bool update(Game game) {
    return frame++ < NUM_FRAMES;
  }

  void render(Terminal terminal) {
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
    final theta = rng.range(628) / 100; // TODO(bob): Ghetto.
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

  void render(Terminal terminal) {
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

  void render(Terminal terminal) {
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