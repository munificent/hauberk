
class Screen {
  final UserInput input;
  final Terminal  terminal;

  Screen(this.input, this.terminal);

  abstract bool update();
  abstract void render();
}

class GameScreen extends Screen {
  Game         game;
  List<Effect> effects;
  bool         logOnTop = false;

  GameScreen(UserInput input, Terminal terminal, List<Breed> breeds)
  : super(input, terminal),
    game = new Game(breeds),
    effects = <Effect>[];

  bool update() {
    game.hero.nextAction = input.getAction();

    var result = game.update();

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

    var needsRender = result.madeProgress || (effects.length > 0);

    effects = effects.filter((effect) => effect.update(game));

    return needsRender;
  }

  void render() {
    // Draw the level.
    for (int y = 0; y < game.level.height; y++) {
      for (int x = 0; x < game.level.width; x++) {
        final tile = game.level.get(x, y);
        var glyph;
        if (tile.explored) {
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
        // Visually debug the scent data.
        if (tile.isPassable) {
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

          glyph = new Glyph(char, color);
        }
        */

        // Visually debug the pathfinding data.
        /*
        final colors = const [
          Color.DARK_PURPLE,
          Color.DARK_BLUE,
          Color.DARK_AQUA,
          Color.DARK_GREEN,
          Color.DARK_YELLOW,
          Color.DARK_ORANGE,
          Color.DARK_RED
        ];

        if (tile.isPassable) {
          final steps = game.level.getPath(x, y);
          if (steps >= 0) {
            glyph = new Glyph('0123456789'[steps % 10], colors[steps % 7]);
          } else {
            glyph = new Glyph('-', Color.DARK_GRAY);
          }
        }
        */

        terminal.writeAt(x, y, glyph.char, glyph.fore, glyph.back);
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

    // If the log is overlapping the hero, flip it to the other side. Use 0.4 and
    // 0.6 here to avoid flipping too much if the hero is wandering around near
    // the middle.
    if (logOnTop) {
      if (game.hero.y < terminal.height * 0.4) logOnTop = false;
    } else {
      if (game.hero.y > terminal.height * 0.6) logOnTop = true;
    }
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

    terminal.writeAt(81, 3, 'Health    /   ', Color.GRAY);
    terminal.writeAt(88, 3, game.hero.health.current.toString(), Color.RED);
    terminal.writeAt(92, 3, game.hero.health.max.toString(), Color.RED);

    /*
    terminal.writeAt(50, 20, '    ', Color.RED, Color.RED);
    terminal.writeAt(54, 20, '!!!', Color.RED, Color.DARK_RED);
    terminal.writeAt(57, 20, '  ', Color.DARK_GRAY, Color.DARK_GRAY);
    */

    /*
    terminal.writeAt(81, 4, '  Mana', Color.GRAY);
    terminal.writeAt(81, 5, '   Str', Color.GRAY);
    terminal.writeAt(81, 6, '   Agi', Color.GRAY);
    terminal.writeAt(81, 7, '   Int', Color.GRAY);

    terminal.writeAt(88, 3, '25/25', Color.RED);
    terminal.writeAt(88, 4, '25/25', Color.PURPLE);
    terminal.writeAt(88, 5, '25/25', Color.ORANGE);
    terminal.writeAt(88, 6, '25/25', Color.GREEN);
    terminal.writeAt(88, 7, '25/25', Color.BLUE);
    */

    terminal.render();
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
    terminal.writeAt(x, y, '0123456789'[health], Color.BLACK, back);
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