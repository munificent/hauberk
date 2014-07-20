library hauberk.web.main;

import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/debug.dart';
import 'package:hauberk/src/ui/main_menu_screen.dart';

const WIDTH = 100;
const HEIGHT = 40;

final terminals = [];
var ui;

addTerminal(String name, html.Element element,
    RenderableTerminal terminalCallback(html.Element element)) {

  // Make the terminal.
  var terminal = terminalCallback(element);
  terminals.add([name, element, terminal]);

  if (Debug.ENABLED) {
    var debugBox = new html.PreElement();
    debugBox.id = "debug";
    html.document.body.children.add(debugBox);

    var lastPos;
    element.onMouseMove.listen((event) {
      var pixel = new Vec(event.offset.x, event.offset.y);
      var pos = terminal.pixelToChar(pixel);
      var absolute = pixel + new Vec(element.offsetLeft, element.offsetTop);
      if (pos != lastPos) debugHover(debugBox, absolute, pos);
      lastPos = pos;
    });
  }

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
      (element) => new RetroTerminal.dos(WIDTH, HEIGHT, element));

  addTerminal('DOS Short', new html.CanvasElement(),
      (element) => new RetroTerminal.shortDos(WIDTH, HEIGHT, element));

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

void debugHover(html.Element debugBox, Vec pixel, Vec pos) {
  var info = Debug.getMonsterInfoAt(pos);
  if (info == null) {
    debugBox.style.display = "none";
    return;
  }

  debugBox.style.display = "inline-block";
  debugBox.style.left = "${pixel.x + 10}";
  debugBox.style.top = "${pixel.y}";
  debugBox.text = info;
}