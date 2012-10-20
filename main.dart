#library('roguekit');

#import('dart:html', prefix: 'html');

#import('content.dart');
#import('engine.dart');
#import('ui.dart');
#import('util.dart');

main() {
  var content = createContent();

  var pre = new html.PreElement();
  var preTerminal = new DomTerminal(100, 40, pre);

  var canvas = new html.CanvasElement();
  var canvasTerminal = new CanvasTerminal(100, 40, canvas);

  html.document.body.elements.add(pre);

  var keyboard = new Keyboard(html.document);
  var ui = new UserInterface(keyboard, preTerminal);

  ui.push(new MainMenuScreen(content));

  html.query('#menlo').on.click.add((_) {
    canvas.remove();
    html.document.body.elements.add(pre);
    ui.setTerminal(preTerminal);
  });

  html.query('#retro').on.click.add((_) {
    pre.remove();
    html.document.body.elements.add(canvas);
    ui.setTerminal(canvasTerminal);
  });

  tick(time) {
    ui.tick();
    html.window.requestAnimationFrame(tick);
  }

  html.window.requestAnimationFrame(tick);
}
