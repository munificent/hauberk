
class GameScreen extends Screen {
  final HeroHome home;
  final Game     game;
  List<Effect>   effects;
  bool           logOnTop = false;

  GameScreen(this.home, this.game)
  : effects = <Effect>[];

  bool handleInput(Keyboard keyboard) {
    var action;

    if (keyboard.shift) {
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
    } else {
      switch (keyboard.lastPressed) {
      case KeyCode.Q:
        if (game.isQuestComplete) {
          home.copyFrom(game.hero);
          ui.pop(true);
        } else {
          game.log.add('You have not completed your quest yet.');
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
      if (game.level[pos].type == TileType.OPEN_DOOR) {
        doors.add(pos);
      }
    }

    if (doors.length == 0) {
      game.log.add('You are not next to an open door.');
      dirty();
    } else if (doors.length == 1) {
      game.hero.setNextAction(new CloseDoorAction(doors[0]));
    } else {
      ui.push(new CloseDoorDialog(game));
    }
  }

  void activate(Screen popped, result) {
    if (popped is ForfeitDialog && result) {
      // Forfeiting, so exit.
      ui.pop(false);
    }
  }

  void update() {
    if (effects.length > 0) dirty();

    var result = game.update();

    // TODO(bob): Hack temp.
    if (game.hero.health.current == 0) {
      // TODO(bob): Should it save the game here?
      ui.pop(false);
      return;
    }

    for (final event in result.events) {
      // TODO(bob): Handle other event types.
      switch (event.type) {
        case EventType.BOLT:
          effects.add(new FrameEffect(event.value, '*'));
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

    effects = effects.filter((effect) => effect.update(game));
  }

  void render(Terminal terminal) {
    // Draw the level.
    for (int y = 0; y < game.level.height; y++) {
      for (int x = 0; x < game.level.width; x++) {
        final tile = game.level.get(x, y);
        var glyph;
        if (tile.isExplored) {
          switch (tile.type) {
            case TileType.FLOOR:
              glyph = new Glyph('.', tile.visible ? Color.GRAY : Color.DARK_GRAY);
              break;
            case TileType.WALL:
              glyph = new Glyph('#',
                  tile.visible ? Color.WHITE : Color.GRAY,
                  tile.visible ? Color.DARK_GRAY : Color.BLACK);
              break;
            case TileType.LOW_WALL:
              glyph = new Glyph('%',
                  tile.visible ? Color.GRAY : Color.DARK_GRAY,
                  tile.visible ? Color.DARK_GRAY : Color.BLACK);
              break;
            case TileType.CLOSED_DOOR:
              glyph = new Glyph('+',
                  tile.visible ? Color.BROWN : Color.DARK_BROWN);
              break;
            case TileType.OPEN_DOOR:
              glyph = new Glyph("'",
                  tile.visible ? Color.BROWN : Color.DARK_BROWN);
              break;
          }
        } else {
          glyph = new Glyph(' ');
        }

        /*
        glyph = debugScent(x, y, tile, glyph);
        */

        terminal.writeAt(x, y, glyph.char, glyph.fore, glyph.back);
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
    for (final item in game.level.items) {
      if (!game.level[item.pos].isExplored) continue;
      terminal.drawGlyph(item.x, item.y, item.appearance);
    }

    // Draw the actors.
    for (final actor in game.level.actors) {
      if (!game.level[actor.pos].visible) continue;
      final appearance = actor.appearance;
      final glyph = (appearance is Glyph) ? appearance : new Glyph('@', Color.WHITE);
      terminal.drawGlyph(actor.x, actor.y, glyph);
    }

    // Draw the effects.
    for (final effect in effects) {
      effect.render(terminal);
    }

    // Draw the log.

    // If the log is overlapping the hero, flip it to the other side. Use 0.4
    // and 0.6 here to avoid flipping too much if the hero is wandering around
    // near the middle.
    if (logOnTop) {
      if (game.hero.y < terminal.height * 0.4) logOnTop = false;
    } else {
      if (game.hero.y > terminal.height * 0.6) logOnTop = true;
    }

    // Force the log to the bottom if a popup is open so it's still visible.
    if (!isTopScreen) logOnTop = false;

    var y = logOnTop ? 0 : terminal.height - game.log.messages.length;

    for (final message in game.log.messages) {
      terminal.writeAt(0, y, message.text);
      if (message.count > 1) {
        terminal.writeAt(message.text.length, y, ' (x${message.count})',
          Color.GRAY);
      }
      y++;
    }

    terminal.writeAt(81, 1, 'Phineas the Bold', Color.WHITE);
    drawMeter(terminal, 'Health', 3, Color.RED,
      game.hero.health.current, game.hero.health.max);
    /*
    drawMeter(terminal, 'Hunger', 4, Color.ORANGE,
      game.hero.hunger, Option.HUNGER_MAX, showNumber: false);
    */

    terminal.writeAt(81, 6, 'Level', Color.GRAY);
    terminal.writeAt(88, 6, game.hero.level.toString(), Color.GOLD);
    terminal.writeAt(81, 7, 'Exp', Color.GRAY);
    terminal.writeAt(88, 7, game.hero.experience.toString(), Color.GOLD);

    terminal.writeAt(81, 8, 'Armor', Color.GRAY);
    terminal.writeAt(88, 8,
        '${(100 - getArmorMultiplier(game.hero.armor) * 100).toInt().toString()}% ',
        Color.YELLOW);
  }

  void drawMeter(Terminal terminal, String label, int y, Color color,
      int current, int max, [bool showNumber = true]) {
    terminal.writeAt(81, y, label, Color.GRAY);
    terminal.writeAt(87, y, padLeft(current.toString(), 3), color);

    final barString = padRight(showNumber ? current.toString() : '', 12);
    final barWidth = 12 * current ~/ max;
    terminal.writeAt(88, y, barString.substring(0, barWidth), Color.BLACK, color);
    terminal.writeAt(88 + barWidth, y, barString.substring(barWidth), color);
  }

  /// Visually debug the scent data.
  Glyph debugScent(int x, int y, Tile tile, Glyph glyph) {
    if (!tile.isPassable) return glyph;

    var scent = game.level.getScent(x, y);
    var color;
    if (scent == 0) color = Color.DARK_GRAY;
    else if (scent < 0.02) color = Color.DARK_BLUE;
    else if (scent < 0.04) color = Color.BLUE;
    else if (scent < 0.06) color = Color.DARK_AQUA;
    else if (scent < 0.08) color = Color.AQUA;
    else if (scent < 0.1) color = Color.DARK_GREEN;
    else if (scent < 0.2) color = Color.GREEN;
    else if (scent < 0.3) color = Color.DARK_YELLOW;
    else if (scent < 0.4) color = Color.YELLOW;
    else if (scent < 0.5) color = Color.DARK_ORANGE;
    else if (scent < 0.6) color = Color.ORANGE;
    else if (scent < 0.7) color = Color.DARK_RED;
    else if (scent < 0.8) color = Color.RED;
    else if (scent < 0.9) color = Color.DARK_PURPLE;
    else color = Color.PURPLE;

    var best = 0;
    var char = 'O';
    compareScent(dir, c) {
      var neighbor = game.level.getScent(x + dir.x, y + dir.y);
      if (neighbor > best) {
        best = neighbor;
        char = c;
      }
    }

    compareScent(Direction.N, '|');
    compareScent(Direction.NE, '/');
    compareScent(Direction.E, '-');
    compareScent(Direction.SE, '\\');
    compareScent(Direction.S, '|');
    compareScent(Direction.SW, '/');
    compareScent(Direction.W, '-');
    compareScent(Direction.NW, '\\');

    return new Glyph(char, color);
  }

  void _spawnParticles(int count, Vec pos, Color color) {
    for (var i = 0; i < count; i++) {
      effects.add(new ParticleEffect(pos.x, pos.y, color));
    }
  }
}

interface Effect {
  bool update(Game game);
  void render(Terminal terminal);
}

class FrameEffect implements Effect {
  final Vec pos;
  final String char;
  int life = 4;

  FrameEffect(this.pos, this.char);

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Terminal terminal) {
    terminal.writeAt(pos.x, pos.y, char, Color.GREEN);
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

    h = cos(theta) * radius;
    v = sin(theta) * radius;
    life = rng.range(7, 15);
  }

  bool update(Game game) {
    x += h;
    y += v;

    final pos = new Vec(x.toInt(), y.toInt());
    if (!game.level.bounds.contains(pos)) return false;
    if (!game.level[pos].isPassable) return false;

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