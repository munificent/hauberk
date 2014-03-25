library dngn.web.main;

import 'dart:html' as html;

import 'package:dngn/src/content.dart';
import 'package:dngn/src/ui.dart';

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
  button.innerHtml = name;
  button.onClick.listen((_) {
    for (var i = 0; i < terminals.length; i++) {
      if (terminals[i][0] == name) {
        html.document.body.children.add(terminals[i][1]);
      } else {
        terminals[i][1].remove();
      }
    }
    ui.setTerminal(terminal);

    // Remember the preference.
    html.window.localStorage['font'] = name;
  });

  html.querySelector('.button-bar').children.add(button);
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

  addTerminal('DOS', new html.CanvasElement(),
      (element) => new RetroTerminal(WIDTH, HEIGHT, element, "dos.png",
        w: 9, h: 16));

  addTerminal('DOS Short', new html.CanvasElement(),
      (element) => new RetroTerminal(WIDTH, HEIGHT, element, "dos-short.png",
        w: 9, h: 13));

  // Load the user's font preference, if any.
  var font = html.window.localStorage['font'];
  var fontIndex = 1;
  for (var i = 0; i < terminals.length; i++) {
    if (terminals[i][0] == font) {
      fontIndex = i;
      break;
    }
  }

  html.document.body.children.add(terminals[fontIndex][1]);
  var keyboard = new Keyboard(html.document.body);
  ui = new UserInterface(keyboard, terminals[fontIndex][2]);

  ui.push(new MainMenuScreen(content));

  tick(time) {
    ui.tick();
    html.window.requestAnimationFrame(tick);
  }

  html.window.requestAnimationFrame(tick);
}
