
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
      case KeyCode.D:
        ui.push(new InventoryDialog(game, InventoryMode.DROP));
        return true;
      case KeyCode.U:
        ui.push(new InventoryDialog(game, InventoryMode.USE));
        return true;
    }

    game.hero.nextAction = input.getAction(keyboard);

    return true;
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
          }
        } else {
          glyph = new Glyph(' ');
        }

        /*
        glyph = debugScent(x, y, tile, glyph);
        glyph = debugPathfinding(x, y, tile, glyph);
        */

        terminal.writeAt(x, y, glyph.char, glyph.fore, glyph.back);
      }
    }

    // Draw the items.
    for (final item in game.level.items) {
      if (game.level[item.pos].isExplored) {
        terminal.drawGlyph(item.x, item.y, item.appearance);
      }
    }

    // Draw the actors.
    for (final actor in game.level.actors) {
      if (game.level[actor.pos].visible) {
        final appearance = actor.appearance;
        final glyph = (appearance is Glyph) ? appearance : new Glyph('@', Color.YELLOW);
        terminal.drawGlyph(actor.x, actor.y, glyph);
      }
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

  /// Visually debug the pathfinding data.
  Glyph debugPathfinding(int x, int y, Tile tile, Glyph glyph) {
    if (!tile.isPassable) return glyph;

    final colors = const [
      Color.DARK_PURPLE,
      Color.DARK_BLUE,
      Color.DARK_AQUA,
      Color.DARK_GREEN,
      Color.DARK_YELLOW,
      Color.DARK_ORANGE,
      Color.DARK_RED
    ];

    final steps = game.level.getPath(x, y);
    if (steps >= 0) {
      return new Glyph('0123456789'[steps % 10], colors[steps % 7]);
    } else {
      return new Glyph('-', Color.DARK_GRAY);
    }
  }
}

/// Processes user input while the game is being played.
class GameInput {
  /// The direction key the user is currently pressing.
  Direction currentDirection = null;

  /// How long the user has been pressing in the current direction.
  int holdTime = 0;

  Action getAction(Keyboard keyboard) {
    // First try the key events that only trigger on a press.
    switch (keyboard.lastPressed) {
      case KeyCode.G: return new PickUpAction();
    }

    // See what direction is being pressed.
    var direction;
    switch (keyboard.getOnlyKey()) {
      case KeyCode.I:         direction = Direction.NW; break;
      case KeyCode.O:         direction = Direction.N; break;
      case KeyCode.P:         direction = Direction.NE; break;
      case KeyCode.K:         direction = Direction.W; break;
      case KeyCode.L:         direction = Direction.NONE; break;
      case KeyCode.SEMICOLON: direction = Direction.E; break;
      case KeyCode.COMMA:     direction = Direction.SW; break;
      case KeyCode.PERIOD:    direction = Direction.S; break;
      case KeyCode.SLASH:     direction = Direction.SE; break;
    }

    if (direction != currentDirection) {
      // Changing direction.
      currentDirection = direction;
      holdTime = 0;
    } else {
      // Still going in the same direction.
      holdTime++;
    }

    // TODO(bob): Kinda hackish.
    // Determine which frames should actually move the hero. The numbers here
    // gradually accelerate until eventually the hero moves at every frame.
    shouldMove() {
      if (holdTime == 0) return true;
      if (holdTime == 8) return true;
      if (holdTime == 16) return true;
      if (holdTime == 23) return true;
      if (holdTime == 30) return true;
      if (holdTime == 36) return true;
      if (holdTime == 42) return true;
      if (holdTime == 47) return true;
      if (holdTime == 52) return true;
      if (holdTime == 56) return true;
      if (holdTime == 60) return true;
      if (holdTime == 63) return true;
      if (holdTime == 66) return true;
      if (holdTime == 68) return true;
      if (holdTime >= 70) return true;

      return false;
    }

    if (currentDirection == null) return null;
    if (!shouldMove()) return null;

    switch (currentDirection) {
      case Direction.NW:   return new MoveAction(new Vec(-1, -1));
      case Direction.N:    return new MoveAction(new Vec(0, -1));
      case Direction.NE:   return new MoveAction(new Vec(1, -1));
      case Direction.W:    return new MoveAction(new Vec(-1, 0));
      case Direction.NONE: return new MoveAction(new Vec(0, 0));
      case Direction.E:    return new MoveAction(new Vec(1, 0));
      case Direction.SW:   return new MoveAction(new Vec(-1, 1));
      case Direction.S:    return new MoveAction(new Vec(0, 1));
      case Direction.SE:   return new MoveAction(new Vec(1, 1));
    }
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