library hauberk.web.main;

import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/debug.dart';
import 'package:hauberk/src/ui/input.dart';
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
      var pixel = new Vec(event.offset.x - 4, event.offset.y - 4);
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
        html.querySelector("#game").append(terminals[i][1]);
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
  var fontIndex = 3;
  for (var i = 0; i < terminals.length; i++) {
    if (terminals[i][0] == font) {
      fontIndex = i;
      break;
    }
  }

  html.querySelector("#game").append(terminals[fontIndex][1]);

  ui = new UserInterface(terminals[fontIndex][2]);

  // Set up the keybindings.
  ui.keyBindings.bind(Input.OK, KeyCode.ENTER);
  ui.keyBindings.bind(Input.CANCEL, KeyCode.ESCAPE);
  ui.keyBindings.bind(Input.FORFEIT, KeyCode.F, shift: true);
  ui.keyBindings.bind(Input.QUIT, KeyCode.Q);

  ui.keyBindings.bind(Input.CLOSE_DOOR, KeyCode.C);
  ui.keyBindings.bind(Input.DROP, KeyCode.D);
  ui.keyBindings.bind(Input.USE, KeyCode.U);
  ui.keyBindings.bind(Input.PICK_UP, KeyCode.G);
  ui.keyBindings.bind(Input.SWAP, KeyCode.X);
  ui.keyBindings.bind(Input.SELECT_COMMAND, KeyCode.S);

  // Laptop directions.
  ui.keyBindings.bind(Input.NW, KeyCode.I);
  ui.keyBindings.bind(Input.N, KeyCode.O);
  ui.keyBindings.bind(Input.NE, KeyCode.P);
  ui.keyBindings.bind(Input.W, KeyCode.K);
  ui.keyBindings.bind(Input.E, KeyCode.SEMICOLON);
  ui.keyBindings.bind(Input.SW, KeyCode.COMMA);
  ui.keyBindings.bind(Input.S, KeyCode.PERIOD);
  ui.keyBindings.bind(Input.SE, KeyCode.SLASH);
  ui.keyBindings.bind(Input.RUN_NW, KeyCode.I, shift: true);
  ui.keyBindings.bind(Input.RUN_N, KeyCode.O, shift: true);
  ui.keyBindings.bind(Input.RUN_NE, KeyCode.P, shift: true);
  ui.keyBindings.bind(Input.RUN_W, KeyCode.K, shift: true);
  ui.keyBindings.bind(Input.RUN_E, KeyCode.SEMICOLON, shift: true);
  ui.keyBindings.bind(Input.RUN_SW, KeyCode.COMMA, shift: true);
  ui.keyBindings.bind(Input.RUN_S, KeyCode.PERIOD, shift: true);
  ui.keyBindings.bind(Input.RUN_SE, KeyCode.SLASH, shift: true);
  ui.keyBindings.bind(Input.FIRE_NW, KeyCode.I, alt: true);
  ui.keyBindings.bind(Input.FIRE_N, KeyCode.O, alt: true);
  ui.keyBindings.bind(Input.FIRE_NE, KeyCode.P, alt: true);
  ui.keyBindings.bind(Input.FIRE_W, KeyCode.K, alt: true);
  ui.keyBindings.bind(Input.FIRE_E, KeyCode.SEMICOLON, alt: true);
  ui.keyBindings.bind(Input.FIRE_SW, KeyCode.COMMA, alt: true);
  ui.keyBindings.bind(Input.FIRE_S, KeyCode.PERIOD, alt: true);
  ui.keyBindings.bind(Input.FIRE_SE, KeyCode.SLASH, alt: true);

  ui.keyBindings.bind(Input.OK, KeyCode.L);
  ui.keyBindings.bind(Input.REST, KeyCode.L, shift: true);
  ui.keyBindings.bind(Input.FIRE, KeyCode.L, alt: true);

  // Arrow keys.
  ui.keyBindings.bind(Input.N, KeyCode.UP);
  ui.keyBindings.bind(Input.W, KeyCode.LEFT);
  ui.keyBindings.bind(Input.E, KeyCode.RIGHT);
  ui.keyBindings.bind(Input.S, KeyCode.DOWN);
  ui.keyBindings.bind(Input.RUN_N, KeyCode.UP, shift: true);
  ui.keyBindings.bind(Input.RUN_W, KeyCode.LEFT, shift: true);
  ui.keyBindings.bind(Input.RUN_E, KeyCode.RIGHT, shift: true);
  ui.keyBindings.bind(Input.RUN_S, KeyCode.DOWN, shift: true);
  ui.keyBindings.bind(Input.FIRE_N, KeyCode.UP, alt: true);
  ui.keyBindings.bind(Input.FIRE_W, KeyCode.LEFT, alt: true);
  ui.keyBindings.bind(Input.FIRE_E, KeyCode.RIGHT, alt: true);
  ui.keyBindings.bind(Input.FIRE_S, KeyCode.DOWN, alt: true);

  // Numeric keypad.
  ui.keyBindings.bind(Input.NW, KeyCode.NUMPAD_7);
  ui.keyBindings.bind(Input.N, KeyCode.NUMPAD_8);
  ui.keyBindings.bind(Input.NE, KeyCode.NUMPAD_9);
  ui.keyBindings.bind(Input.W, KeyCode.NUMPAD_4);
  ui.keyBindings.bind(Input.E, KeyCode.NUMPAD_6);
  ui.keyBindings.bind(Input.SW, KeyCode.NUMPAD_1);
  ui.keyBindings.bind(Input.S, KeyCode.NUMPAD_2);
  ui.keyBindings.bind(Input.SE, KeyCode.NUMPAD_3);

  ui.keyBindings.bind(Input.OK, KeyCode.NUMPAD_5);
  ui.keyBindings.bind(Input.REST, KeyCode.NUMPAD_5, shift: true);
  ui.keyBindings.bind(Input.FIRE, KeyCode.NUMPAD_5, alt: true);

  ui.push(new MainMenuScreen(content));

  tick(time) {
    ui.refresh();
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