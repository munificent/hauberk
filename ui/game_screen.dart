
class GameScreen extends Screen {
  Game           game;
  List<Breed>    breeds;
  List<ItemType> itemTypes;
  List<Effect>   effects;
  bool           logOnTop = false;
  GameInput      input;

  GameScreen(List<Breed> breeds, List<ItemType> itemTypes)
  : effects = <Effect>[],
    input = new GameInput()
  {
    this.breeds = breeds;
    this.itemTypes = itemTypes;

    game = new Game(breeds, itemTypes);
  }

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.C:
        closeDoor();
        return true;

      case KeyCode.D:
        ui.push(new InventoryDialog(game, InventoryMode.DROP));
        return true;

      case KeyCode.U:
        ui.push(new InventoryDialog(game, InventoryMode.USE));
        return true;

      case KeyCode.L:
        if (keyboard.shift) {
          game.hero.rest();
          return true;
        }
        break;

      case KeyCode.I:
        if (keyboard.shift) {
          game.hero.run(Direction.NW);
          return true;
        }
        break;

      case KeyCode.O:
        if (keyboard.shift) {
          game.hero.run(Direction.N);
          return true;
        }
        break;

      case KeyCode.P:
        if (keyboard.shift) {
          game.hero.run(Direction.NE);
          return true;
        }
        break;

      case KeyCode.K:
        if (keyboard.shift) {
          game.hero.run(Direction.W);
          return true;
        }
        break;

      case KeyCode.SEMICOLON:
        if (keyboard.shift) {
          game.hero.run(Direction.E);
          return true;
        }
        break;

      case KeyCode.COMMA:
        if (keyboard.shift) {
          game.hero.run(Direction.SW);
          return true;
        }
        break;

      case KeyCode.PERIOD:
        if (keyboard.shift) {
          game.hero.run(Direction.S);
          return true;
        }
        break;

      case KeyCode.SLASH:
        if (keyboard.shift) {
          game.hero.run(Direction.SE);
          return true;
        }
        break;
    }

    final action = input.getAction(keyboard);
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
      // TODO(bob): Bug. This doesn't actually get shown immediately. Because
      // no game update occurs, the screen doesn't refresh.
      game.log.add('You are not next to an open door.');
    } else if (doors.length == 1) {
      game.hero.setNextAction(new CloseDoorAction(doors[0]));
    } else {
      ui.push(new CloseDoorDialog(game));
    }
  }

  bool update() {
    var needsRender = effects.length > 0;

    var result = game.update();

    // TODO(bob): Hack temp.
    if (game.hero.health.current == 0) {
      game = new Game(breeds, itemTypes);
      return true;
    }

    for (final event in result.events) {
      // TODO(bob): Handle other event types.
      switch (event.type) {
        case EventType.HIT:
          effects.add(new HitEffect(event.actor));
          break;

        case EventType.KILL:
          effects.add(new HitEffect(event.actor));
          for (var i = 0; i < 10; i++) {
            effects.add(new ParticleEffect(event.actor.x, event.actor.y));
          }
          break;
      }
    }

    needsRender = needsRender || result.madeProgress;

    effects = effects.filter((effect) => effect.update(game));

    return needsRender;
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
    drawMeter(terminal, 'Hunger', 4, Color.ORANGE,
      game.hero.hunger, Option.HUNGER_MAX, showNumber: false);
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
}

/// Processes user input while the game is being played.
// TODO(bob): Kind of hackish. Needs clean-up. This is only for walking
// movement, which needs a little extra effort to feel right. (We don't want to
// rely on the OS's key repeat which is a bit too slow.)
class GameInput {
  /// The direction key the user is currently pressing.
  Direction currentDirection = null;

  /// How long the user has been pressing in the current direction.
  int holdTime = 0;

  Action getAction(Keyboard keyboard) {
    if (keyboard.shift) return null;

    switch (keyboard.lastPressed) {
      case KeyCode.G:         return new PickUpAction();
      case KeyCode.I:         return new MoveAction(Direction.NW);
      case KeyCode.O:         return new MoveAction(Direction.N);
      case KeyCode.P:         return new MoveAction(Direction.NE);
      case KeyCode.K:         return new MoveAction(Direction.W);
      case KeyCode.L:         return new MoveAction(Direction.NONE);
      case KeyCode.SEMICOLON: return new MoveAction(Direction.E);
      case KeyCode.COMMA:     return new MoveAction(Direction.SW);
      case KeyCode.PERIOD:    return new MoveAction(Direction.S);
      case KeyCode.SLASH:     return new MoveAction(Direction.SE);
    }

    return null;
  }
}

interface Effect {
  bool update(Game game);
  void render(Terminal terminal);
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

  ParticleEffect(this.x, this.y) {
    final theta = rng.range(628) / 100; // TODO(bob): Ghetto.
    final radius = rng.range(30, 40) / 100;

    h = Math.cos(theta) * radius;
    v = Math.sin(theta) * radius;
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
    terminal.writeAt(x.toInt(), y.toInt(), '*', Color.RED);
  }
}