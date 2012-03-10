#library('roguekit');

#import('dart:html', prefix: 'html');

#import('engine.dart');
#import('ui.dart');
#import('util.dart');

DomTerminal terminal;
Game        game;
UserInput   input;

bool logOnTop = false;

main() {
  game = new Game();

  final rat = new Breed('rat', Gender.NEUTER,
    new Glyph('r', Color.DARK_ORANGE),
    maxHealth: 4,
    minScent: 0.001);

  // Temp for testing.
  Vec findOpen() {
    while (true) {
      final pos = rng.vecInRect(game.level.bounds);
      if (game.level[pos].isPassable) return pos;
    }
  }

  game.hero.pos = findOpen();
  for (int i = 0; i < 10; i++) {
    final pos = findOpen();
    game.level.actors.add(rat.spawn(game, pos));
  }

  // TODO(bob): Doing this here is a hack, but we need to run it once the
  // hero knows his position.
  Fov.refresh(game.level, game.hero.pos);

  terminal = new DomTerminal(100, 40, html.document.query('#terminal'));

  input = new UserInput(new Keyboard(html.document));

  render();

  html.window.webkitRequestAnimationFrame(tick, html.document);
}

tick(time) {
  game.hero.nextAction = input.getAction();

  if (game.update()) {
    render();
  }

  html.window.webkitRequestAnimationFrame(tick, html.document);
}

render() {
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
        else if (scent < 0.02) color = Color.DARK_PURPLE;
        else if (scent < 0.04) color = Color.DARK_BLUE;
        else if (scent < 0.06) color = Color.DARK_AQUA;
        else if (scent < 0.08) color = Color.DARK_GREEN;
        else if (scent < 0.1) color = Color.DARK_YELLOW;
        else if (scent < 0.2) color = Color.DARK_ORANGE;
        else if (scent < 0.3) color = Color.DARK_RED;
        else if (scent < 0.4) color = Color.PURPLE;
        else if (scent < 0.5) color = Color.BLUE;
        else if (scent < 0.6) color = Color.AQUA;
        else if (scent < 0.7) color = Color.GREEN;
        else if (scent < 0.8) color = Color.YELLOW;
        else if (scent < 0.9) color = Color.ORANGE;
        else color = Color.RED;
        glyph = new Glyph('S', color);
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

  // Draw the effects.
  for (final effect in game.effects) {
    final pos = effect.pos;
    if (game.level[pos].visible) {
      terminal.writeAt(pos.x, pos.y, '*', Color.RED);
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

  terminal.writeAt(81, 3, 'Health', Color.GRAY);
  terminal.writeAt(81, 4, '  Mana', Color.GRAY);
  terminal.writeAt(81, 5, '   Str', Color.GRAY);
  terminal.writeAt(81, 6, '   Agi', Color.GRAY);
  terminal.writeAt(81, 7, '   Int', Color.GRAY);

  terminal.writeAt(88, 3, '25/25', Color.RED);
  terminal.writeAt(88, 4, '25/25', Color.PURPLE);
  terminal.writeAt(88, 5, '25/25', Color.ORANGE);
  terminal.writeAt(88, 6, '25/25', Color.GREEN);
  terminal.writeAt(88, 7, '25/25', Color.BLUE);

  terminal.render();
}

colorTest() {
  var colors = [
    Color.WHITE,
    Color.BLACK,
    Color.GRAY,
    Color.RED,
    Color.ORANGE,
    Color.YELLOW,
    Color.GREEN,
    Color.AQUA,
    Color.BLUE,
    Color.PURPLE,
    Color.DARK_GRAY,
    Color.DARK_RED,
    Color.DARK_ORANGE,
    Color.DARK_YELLOW,
    Color.DARK_GREEN,
    Color.DARK_AQUA,
    Color.DARK_BLUE,
    Color.DARK_PURPLE
  ];

  for (var y = 0; y < colors.length; y++) {
    for (var x = 0; x < colors.length; x++) {
      terminal.writeAt(x + 4, y + 2, '#', colors[y], colors[x]);
    }
  }
  /*
  terminal.writeAt(4,  3, 'white',  color: Color.WHITE);

  terminal.writeAt(4,  4, 'gray',   color: Color.GRAY);
  terminal.writeAt(4,  5, 'red',    color: Color.RED);
  terminal.writeAt(4,  6, 'orange', color: Color.ORANGE);
  terminal.writeAt(4,  7, 'yellow', color: Color.YELLOW);
  terminal.writeAt(4,  8, 'green',  color: Color.GREEN);
  terminal.writeAt(4,  9, 'aqua',   color: Color.AQUA);
  terminal.writeAt(4, 10, 'blue',   color: Color.BLUE);
  terminal.writeAt(4, 11, 'purple', color: Color.PURPLE);

  terminal.writeAt(14,  4, 'dark gray',   color: Color.DARK_GRAY);
  terminal.writeAt(14,  5, 'dark red',    color: Color.DARK_RED);
  terminal.writeAt(14,  6, 'dark orange', color: Color.DARK_ORANGE);
  terminal.writeAt(14,  7, 'dark yellow', color: Color.DARK_YELLOW);
  terminal.writeAt(14,  8, 'dark green',  color: Color.DARK_GREEN);
  terminal.writeAt(14,  9, 'dark aqua',   color: Color.DARK_AQUA);
  terminal.writeAt(14, 10, 'dark blue',   color: Color.DARK_BLUE);
  terminal.writeAt(14, 11, 'dark purple', color: Color.DARK_PURPLE);
  */
}

class Fps {
  Fps() : ticks = new List(NUM_TICKS) {
    for (var i = 0; i < NUM_TICKS; i++) ticks[i] = 0;
  }

  tick(time) {
    // Get the duration between the oldest and newest ticks in the buffer.
    final start = ticks[head];
    final end = time;
    print((end - start) / NUM_TICKS);

    // Add it to the buffer.
    ticks[head] = time;
    head = (head + 1) % NUM_TICKS;
  }

  static final NUM_TICKS = 100;
  /// Circular buffer of past frame times.
  final List ticks;
  int head = 0;
}