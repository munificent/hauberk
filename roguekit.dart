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
  terminal.rect(3, 10, 8, 4).write('hello there', color: Color.RED);
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
