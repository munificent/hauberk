#library('roguekit');

#import('dart:html', prefix: 'html');

#source('action.dart');
#source('actor.dart');
#source('array2d.dart');
#source('chain.dart');
#source('game.dart');
#source('keyboard.dart');
#source('level.dart');
#source('terminal.dart');
#source('vec.dart');

DomTerminal terminal;
Game        game;
UserInput   input;

bool _running = false;

bool get running() => _running;
void set running(bool value) {
  if (_running != value) {
    _running = value;
    if (_running) {
      html.window.webkitRequestAnimationFrame(tick, html.document);
    }
  }
}

main() {
  game = new Game();
  terminal = new DomTerminal(100, 40, html.document.query('#terminal'));

  input = new UserInput(new Keyboard(html.document));

  render();

  html.document.on.click.add((event) => running = !running, true);

  running = true;
}

tick(time) {
  game.hero.nextAction = input.getAction();
  game.update();
  render();

  if (running) html.window.webkitRequestAnimationFrame(tick, html.document);
}

render() {
  // Draw the level.
  for (int y = 0; y < game.level.height; y++) {
    for (int x = 0; x < game.level.width; x++) {
      var char;
      var color;
      switch (game.level.get(x, y).type) {
        case TileType.FLOOR: char = '.'; color = Color.DARK_GRAY; break;
        case TileType.WALL:  char = '#'; color = Color.WHITE; break;
      }
      terminal.writeAt(x, y, char, color);
    }
  }

  for (final actor in game.actors) {
    final color = (actor is Hero) ? Color.YELLOW : Color.GRAY;
    terminal.writeAt(actor.x, actor.y, '@', color);
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

rand(int max) {
  return (Math.random() * max).toInt();
}

randRange(int min, int max) {
  return ((Math.random() * (max - min)) + min).toInt();
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