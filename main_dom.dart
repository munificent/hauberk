#library('roguekit');

#import('dart:html', prefix: 'html');

#import('content.dart');
#import('engine.dart');
#import('ui.dart');
#import('util.dart');

main() {
  final content = createContent();

  final terminal = new DomTerminal(100, 40, html.document.query('#terminal'));
//  final terminal = new CanvasTerminal(100, 40, html.query('canvas'));
  final keyboard = new Keyboard(html.document);
  final ui = new UserInterface(keyboard, terminal);

  ui.push(new MainMenuScreen(content));

  final element = html.document.query('pre');

  tick(time) {
    ui.tick();
    html.window.requestAnimationFrame(tick);
  }

  html.window.requestAnimationFrame(tick);
}
