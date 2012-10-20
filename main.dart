#library('roguekit');

#import('dart:html', prefix: 'html');

#import('content.dart');
#import('engine.dart');
#import('ui.dart');
#import('util.dart');

const WIDTH = 100;
const HEIGHT = 40;

final terminals = [];
var ui;

addTerminal(String name, html.Element element,
    RenderableTerminal terminalCallback(html.Element element)) {

  // Make the terminal.
  var terminal = terminalCallback(element);
  terminals.add([name, element, terminal]);

  // Make a button for it.
  var button = new html.ButtonElement();
  button.innerHTML = name;
  button.on.click.add((_) {
    for (var i = 0; i < terminals.length; i++) {
      if (terminals[i][0] == name) {
        html.document.body.elements.add(terminals[i][1]);
      } else {
        terminals[i][1].remove();
      }
    }
    ui.setTerminal(terminal);

    // Remember the preference.
    html.window.localStorage['font'] = name;
  });

  html.query('.button-bar').elements.add(button);
}

main() {
  var content = createContent();

  addTerminal('Compat', new html.PreElement(),
      (element) => new DomTerminal(WIDTH, HEIGHT, element));

  addTerminal('Courier', new html.CanvasElement(),
      (element) => new CanvasTerminal(WIDTH, HEIGHT, element,
          new Font('"Courier New"', size: 12, w: 15, h: 28, x: 1, y: 21)));

  addTerminal('Menlo', new html.CanvasElement(),
      (element) => new CanvasTerminal(WIDTH, HEIGHT, element,
          new Font('Menlo', size: 12, w: 16, h: 28, x: 1, y: 21)));

  addTerminal('Retro', new html.CanvasElement(),
      (element) => new RetroTerminal(WIDTH, HEIGHT, element));

  // Load the user's font preference, if any.
  var font = html.window.localStorage['font'];
  var fontIndex = 1;
  for (var i = 0; i < terminals.length; i++) {
    if (terminals[i][0] == font) {
      fontIndex = i;
      break;
    }
  }

  html.document.body.elements.add(terminals[fontIndex][1]);
  var keyboard = new Keyboard(html.document);
  ui = new UserInterface(keyboard, terminals[fontIndex][2]);

  ui.push(new MainMenuScreen(content));

  tick(time) {
    ui.tick();
    html.window.requestAnimationFrame(tick);
  }

  html.window.requestAnimationFrame(tick);
}
