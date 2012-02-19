#library('roguekit');

#import('dart:html');

#source('terminal.dart');

DomTerminal terminal;

bool _running = false;

bool get running() => _running;
void set running(bool value) {
  if (_running != value) {
    _running = value;
    if (_running) {
      window.webkitRequestAnimationFrame(tick, document);
    }
  }
}

main() {
  terminal = new DomTerminal(90, 30, document.query('#terminal'));
  terminal.writeAt(4,  3, 'white',  color: Color.WHITE);

  terminal.writeAt(4,  4, 'gray',  color: Color.GRAY);
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
  terminal.render();

  document.on.click.add((event) => running = !running);
}

rand(int min, int max) {
  return ((Math.random() * (max - min)) + min).toInt();
}

final BLAH = 'abcdefhighjk*!@#*(^)#';
final COLS = const [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.GREEN, Color.BLUE];

tick(time) {
  for (int i = 0; i < terminal.width * terminal.height; i++) {
    final glyph = terminal.glyphs[i];
    glyph.char = BLAH[rand(0, BLAH.length)];
    glyph.color = COLS[rand(0, COLS.length)];
  }

  terminal.render();

  if (running) window.webkitRequestAnimationFrame(tick, document);
}
