#library('roguekit');

#import('dart:html', prefix: 'html');

#import('content.dart');
#import('engine.dart');
#import('ui.dart');
#import('util.dart');

main() {
  final content = new Content();

  final terminal = new DomTerminal(100, 40, html.document.query('#terminal'));;
  final input = new UserInput(new Keyboard(html.document));
  final screen = new GameScreen(input, terminal,
      content.breeds, content.itemTypes);

  screen.render();
  tick(time) {
    if (screen.update()) screen.render();
    html.window.webkitRequestAnimationFrame(tick, html.document);
  }

  html.window.webkitRequestAnimationFrame(tick, html.document);
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